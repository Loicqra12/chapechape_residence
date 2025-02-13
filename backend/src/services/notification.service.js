const Notification = require('../models/notification.model');
const User = require('../models/user.model');
const emailService = require('./email.service');

class NotificationService {
    // Créer une notification
    async createNotification(userId, type, message, data = {}) {
        try {
            const notification = await Notification.create({
                user: userId,
                type,
                message,
                data,
                read: false
            });

            // Récupérer l'utilisateur pour avoir son email
            const user = await User.findById(userId);
            if (user && user.email) {
                // Envoyer un email de notification
                await emailService.sendNotificationEmail(user, notification);
            }

            return notification;
        } catch (error) {
            console.error('Erreur lors de la création de la notification:', error);
            throw error;
        }
    }

    // Obtenir les notifications d'un utilisateur
    async getUserNotifications(userId, page = 1, limit = 10) {
        const skip = (page - 1) * limit;

        const total = await Notification.countDocuments({ user: userId });
        const notifications = await Notification.find({ user: userId })
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit);

        return {
            notifications,
            total,
            page: parseInt(page),
            pages: Math.ceil(total / limit)
        };
    }

    // Marquer une notification comme lue
    async markAsRead(notificationId, userId) {
        return await Notification.findOneAndUpdate(
            { _id: notificationId, user: userId },
            { read: true },
            { new: true }
        );
    }

    // Marquer toutes les notifications comme lues
    async markAllAsRead(userId) {
        await Notification.updateMany(
            { user: userId, read: false },
            { read: true }
        );
    }

    // Supprimer une notification
    async deleteNotification(notificationId, userId) {
        return await Notification.findOneAndDelete({
            _id: notificationId,
            user: userId
        });
    }

    // Supprimer toutes les notifications lues
    async deleteReadNotifications(userId) {
        return await Notification.deleteMany({
            user: userId,
            read: true
        });
    }

    // Notifier un utilisateur
    async notifyUser(userId, type, message, data = {}) {
        // Créer la notification dans la base de données
        const notification = await this.createNotification(userId, type, message, data);

        return notification;
    }

    // Notifier un partenaire
    async notifyPartner(partnerId, type, data = {}) {
        let message;

        switch (type) {
            case 'new_booking':
                message = 'Nouvelle réservation reçue';
                break;
            case 'booking_cancelled':
                message = 'Une réservation a été annulée';
                break;
            case 'new_review':
                message = 'Nouveau commentaire reçu';
                break;
            default:
                message = 'Nouvelle notification';
        }

        // Créer la notification
        const notification = await this.createNotification(partnerId, type, message, data);

        // Envoyer un email
        await emailService.sendPartnerNotification(partnerId, type, data);

        return notification;
    }

    // Notifier un admin
    async notifyAdmin(adminId, type, message, data = {}) {
        return await this.createNotification(adminId, type, message, data);
    }

    // Notifier plusieurs utilisateurs
    async notifyMultipleUsers(userIds, type, message, data = {}) {
        const notifications = await Promise.all(
            userIds.map(userId =>
                this.createNotification(userId, type, message, data)
            )
        );

        return notifications;
    }

    // Supprimer les anciennes notifications
    async cleanOldNotifications(days = 30) {
        const date = new Date();
        date.setDate(date.getDate() - days);

        return await Notification.deleteMany({
            createdAt: { $lt: date },
            read: true
        });
    }
}

module.exports = new NotificationService();
