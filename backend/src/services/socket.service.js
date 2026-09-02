const socketIO = require('socket.io');
const Reservation = require('../models/reservation.model');
const Residence = require('../models/residence.model');
const DateService = require('./date.service');
const logger = require('../utils/logger');
const jwt = require('../utils/jwt');

let io;
let socketAdapterEnabled = false;
const userSockets = new Map(); // userId -> Set<socketId>

/**
 * Extrait et vérifie le JWT du handshake Socket.IO.
 * Sources : auth.token | query.token | Authorization Bearer
 */
function extractAndVerifyToken(handshake) {
    const raw =
        handshake.auth?.token ||
        handshake.query?.token ||
        (handshake.headers?.authorization || '').replace(/^Bearer\s+/i, '');

    if (!raw || typeof raw !== 'string') {
        return null;
    }

    const decoded = jwt.verifyToken(raw, 'JWT_SECRET');
    if (!decoded?.id) {
        throw new Error('Token socket invalide');
    }
    return {
        userId: decoded.id.toString(),
        role: decoded.role || 'client',
    };
}

function registerUserSocket(userId, socketId) {
    if (!userSockets.has(userId)) {
        userSockets.set(userId, new Set());
    }
    userSockets.get(userId).add(socketId);
}

function unregisterSocket(socketId) {
    for (const [userId, sockets] of userSockets.entries()) {
        if (sockets.has(socketId)) {
            sockets.delete(socketId);
            if (sockets.size === 0) {
                userSockets.delete(userId);
            }
            return userId;
        }
    }
    return null;
}

class SocketService {
    static initialize(server) {
        if (io) return io;

        const corsOrigin =
            process.env.SOCKET_CORS_ORIGIN ||
            process.env.FRONTEND_URL ||
            process.env.CLIENT_URL ||
            '*';

        io = socketIO(server, {
            cors: {
                origin: corsOrigin,
                methods: ['GET', 'POST'],
                credentials: true,
            },
        });

        socketAdapterEnabled = false;
        if (process.env.NODE_ENV === 'production') {
            try {
                const { createAdapter } = require('@socket.io/redis-adapter');
                const redis = require('../config/redis');
                const pubClient = redis.getClient();
                if (pubClient && typeof pubClient.duplicate === 'function' && !pubClient.isMock) {
                    const subClient = pubClient.duplicate();
                    io.adapter(createAdapter(pubClient, subClient));
                    socketAdapterEnabled = true;
                    logger.info('Socket.IO Redis adapter activé (cross-worker)');
                } else {
                    logger.warn('SOCKET_CROSS_WORKER_UNAVAILABLE: Redis adapter non attaché (mock ou client incompatible)');
                }
            } catch (err) {
                logger.warn(`SOCKET_CROSS_WORKER_UNAVAILABLE: ${err.message}`);
            }
        }

        // Authentification JWT au handshake — obligatoire
        io.use((socket, next) => {
            try {
                const auth = extractAndVerifyToken(socket.handshake);
                if (!auth) {
                    logger.warn(`Socket sans JWT rejeté: ${socket.id}`);
                    return next(new Error('Authentification socket requise'));
                }
                socket.data.authenticated = true;
                socket.data.userId = auth.userId;
                socket.data.role = auth.role;
                return next();
            } catch (err) {
                logger.warn(`Socket JWT rejeté: ${err.message}`);
                return next(new Error('Authentification socket requise'));
            }
        });

        io.on('connection', (socket) => {
            const userId = socket.data.userId;
            logger.info('Client connected:', {
                socketId: socket.id,
                authenticated: socket.data.authenticated,
                userId: userId || null,
            });

            // Auto-join salle utilisateur si JWT présent
            if (socket.data.authenticated && userId) {
                socket.join(`user_${userId}`);
                registerUserSocket(userId, socket.id);
                socket.emit('socket_authenticated', { userId, role: socket.data.role });
            }

            /**
             * auth_user : compat apps legacy.
             * L'userId client est IGNORÉ — on utilise uniquement le JWT.
             */
            socket.on('auth_user', (_ignoredUserId) => {
                if (!socket.data.authenticated || !socket.data.userId) {
                    socket.emit('socket_error', {
                        code: 'AUTH_REQUIRED',
                        message: 'JWT requis — reconnectez avec auth.token',
                    });
                    return;
                }
                const uid = socket.data.userId;
                socket.join(`user_${uid}`);
                registerUserSocket(uid, socket.id);
                logger.info(`User ${uid} rejoint user room via auth_user (JWT)`);
            });

            socket.on('join_residence', async (residenceId) => {
                try {
                    if (!socket.data.authenticated || !residenceId) {
                        socket.emit('socket_error', { code: 'AUTH_REQUIRED' });
                        return;
                    }
                    const uid = socket.data.userId;
                    const role = socket.data.role;

                    if (['admin', 'superadmin'].includes(role)) {
                        socket.join(`residence_${residenceId}`);
                        return;
                    }

                    const residence = await Residence.findById(residenceId).select('partner').lean();
                    if (!residence) {
                        socket.emit('socket_error', { code: 'RESIDENCE_NOT_FOUND' });
                        return;
                    }
                    if (residence.partner?.toString() !== uid) {
                        socket.emit('socket_error', { code: 'FORBIDDEN', message: 'Accès résidence refusé' });
                        return;
                    }
                    socket.join(`residence_${residenceId}`);
                    logger.info(`Client ${socket.id} joined residence_${residenceId}`);
                } catch (err) {
                    logger.error('join_residence error:', err);
                    socket.emit('socket_error', { code: 'JOIN_FAILED' });
                }
            });

            socket.on('leave_residence', (residenceId) => {
                if (!residenceId) return;
                socket.leave(`residence_${residenceId}`);
            });

            socket.on('join_conversation', async (conversationId) => {
                try {
                    if (!socket.data.authenticated || !conversationId) {
                        socket.emit('socket_error', { code: 'AUTH_REQUIRED' });
                        return;
                    }
                    const { Conversation } = require('../models/message.model');
                    const conversation = await Conversation.findById(conversationId)
                        .select('participants')
                        .lean();

                    if (!conversation) {
                        socket.emit('socket_error', { code: 'CONVERSATION_NOT_FOUND' });
                        return;
                    }

                    const isParticipant = (conversation.participants || []).some(
                        (p) => p.toString() === socket.data.userId
                    );
                    if (!isParticipant && !['admin', 'superadmin'].includes(socket.data.role)) {
                        socket.emit('socket_error', { code: 'FORBIDDEN', message: 'Accès conversation refusé' });
                        return;
                    }

                    socket.join(`conversation_${conversationId}`);
                    logger.info(`Client ${socket.id} joined conversation_${conversationId}`);
                } catch (err) {
                    logger.error('join_conversation error:', err);
                    socket.emit('socket_error', { code: 'JOIN_FAILED' });
                }
            });

            socket.on('leave_conversation', (conversationId) => {
                if (!conversationId) return;
                socket.leave(`conversation_${conversationId}`);
            });

            // Alias client Flutter join_booking — vérifie ownership
            socket.on('join_booking', async (bookingId) => {
                try {
                    if (!socket.data.authenticated || !bookingId) {
                        socket.emit('socket_error', { code: 'AUTH_REQUIRED' });
                        return;
                    }
                    const reservation = await Reservation.findById(bookingId)
                        .select('user partner')
                        .lean();
                    if (!reservation) {
                        socket.emit('socket_error', { code: 'BOOKING_NOT_FOUND' });
                        return;
                    }
                    const uid = socket.data.userId;
                    const isOwner =
                        reservation.user?.toString() === uid ||
                        reservation.partner?.toString() === uid ||
                        ['admin', 'superadmin'].includes(socket.data.role);
                    if (!isOwner) {
                        socket.emit('socket_error', { code: 'FORBIDDEN' });
                        return;
                    }
                    socket.join(`booking_${bookingId}`);
                } catch (err) {
                    logger.error('join_booking error:', err);
                }
            });

            socket.on('leave_booking', (bookingId) => {
                if (!bookingId) return;
                socket.leave(`booking_${bookingId}`);
            });

            socket.on('disconnect', () => {
                unregisterSocket(socket.id);
                logger.info('Client disconnected:', socket.id);
            });
        });

        return io;
    }

    static async notifyBlockedDatesUpdate(residenceId) {
        if (!io) return;

        try {
            const reservations = await Reservation.find({
                residence: residenceId,
                status: 'confirmed',
                checkOut: { $gte: new Date() },
            });

            const blockedDates = reservations.flatMap((reservation) =>
                DateService.getDatesInRange(reservation.checkIn, reservation.checkOut)
            );

            io.to(`residence_${residenceId}`).emit('blocked_dates_updated', {
                residenceId,
                blockedDates: blockedDates.map((date) => date.toISOString()),
            });
        } catch (error) {
            logger.error('Error notifying blocked dates update:', error);
        }
    }

    /**
     * Nouvelle réservation — chemin canonique Partner : emitNewReservation (new_reservation_received).
     * LEGACY : new_reservation (room résidence) conservé sans consumer LIVE Flutter Partner.
     */
    static async notifyNewReservation(reservation) {
        if (!io || !reservation) return;

        SocketService.emitNewReservation(reservation);

        const residenceId = reservation.residence?._id || reservation.residence;
        if (residenceId) {
            io.to(`residence_${residenceId}`).emit('new_reservation', {
                reservationId: reservation._id,
                status: reservation.status,
                timestamp: new Date().toISOString(),
            });
        }
    }

    static async notifyReservationCancellation(reservation) {
        if (!io) return;

        io.to(`residence_${reservation.residence}`).emit('reservation_cancelled', {
            reservation: reservation.toObject ? reservation.toObject() : reservation,
        });
    }

    /** Alias utilisé par reservation.controller (check-in/out) */
    static async notifyReservationStatusUpdate(reservation) {
        const status = reservation.status;
        await SocketService.emitReservationStatusChange(reservation, null, status);
    }

    static async notifyReservationModification(reservation) {
        await SocketService.emitReservationStatusChange(
            reservation,
            null,
            reservation.status
        );
    }

    static async notifyNewMessage(message, conversation) {
        if (!io) return;

        try {
            io.to(`conversation_${message.conversation}`).emit('new_message', {
                message: message.toObject ? message.toObject() : message,
                conversationId: message.conversation,
            });
            logger.info(
                `Notification WebSocket envoyée pour le message ${message._id} dans la conversation ${message.conversation}`
            );
        } catch (error) {
            logger.error('Erreur notification WebSocket message:', error);
        }
    }

    /**
     * Présence utilisateur — source de vérité : room Socket.IO `user_{id}`.
     * Avec Redis adapter (prod), fetchSockets interroge tous les workers PM2.
     * En échec/timeout : retourne false (offline) pour autoriser le fallback push.
     */
    static async isUserOnline(userId) {
        if (!userId) return false;

        const uid = String(userId);
        if (!io) return false;

        const room = `user_${uid}`;
        const timeoutMs = Number(process.env.SOCKET_PRESENCE_TIMEOUT_MS) || 2000;

        try {
            const sockets = await Promise.race([
                io.in(room).fetchSockets(),
                new Promise((_, reject) => {
                    setTimeout(() => reject(new Error('PRESENCE_TIMEOUT')), timeoutMs);
                }),
            ]);
            return Array.isArray(sockets) && sockets.length > 0;
        } catch (err) {
            logger.warn('Presence lookup failed — treating as offline for push', {
                code: err.message === 'PRESENCE_TIMEOUT' ? 'PRESENCE_TIMEOUT' : 'PRESENCE_LOOKUP_FAILED',
                crossWorker: socketAdapterEnabled,
            });
            return false;
        }
    }

    /**
     * Émet changement de statut — noms canoniques + alias Flutter legacy
     */
    static emitReservationStatusChange(reservation, oldStatus, newStatus) {
        try {
            if (!io || !reservation) return;

            const eventData = {
                reservationId: reservation._id,
                bookingId: reservation._id,
                oldStatus,
                previousStatus: oldStatus,
                newStatus,
                status: newStatus,
                timestamp: new Date().toISOString(),
                userId: reservation.user?._id || reservation.user,
                partnerId: reservation.partner?._id || reservation.partner,
                residenceId: reservation.residence?._id || reservation.residence,
                residenceTitle: reservation.residence?.title,
                expirationReason: reservation.expirationReason || null,
            };

            const userId = reservation.user?._id || reservation.user;
            if (userId) {
                const room = `user_${userId}`;
                io.to(room).emit('reservation_status_changed', eventData);
                // Alias apps Flutter (anciens noms)
                io.to(room).emit('booking_status_updated', eventData);
                if (newStatus === 'confirmed' || newStatus === 'payment_pending') {
                    io.to(room).emit('booking_approved', eventData);
                }
                if (newStatus === 'cancelled' || newStatus === 'rejected') {
                    io.to(room).emit('booking_rejected', eventData);
                }
                if (newStatus === 'expired') {
                    io.to(room).emit('reservation_expired', eventData);
                    io.to(room).emit('booking_expired', eventData);
                }
            }

            if (reservation.partner) {
                const partnerId = reservation.partner._id || reservation.partner;
                io.to(`user_${partnerId}`).emit('partner_reservation_status_changed', eventData);
            }

            if (reservation.residence) {
                const residenceId = reservation.residence._id || reservation.residence;
                io.to(`residence_${residenceId}`).emit('residence_reservation_update', eventData);
            }

            io.to(`booking_${reservation._id}`).emit('reservation_status_changed', eventData);
            io.to(`booking_${reservation._id}`).emit('booking_status_updated', eventData);

            logger.info(
                `WebSocket statut réservation ${reservation._id}: ${oldStatus} → ${newStatus}`
            );
        } catch (error) {
            logger.error('Erreur émission changement statut réservation:', error);
        }
    }

    static emitNewReservation(reservation) {
        try {
            if (!io || !reservation) return;

            const eventData = {
                reservationId: reservation._id,
                status: reservation.status,
                paymentStatus: reservation.paymentStatus,
                timestamp: new Date().toISOString(),
                userId: reservation.user?._id || reservation.user,
                partnerId: reservation.partner?._id || reservation.partner,
                residenceId: reservation.residence?._id || reservation.residence,
                residenceTitle: reservation.residence?.title,
                checkIn: reservation.checkIn,
                checkOut: reservation.checkOut,
                totalPrice: reservation.totalPrice,
            };

            if (reservation.partner) {
                const partnerId = reservation.partner._id || reservation.partner;
                io.to(`user_${partnerId}`).emit('new_reservation_received', eventData);
            }

            if (reservation.residence) {
                const residenceId = reservation.residence._id || reservation.residence;
                io.to(`residence_${residenceId}`).emit('residence_new_reservation', eventData);
            }
        } catch (error) {
            logger.error('Erreur émission nouvelle réservation:', error);
        }
    }

    static isCrossWorkerEnabled() {
        return socketAdapterEnabled;
    }

    static async close() {
        socketAdapterEnabled = false;
        if (!io) return;
        await new Promise((resolve) => {
            io.close(() => resolve());
        });
        io = null;
        userSockets.clear();
    }
}

module.exports = SocketService;
