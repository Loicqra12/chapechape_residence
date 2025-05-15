const Notification = require('../models/notification.model');
const User = require('../models/user.model');
const emailService = require('./email.service');
const oneSignalService = require('./onesignal.service');
const logger = require('../utils/logger');
const notificationTypes = require('../utils/notification-types');

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

            // Récupérer l'utilisateur pour avoir son email et ses tokens d'appareils
            const user = await User.findById(userId);
            if (!user) {
                logger.warn(`Notification créée mais utilisateur ${userId} non trouvé`);
                return notification;
            }

            // Envoyer un email de notification si activé dans les préférences de l'utilisateur
            if (user.email && (!user.notificationSettings || user.notificationSettings.emailEnabled !== false)) {
                await emailService.sendNotificationEmail(user, notification);
            }

            // Envoyer notification push via OneSignal si l'utilisateur a des tokens d'appareils
            if (user.deviceTokens && user.deviceTokens.length && 
                (!user.notificationSettings || user.notificationSettings.pushEnabled !== false)) {
                try {
                    await oneSignalService.sendToMultipleUsers(
                        user.deviceTokens,
                        'ChapeChape Notification',
                        message,
                        {
                            notificationId: notification._id.toString(),
                            type,
                            ...data
                        }
                    );
                    logger.info(`Notification push envoyée à l'utilisateur ${userId}`);
                } catch (pushError) {
                    logger.error(`Erreur lors de l'envoi de la notification push:`, pushError);
                    // On continue même si la notification push échoue
                }
            }

            return notification;
        } catch (error) {
            logger.error('Erreur lors de la création de la notification:', error);
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

    /**
     * Compte les notifications non lues d'un utilisateur
     * @param {string} userId - ID de l'utilisateur
     * @returns {Promise<number>} - Nombre de notifications non lues
     */
    async countUnreadNotifications(userId) {
        try {
            const count = await Notification.countDocuments({ 
                user: userId, 
                read: false 
            });
            return count;
        } catch (error) {
            logger.error('Erreur lors du comptage des notifications non lues:', error);
            throw error;
        }
    }

    // Notifier un utilisateur
    async notifyUser(userId, type, message, data = {}) {
        // Créer la notification dans la base de données
        const notification = await this.createNotification(userId, type, message, data);

        return notification;
    }

    // Notifier un client (pour les notifications spécifiques à l'application client)
    async notifyClient(clientId, type, data = {}) {
        // Utiliser les types et titres définis
        const title = notificationTypes.getTitleByType(type);
        let message;
        
        switch (type) {
            case notificationTypes.CLIENT.BOOKING_CONFIRMED:
                message = `Votre réservation ${data.bookingCode ? `#${data.bookingCode} ` : ''}a été confirmée${data.residenceName ? ` pour "${data.residenceName}"` : ''}.`;
                break;
            case notificationTypes.CLIENT.ARRIVAL_REMINDER:
                message = `Rappel: Votre arrivée${data.residenceName ? ` à "${data.residenceName}"` : ''} est prévue ${data.arrivalDate ? `le ${data.arrivalDate}` : 'aujourd\'hui'}${data.arrivalTime ? ` à ${data.arrivalTime}` : ''}.`;
                break;
            case notificationTypes.CLIENT.DEPARTURE_REMINDER:
                message = `Rappel: Votre départ${data.residenceName ? ` de "${data.residenceName}"` : ''} est prévu ${data.departureDate ? `le ${data.departureDate}` : 'aujourd\'hui'}${data.departureTime ? ` à ${data.departureTime}` : ''}.`;
                break;
            case notificationTypes.CLIENT.SPECIAL_OFFER:
                message = `Offre spéciale pour vous: ${data.offerTitle || 'Nouvelle offre disponible'}. ${data.offerDescription || ''}`;
                break;
            case notificationTypes.CLIENT.DISCOUNT:
                message = `Remise exclusive de ${data.discountAmount || ''}${data.discountPercentage ? `${data.discountPercentage}%` : ''} ${data.discountDescription || 'sur votre prochaine réservation'}.`;
                break;
            case notificationTypes.CLIENT.POPULAR_RESIDENCE:
                message = `"${data.residenceName || 'Une résidence populaire'}" est très demandée. ${data.additionalInfo || 'Réservez maintenant pour ne pas la manquer!'}`;
                break;
            case notificationTypes.CLIENT.LIMITED_AVAILABILITY:
                message = `Plus que ${data.availableUnits || 'quelques'} logements disponibles${data.residenceName ? ` à "${data.residenceName}"` : ''}${data.locationName ? ` à ${data.locationName}` : ''}.`;
                break;
            case notificationTypes.CLIENT.NEARBY_RESIDENCE:
                message = `${data.residenceCount || 'Plusieurs'} résidences sont disponibles près de ${data.locationName || 'votre position actuelle'}.`;
                break;
            case notificationTypes.COMMON.NEW_MESSAGE:
                message = `Vous avez reçu un nouveau message${data.senderName ? ` de ${data.senderName}` : ''}.`;
                break;
            default:
                message = data.message || 'Notification ChapeChape';
        }

        // Créer la notification
        const notification = await this.createNotification(clientId, type, message, data);
        
        // Envoyer un email si applicable
        if ([
            notificationTypes.CLIENT.BOOKING_CONFIRMED,
            notificationTypes.CLIENT.ARRIVAL_REMINDER,
            notificationTypes.CLIENT.DEPARTURE_REMINDER
        ].includes(type)) {
            await emailService.sendClientNotification(clientId, type, {
                title,
                message,
                ...data
            });
        }

        return notification;
    }

    // Notifier un partenaire
    async notifyPartner(partnerId, type, data = {}) {
        let message;

        // Utiliser les types et titres définis
        const title = notificationTypes.getTitleByType(type);
        
        switch (type) {
            case notificationTypes.PARTNER.NEW_BOOKING:
                message = `Vous avez reçu une nouvelle réservation${data.residenceName ? ` pour "${data.residenceName}"` : ''}.`;
                break;
            case notificationTypes.PARTNER.BOOKING_MODIFIED:
                message = `Une réservation a été modifiée${data.residenceName ? ` pour "${data.residenceName}"` : ''}.`;
                break;
            case notificationTypes.PARTNER.BOOKING_CANCELED:
                message = `Une réservation a été annulée${data.residenceName ? ` pour "${data.residenceName}"` : ''}.`;
                break;
            case notificationTypes.PARTNER.PAYMENT_RECEIVED:
                message = `Vous avez reçu un paiement de ${data.amount || 'montant non spécifié'}${data.currency ? ` ${data.currency}` : ''}${data.residenceName ? ` pour "${data.residenceName}"` : ''}.`;
                break;
            case notificationTypes.PARTNER.DEPOSIT_RECEIVED:
                message = `Vous avez reçu un dépôt de garantie de ${data.amount || 'montant non spécifié'}${data.currency ? ` ${data.currency}` : ''}${data.residenceName ? ` pour "${data.residenceName}"` : ''}.`;
                break;
            case notificationTypes.PARTNER.MONTHLY_STATS:
                message = `Vos statistiques du mois sont disponibles. ${data.summary || 'Consultez votre tableau de bord pour plus de détails.'}`; 
                break;
            case notificationTypes.PARTNER.NEW_REVIEW:
                message = `Vous avez reçu une nouvelle évaluation${data.rating ? ` de ${data.rating}/5` : ''}${data.residenceName ? ` pour "${data.residenceName}"` : ''}.`;
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

    // ----- MÉTHODES UTILITAIRES POUR LES CAS D'UTILISATION SPÉCIFIQUES -----

    /**
     * Envoie des notifications pour les résidences à proximité d'une position géographique
     * @param {string} clientId - ID du client
     * @param {Object} location - Objet contenant lat et lng
     * @param {number} radius - Rayon de recherche en kilomètres
     * @returns {Promise} - Notification envoyée
     */
    async sendNearbyResidencesNotification(clientId, location, radius = 5) {
        try {
            // Ici, on pourrait appeler un service pour récupérer les résidences à proximité
            // Pour l'exemple, on suppose qu'on a déjà les données
            const data = {
                locationName: location.name || 'votre position',
                residenceCount: location.count || 'Plusieurs',
                lat: location.lat,
                lng: location.lng,
                radius
            };

            return await this.notifyClient(
                clientId, 
                notificationTypes.CLIENT.NEARBY_RESIDENCE, 
                data
            );
        } catch (error) {
            logger.error('Erreur lors de l\'envoi de notification de proximité:', error);
            throw error;
        }
    }

    /**
     * Programme des rappels d'arrivée et de départ pour une réservation
     * @param {Object} booking - Objet de réservation
     * @returns {Promise} - Résultat des programmations
     */
    async scheduleBookingReminders(booking) {
        try {
            const clientId = booking.client;
            const residenceName = booking.residence.title || booking.residence.name || 'votre résidence';
            
            // Données pour les rappels
            const arrivalData = {
                bookingId: booking._id,
                residenceName,
                arrivalDate: new Date(booking.checkInDate).toLocaleDateString('fr-FR'),
                arrivalTime: booking.checkInTime || '14:00',
                address: booking.residence.location?.formattedAddress || booking.residence.address
            };
            
            const departureData = {
                bookingId: booking._id,
                residenceName,
                departureDate: new Date(booking.checkOutDate).toLocaleDateString('fr-FR'),
                departureTime: booking.checkOutTime || '12:00'
            };

            // Calculer les délais pour les rappels
            const now = new Date();
            const arrivalDate = new Date(booking.checkInDate);
            const departureDate = new Date(booking.checkOutDate);
            
            // Programmer les rappels (dans un environnement de production, utilisez un service comme Bull/Agenda)
            // Exemple simplifié pour la démonstration
            
            // Rappel 24h avant l'arrivée
            if (arrivalDate > now) {
                const dayBeforeArrival = new Date(arrivalDate);
                dayBeforeArrival.setDate(dayBeforeArrival.getDate() - 1);
                
                // En production, utilisez un système de tâches programmées comme Bull
                // setTimeout() n'est pas fiable pour des délais longs en production
                const delayArrival = Math.max(0, dayBeforeArrival.getTime() - now.getTime());
                
                if (delayArrival < 2147483647) { // Limite de setTimeout en millisecondes
                    setTimeout(() => {
                        this.notifyClient(clientId, notificationTypes.CLIENT.ARRIVAL_REMINDER, arrivalData);
                    }, delayArrival);
                    
                    logger.info(`Rappel d'arrivée programmé pour le client ${clientId} dans ${Math.round(delayArrival/3600000)} heures`);
                }
            }
            
            // Rappel 24h avant le départ
            if (departureDate > now) {
                const dayBeforeDeparture = new Date(departureDate);
                dayBeforeDeparture.setDate(dayBeforeDeparture.getDate() - 1);
                
                const delayDeparture = Math.max(0, dayBeforeDeparture.getTime() - now.getTime());
                
                if (delayDeparture < 2147483647) {
                    setTimeout(() => {
                        this.notifyClient(clientId, notificationTypes.CLIENT.DEPARTURE_REMINDER, departureData);
                    }, delayDeparture);
                    
                    logger.info(`Rappel de départ programmé pour le client ${clientId} dans ${Math.round(delayDeparture/3600000)} heures`);
                }
            }

            return { 
                success: true, 
                message: 'Rappels programmés avec succès'
            };
        } catch (error) {
            logger.error('Erreur lors de la programmation des rappels:', error);
            throw error;
        }
    }

    /**
     * Envoie une notification concernant une résidence populaire ou à disponibilité limitée
     * @param {Array} clientIds - Liste des IDs clients à notifier
     * @param {Object} residence - Objet de résidence
     * @param {number} availableUnits - Nombre d'unités disponibles
     * @returns {Promise} - Résultat des notifications
     */
    async sendLimitedAvailabilityNotification(clientIds, residence, availableUnits) {
        try {
            const promises = clientIds.map(clientId => {
                const data = {
                    residenceId: residence._id,
                    residenceName: residence.title || residence.name,
                    availableUnits,
                    locationName: residence.location?.city || residence.location?.formattedAddress,
                    imageUrl: residence.images && residence.images.length > 0 ? residence.images[0] : null
                };
                
                const notificationType = availableUnits <= 2 
                    ? notificationTypes.CLIENT.LIMITED_AVAILABILITY 
                    : notificationTypes.CLIENT.POPULAR_RESIDENCE;
                
                return this.notifyClient(clientId, notificationType, data);
            });
            
            const results = await Promise.all(promises);
            logger.info(`Notifications d'occupation envoyées à ${results.length} clients`);
            
            return {
                success: true,
                notificationsSent: results.length
            };
        } catch (error) {
            logger.error('Erreur lors de l\'envoi des notifications d\'occupation:', error);
            throw error;
        }
    }

    /**
     * Envoie une notification de statistiques mensuelles aux partenaires
     * @param {Object} partnerStats - Statistiques du partenaire
     * @returns {Promise} - Résultat de la notification
     */
    async sendMonthlyStatsNotification(partnerStats) {
        try {
            const { partnerId, month, year, totalBookings, totalRevenue, occupancyRate } = partnerStats;
            
            const monthNames = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 
                               'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
            
            const data = {
                month: monthNames[month - 1],
                year,
                totalBookings,
                totalRevenue,
                occupancyRate: `${occupancyRate}%`,
                summary: `${totalBookings} réservations, ${totalRevenue} FCFA de revenus, taux d'occupation de ${occupancyRate}%`
            };
            
            return await this.notifyPartner(
                partnerId,
                notificationTypes.PARTNER.MONTHLY_STATS,
                data
            );
        } catch (error) {
            logger.error('Erreur lors de l\'envoi des statistiques mensuelles:', error);
            throw error;
        }
    }
}

module.exports = new NotificationService();
