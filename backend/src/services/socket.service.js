const socketIO = require('socket.io');
const Reservation = require('../models/reservation.model');
const DateService = require('./date.service');
const logger = require('../utils/logger');

let io;
const userSockets = new Map(); // Pour stocker les utilisateurs connectés et leurs sockets

class SocketService {
    static initialize(server) {
        if (io) return io;

        io = socketIO(server, {
            cors: {
                origin: process.env.FRONTEND_URL || "*",
                methods: ["GET", "POST"]
            }
        });

        io.on('connection', (socket) => {
            logger.info('Client connected:', socket.id);

            // Rejoindre une salle pour les résidences
            socket.on('join_residence', (residenceId) => {
                socket.join(`residence_${residenceId}`);
                logger.info(`Client ${socket.id} joined residence_${residenceId}`);
            });

            // Quitter une salle pour les résidences
            socket.on('leave_residence', (residenceId) => {
                socket.leave(`residence_${residenceId}`);
                logger.info(`Client ${socket.id} left residence_${residenceId}`);
            });

            // Rejoindre une salle pour les utilisateurs (chat)
            socket.on('auth_user', (userId) => {
                if (!userId) return;
                
                // Ajouter le socket à la salle de l'utilisateur
                socket.join(`user_${userId}`);
                
                // Stocker la relation utilisateur-socket
                if (!userSockets.has(userId)) {
                    userSockets.set(userId, new Set());
                }
                userSockets.get(userId).add(socket.id);
                
                logger.info(`User ${userId} authenticated with socket ${socket.id}`);
            });

            // Rejoindre une salle pour une conversation
            socket.on('join_conversation', (conversationId) => {
                if (!conversationId) return;
                socket.join(`conversation_${conversationId}`);
                logger.info(`Client ${socket.id} joined conversation_${conversationId}`);
            });

            // Quitter une salle pour une conversation
            socket.on('leave_conversation', (conversationId) => {
                socket.leave(`conversation_${conversationId}`);
                logger.info(`Client ${socket.id} left conversation_${conversationId}`);
            });

            // Déconnexion
            socket.on('disconnect', () => {
                logger.info('Client disconnected:', socket.id);
                
                // Nettoyer la map userSockets
                for (const [userId, sockets] of userSockets.entries()) {
                    if (sockets.has(socket.id)) {
                        sockets.delete(socket.id);
                        if (sockets.size === 0) {
                            userSockets.delete(userId);
                        }
                        break;
                    }
                }
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
                checkOut: { $gte: new Date() }
            });

            const blockedDates = reservations.flatMap(reservation => 
                DateService.getDatesInRange(reservation.checkIn, reservation.checkOut)
            );

            io.to(`residence_${residenceId}`).emit('blocked_dates_updated', {
                residenceId,
                blockedDates: blockedDates.map(date => date.toISOString())
            });
        } catch (error) {
            console.error('Error notifying blocked dates update:', error);
        }
    }

    static async notifyNewReservation(reservation) {
        if (!io) return;

        io.to(`residence_${reservation.residence}`).emit('new_reservation', {
            reservation: reservation.toObject()
        });
    }

    static async notifyReservationCancellation(reservation) {
        if (!io) return;

        io.to(`residence_${reservation.residence}`).emit('reservation_cancelled', {
            reservation: reservation.toObject()
        });
    }

    /**
     * Notifie les participants d'un nouveau message dans une conversation
     * @param {Object} message - Le message qui vient d'être envoyé
     * @param {Array<String>} participants - Liste des IDs des participants à notifier
     */
    static async notifyNewMessage(message, conversation) {
        if (!io) return;

        try {
            // Envoyer à tous les membres de la conversation sauf l'expéditeur
            const senderUserId = message.sender._id || message.sender;
            
            // Émettre l'événement à la salle de conversation
            io.to(`conversation_${message.conversation}`).emit('new_message', {
                message: message.toObject ? message.toObject() : message,
                conversationId: message.conversation
            });
            
            // Log informatif
            logger.info(`Notification WebSocket envoyée pour le message ${message._id} dans la conversation ${message.conversation}`);
            
        } catch (error) {
            logger.error('Erreur lors de l\'envoi de la notification WebSocket pour un nouveau message:', error);
        }
    }

    /**
     * Vérifie si un utilisateur est actuellement connecté via WebSocket
     * @param {String} userId - ID de l'utilisateur à vérifier
     * @returns {Boolean} - True si l'utilisateur est connecté, false sinon
     */
    static isUserOnline(userId) {
        return userSockets.has(userId) && userSockets.get(userId).size > 0;
    }

    // ✅ PHASE 0 BIS : Événements Reservation manquants critiques

    /**
     * Émet un événement de changement de statut de réservation
     * @param {Object} reservation - Réservation avec user et partner peuplés
     * @param {String} oldStatus - Ancien statut
     * @param {String} newStatus - Nouveau statut
     */
    static emitReservationStatusChange(reservation, oldStatus, newStatus) {
        try {
            if (!io || !reservation) return;

            const eventData = {
                reservationId: reservation._id,
                oldStatus,
                newStatus,
                timestamp: new Date().toISOString(),
                userId: reservation.user?._id,
                partnerId: reservation.partner?._id || reservation.partner,
                residenceId: reservation.residence?._id || reservation.residence,
                residenceTitle: reservation.residence?.title
            };

            // Notifier le client (user)
            if (reservation.user?._id) {
                io.to(`user_${reservation.user._id}`).emit('reservation_status_changed', eventData);
            }

            // Notifier le partenaire
            if (reservation.partner) {
                const partnerId = reservation.partner._id || reservation.partner;
                io.to(`user_${partnerId}`).emit('partner_reservation_status_changed', eventData);
            }

            // Notifier dans la salle de la résidence
            if (reservation.residence) {
                const residenceId = reservation.residence._id || reservation.residence;
                io.to(`residence_${residenceId}`).emit('residence_reservation_update', eventData);
            }

            logger.info(`Événement WebSocket émis pour réservation ${reservation._id}: ${oldStatus} → ${newStatus}`);
        } catch (error) {
            logger.error('Erreur lors de l\'émission de l\'événement changement statut réservation:', error);
        }
    }

    /**
     * Émet un événement de nouvelle réservation créée
     * @param {Object} reservation - Réservation avec user, partner et residence peuplés
     */
    static emitNewReservation(reservation) {
        try {
            if (!io || !reservation) return;

            const eventData = {
                reservationId: reservation._id,
                status: reservation.status,
                paymentStatus: reservation.paymentStatus,
                timestamp: new Date().toISOString(),
                userId: reservation.user?._id,
                partnerId: reservation.partner?._id || reservation.partner,
                residenceId: reservation.residence?._id || reservation.residence,
                residenceTitle: reservation.residence?.title,
                checkIn: reservation.checkIn,
                checkOut: reservation.checkOut,
                totalPrice: reservation.totalPrice
            };

            // Notifier le partenaire (nouvelle réservation reçue)
            if (reservation.partner) {
                const partnerId = reservation.partner._id || reservation.partner;
                io.to(`user_${partnerId}`).emit('new_reservation_received', eventData);
            }

            // Notifier dans la salle de la résidence pour admins/stats
            if (reservation.residence) {
                const residenceId = reservation.residence._id || reservation.residence;
                io.to(`residence_${residenceId}`).emit('residence_new_reservation', eventData);
            }

            logger.info(`Événement WebSocket nouvelle réservation émis pour ${reservation._id}`);
        } catch (error) {
            logger.error('Erreur lors de l\'émission de l\'événement nouvelle réservation:', error);
        }
    }

    /**
     * Émet un événement de notification de délai de paiement
     * @param {Object} reservation - Réservation avec user peuplé
     * @param {Date} deadline - Date limite de paiement
     */
    static emitPaymentDeadlineNotification(reservation, deadline) {
        try {
            if (!io || !reservation || !reservation.user) return;

            const timeLeft = Math.max(0, Math.ceil((deadline - new Date()) / (1000 * 60))); // Minutes

            const eventData = {
                reservationId: reservation._id,
                deadline: deadline.toISOString(),
                timeLeftMinutes: timeLeft,
                amount: reservation.totalPrice,
                residenceTitle: reservation.residence?.title,
                timestamp: new Date().toISOString()
            };

            // Notifier le client uniquement
            io.to(`user_${reservation.user._id}`).emit('payment_deadline_warning', eventData);

            logger.info(`Notification délai paiement WebSocket envoyée pour réservation ${reservation._id} (${timeLeft} min restantes)`);
        } catch (error) {
            logger.error('Erreur lors de l\'émission de la notification délai paiement:', error);
        }
    }

    /**
     * Émet un événement d'expiration de réservation
     * @param {Object} reservation - Réservation avec user et partner peuplés
     */
    static emitReservationExpired(reservation) {
        try {
            if (!io || !reservation) return;

            const eventData = {
                reservationId: reservation._id,
                expiredAt: new Date().toISOString(),
                residenceTitle: reservation.residence?.title,
                amount: reservation.totalPrice
            };

            // Notifier le client
            if (reservation.user?._id) {
                io.to(`user_${reservation.user._id}`).emit('reservation_expired', eventData);
            }

            // Notifier le partenaire
            if (reservation.partner) {
                const partnerId = reservation.partner._id || reservation.partner;
                io.to(`user_${partnerId}`).emit('partner_reservation_expired', eventData);
            }

            logger.info(`Événement expiration réservation WebSocket émis pour ${reservation._id}`);
        } catch (error) {
            logger.error('Erreur lors de l\'émission de l\'événement expiration réservation:', error);
        }
    }
}

module.exports = SocketService;
