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
}

module.exports = SocketService;
