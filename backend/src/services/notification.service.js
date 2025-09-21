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
            case notificationTypes.CLIENT.PAYMENT_PENDING:
                message = `Paiement en attente pour votre réservation${data.residenceName ? ` à "${data.residenceName}"` : ''}. ${data.amount ? `Montant: ${data.amount} ${data.currency || 'FCFA'}` : ''}`;
                break;
            case notificationTypes.CLIENT.AWAITING_APPROVAL:
                message = `Votre réservation${data.residenceName ? ` pour "${data.residenceName}"` : ''} est en attente d'approbation par l'hôte.`;
                break;
            case notificationTypes.CLIENT.BOOKING_APPROVED:
                message = `Votre réservation${data.residenceName ? ` pour "${data.residenceName}"` : ''} a été approuvée par l'hôte.`;
                break;
            case notificationTypes.CLIENT.BOOKING_REJECTED:
                message = `Votre réservation${data.residenceName ? ` pour "${data.residenceName}"` : ''} a été refusée par l'hôte. ${data.reason || ''}`;
                break;
            case notificationTypes.CLIENT.PAYMENT_EXPIRED:
                message = `Le délai de paiement pour votre réservation${data.residenceName ? ` à "${data.residenceName}"` : ''} a expiré.`;
                break;
            case notificationTypes.CLIENT.CHECKIN_READY:
                message = `Vous pouvez maintenant effectuer votre check-in${data.residenceName ? ` à "${data.residenceName}"` : ''}.`;
                break;
            case notificationTypes.CLIENT.CHECKOUT_REMINDER:
                message = `Rappel: Votre check-out${data.residenceName ? ` de "${data.residenceName}"` : ''} est prévu ${data.checkoutTime ? `à ${data.checkoutTime}` : 'aujourd\'hui'}.`;
                break;
            
            // Notifications de sécurité et vérification
            case notificationTypes.CLIENT.PHONE_CHANGED:
                message = `Votre numéro de téléphone a été changé vers ${data.newPhone || 'nouveau numéro'}.`;
                break;
            case notificationTypes.CLIENT.VERIFICATION_SENT:
                message = `Code de vérification envoyé${data.channel ? ` par ${data.channel.toUpperCase()}` : ''} vers ${data.phoneNumber || 'votre numéro'}.`;
                break;
            case notificationTypes.CLIENT.VERIFICATION_SUCCESS:
                message = `Vérification de numéro de téléphone réussie.`;
                break;
            case notificationTypes.CLIENT.VERIFICATION_FAILED:
                message = `Échec de la vérification de numéro de téléphone. ${data.reason || 'Veuillez réessayer.'}`;
                break;
            case notificationTypes.CLIENT.SECURITY_ALERT:
                message = `Alerte de sécurité: ${data.alert || 'Activité suspecte détectée'}.`;
                break;
            case notificationTypes.CLIENT.LOGIN_ALERT:
                message = `Nouvelle connexion détectée${data.location ? ` depuis ${data.location}` : ''}${data.device ? ` sur ${data.device}` : ''}.`;
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
            
            // Notifications de payout et transfert
            case notificationTypes.PARTNER.PAYOUT_INITIATED:
                message = `Votre payout de ${data.amount || 'montant non spécifié'}${data.currency ? ` ${data.currency}` : ''} a été initié.`;
                break;
            case notificationTypes.PARTNER.PAYOUT_SUCCESS:
                message = `Votre payout de ${data.amount || 'montant non spécifié'}${data.currency ? ` ${data.currency}` : ''} a été traité avec succès.`;
                break;
            case notificationTypes.PARTNER.PAYOUT_FAILED:
                message = `Votre payout de ${data.amount || 'montant non spécifié'}${data.currency ? ` ${data.currency}` : ''} a échoué. ${data.reason || 'Veuillez réessayer.'}`;
                break;
            case notificationTypes.PARTNER.TRANSFER_INITIATED:
                message = `Transfert de ${data.amount || 'montant non spécifié'}${data.currency ? ` ${data.currency}` : ''} vers ${data.recipient || 'destinataire'} initié.`;
                break;
            case notificationTypes.PARTNER.TRANSFER_SUCCESS:
                message = `Transfert de ${data.amount || 'montant non spécifié'}${data.currency ? ` ${data.currency}` : ''} vers ${data.recipient || 'destinataire'} réussi.`;
                break;
            case notificationTypes.PARTNER.TRANSFER_FAILED:
                message = `Transfert de ${data.amount || 'montant non spécifié'}${data.currency ? ` ${data.currency}` : ''} vers ${data.recipient || 'destinataire'} échoué. ${data.reason || 'Veuillez réessayer.'}`;
                break;
            
            // Notifications de sécurité et vérification
            case notificationTypes.PARTNER.PHONE_CHANGED:
                message = `Votre numéro de téléphone a été changé vers ${data.newPhone || 'nouveau numéro'}.`;
                break;
            case notificationTypes.PARTNER.VERIFICATION_SENT:
                message = `Code de vérification envoyé${data.channel ? ` par ${data.channel.toUpperCase()}` : ''} vers ${data.phoneNumber || 'votre numéro'}.`;
                break;
            case notificationTypes.PARTNER.VERIFICATION_SUCCESS:
                message = `Vérification de numéro de téléphone réussie.`;
                break;
            case notificationTypes.PARTNER.VERIFICATION_FAILED:
                message = `Échec de la vérification de numéro de téléphone. ${data.reason || 'Veuillez réessayer.'}`;
                break;
            case notificationTypes.PARTNER.SECURITY_ALERT:
                message = `Alerte de sécurité: ${data.alert || 'Activité suspecte détectée'}.`;
                break;
            case notificationTypes.PARTNER.LOGIN_ALERT:
                message = `Nouvelle connexion détectée${data.location ? ` depuis ${data.location}` : ''}${data.device ? ` sur ${data.device}` : ''}.`;
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
     * Programme des rappels d'arrivée et de départ pour une Réservation (Reservation)
     * Conserve la version Booking pour compatibilité, mais privilégie cette méthode.
     * @param {Object} reservation - Objet Reservation (peut contenir différents alias de champs)
     * @returns {Promise<{success: boolean, message: string}>}
     */
    async scheduleReservationReminders(reservation) {
        try {
            const clientId = reservation.user?._id || reservation.user || reservation.client;
            const residence = reservation.residence || {};
            const residenceName = residence.title || residence.name || 'votre résidence';

            // Support de multiples champs selon variantes de modèle
            const checkInRaw = reservation.checkIn || reservation.checkInDate || reservation.startDate;
            const checkOutRaw = reservation.checkOut || reservation.checkOutDate || reservation.endDate;

            const arrivalData = {
                reservationId: reservation._id,
                residenceName,
                arrivalDate: checkInRaw ? new Date(checkInRaw).toLocaleDateString('fr-FR') : undefined,
                arrivalTime: reservation.checkInTime || '14:00',
                address: residence.location?.formattedAddress || residence.address
            };

            const departureData = {
                reservationId: reservation._id,
                residenceName,
                departureDate: checkOutRaw ? new Date(checkOutRaw).toLocaleDateString('fr-FR') : undefined,
                departureTime: reservation.checkOutTime || '12:00'
            };

            const now = new Date();
            const arrivalDate = checkInRaw ? new Date(checkInRaw) : null;
            const departureDate = checkOutRaw ? new Date(checkOutRaw) : null;

            // Note: setTimeout n'est pas fiable pour de longs délais en production
            if (arrivalDate && arrivalDate > now) {
                const dayBeforeArrival = new Date(arrivalDate);
                dayBeforeArrival.setDate(dayBeforeArrival.getDate() - 1);
                const delayArrival = Math.max(0, dayBeforeArrival.getTime() - now.getTime());
                if (delayArrival < 2147483647) {
                    setTimeout(() => {
                        this.notifyClient(clientId, notificationTypes.CLIENT.ARRIVAL_REMINDER, arrivalData);
                    }, delayArrival);
                    logger.info(`(Reservation) Rappel d'arrivée programmé pour le client ${clientId} dans ${Math.round(delayArrival/3600000)}h`);
                }
            }

            if (departureDate && departureDate > now) {
                const dayBeforeDeparture = new Date(departureDate);
                dayBeforeDeparture.setDate(dayBeforeDeparture.getDate() - 1);
                const delayDeparture = Math.max(0, dayBeforeDeparture.getTime() - now.getTime());
                if (delayDeparture < 2147483647) {
                    setTimeout(() => {
                        this.notifyClient(clientId, notificationTypes.CLIENT.DEPARTURE_REMINDER, departureData);
                    }, delayDeparture);
                    logger.info(`(Reservation) Rappel de départ programmé pour le client ${clientId} dans ${Math.round(delayDeparture/3600000)}h`);
                }
            }

            return { success: true, message: 'Rappels Réservation programmés avec succès' };
        } catch (error) {
            logger.error('Erreur lors de la programmation des rappels (Reservation):', error);
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

    // ✅ PHASE 0 BIS : Méthodes manquantes critiques pour payment-timer.service.js
    
    /**
     * Envoie une notification de délai de paiement
     * @param {Object} reservation - Réservation avec user et residence peuplés
     * @param {Date} deadline - Date limite de paiement
     */
    async sendPaymentDeadlineNotification(reservation, deadline) {
        try {
            if (!reservation || !reservation.user || !deadline) {
                logger.warn('Données insuffisantes pour notification délai paiement');
                return null;
            }

            const timeLeft = Math.max(0, Math.ceil((deadline - new Date()) / (1000 * 60))); // Minutes restantes
            
            const message = `⏰ Paiement requis ! ${timeLeft} min restantes pour votre réservation à ${reservation.residence?.title || 'la résidence'}. Montant: ${reservation.totalPrice || 0} XOF`;

            // Notification push/email standard
            const notification = await this.createNotification(
                reservation.user._id,
                notificationTypes.CLIENT.PAYMENT_PENDING,
                message,
                {
                    reservationId: reservation._id.toString(),
                    deadline: deadline.toISOString(),
                    timeLeftMinutes: timeLeft,
                    amount: reservation.totalPrice
                }
            );

            // SMS de délai si disponible (Twilio)
            if (reservation.user.phoneNumber) {
                try {
                    const twilioService = require('./twilio.service');
                    await twilioService.sendReservationNotification(reservation, 'payment_deadline', {
                        deadline: reservation.ttlSnapshot?.paymentTTLMinutes ? 
                                 new Date(Date.now() + (reservation.ttlSnapshot.paymentTTLMinutes * 60 * 1000)) : 
                                 new Date(Date.now() + (24 * 60 * 60 * 1000))
                    });
                } catch (smsError) {
                    logger.error('Erreur envoi SMS délai paiement:', smsError);
                }
            }

            logger.info(`Notification délai paiement envoyée pour réservation ${reservation._id}`);
            return notification;

        } catch (error) {
            logger.error('Erreur notification délai paiement:', error);
            throw error;
        }
    }

    /**
     * Envoie une notification d'expiration de réservation
     * @param {Object} reservation - Réservation avec user et residence peuplés
     */
    async sendReservationExpiredNotification(reservation) {
        try {
            if (!reservation || !reservation.user) {
                logger.warn('Données insuffisantes pour notification expiration');
                return null;
            }

            const message = `❌ Réservation expirée. Le délai de paiement pour "${reservation.residence?.title || 'votre réservation'}" a expiré. La réservation a été annulée automatiquement.`;

            // Notification Client
            const clientNotification = await this.createNotification(
                reservation.user._id,
                notificationTypes.CLIENT.PAYMENT_EXPIRED,
                message,
                {
                    reservationId: reservation._id.toString(),
                    expiredAt: new Date().toISOString(),
                    amount: reservation.totalPrice
                }
            );

            // Notification Partner si disponible
            if (reservation.partner) {
                const partnerMessage = `📊 Réservation expirée. La réservation de ${reservation.user.firstName || 'Client'} pour "${reservation.residence?.title || 'résidence'}" a expiré (délai paiement dépassé).`;
                
                await this.createNotification(
                    reservation.partner,
                    notificationTypes.PARTNER.BOOKING_EXPIRED,
                    partnerMessage,
                    {
                        reservationId: reservation._id.toString(),
                        clientName: reservation.user.firstName + ' ' + (reservation.user.lastName || ''),
                        expiredAt: new Date().toISOString()
                    }
                );
            }

            // SMS d'expiration si disponible
            if (reservation.user.phoneNumber) {
                try {
                    const twilioService = require('./twilio.service');
                    await twilioService.sendReservationNotification(reservation, 'expired');
                } catch (smsError) {
                    logger.error('Erreur envoi SMS expiration:', smsError);
                }
            }

            logger.info(`Notification expiration envoyée pour réservation ${reservation._id}`);
            return clientNotification;

        } catch (error) {
            logger.error('Erreur notification expiration:', error);
            throw error;
        }
    }

    // ===============================
    // ✅ NOUVELLES MÉTHODES PAYOUT
    // ===============================

    /**
     * Notifier la création d'un payout
     * @param {Object} partner Partner bénéficiaire
     * @param {Object} payoutData Données du payout
     */
    async sendPayoutCreated(partner, payoutData) {
        try {
            const message = `Nouveau reversement programmé: ${payoutData.amount} ${payoutData.currency}`;
            
            // Notification push/email partner
            await this.createNotification(
                partner._id,
                'PAYOUT_CREATED',
                message,
                {
                    payout_id: payoutData.payout_id,
                    amount: payoutData.amount,
                    currency: payoutData.currency,
                    scheduled_for: payoutData.scheduled_for
                }
            );

            // SMS si numéro disponible
            if (partner.phoneNumber) {
                try {
                    const twilioService = require('./twilio.service');
                    await twilioService.sendSMS(
                        partner.phoneNumber,
                        `ChapeChape: Reversement de ${payoutData.amount} ${payoutData.currency} programmé pour ${new Date(payoutData.scheduled_for).toLocaleDateString('fr-FR')}. Vous recevrez une confirmation de transfert.`
                    );
                } catch (smsError) {
                    logger.error('Erreur SMS payout créé:', smsError);
                }
            }

            logger.info(`Notification payout créé envoyée au partner ${partner._id}`);

        } catch (error) {
            logger.error('Erreur notification payout créé:', error);
            throw error;
        }
    }

    /**
     * Notifier l'initiation d'un payout
     * @param {Object} partner Partner bénéficiaire  
     * @param {Object} payoutData Données du payout
     */
    async sendPayoutInitiated(partner, payoutData) {
        try {
            const message = payoutData.requires_confirmation ? 
                `Transfert de ${payoutData.amount} ${payoutData.currency} initié. Confirmation email requise.` :
                `Transfert de ${payoutData.amount} ${payoutData.currency} en cours de traitement.`;
            
            await this.createNotification(
                partner._id,
                'PAYOUT_INITIATED',
                message,
                {
                    transaction_id: payoutData.transaction_id,
                    amount: payoutData.amount,
                    currency: payoutData.currency,
                    requires_confirmation: payoutData.requires_confirmation
                }
            );

            // SMS informatif
            if (partner.phoneNumber) {
                try {
                    const twilioService = require('./twilio.service');
                    const smsMessage = payoutData.requires_confirmation ?
                        `ChapeChape: Transfert de ${payoutData.amount} ${payoutData.currency} initié (ID: ${payoutData.transaction_id}). Vérifiez vos emails pour confirmation.` :
                        `ChapeChape: Transfert de ${payoutData.amount} ${payoutData.currency} en cours (ID: ${payoutData.transaction_id}).`;
                    
                    await twilioService.sendSMS(partner.phoneNumber, smsMessage);
                } catch (smsError) {
                    logger.error('Erreur SMS payout initié:', smsError);
                }
            }

            logger.info(`Notification payout initié envoyée au partner ${partner._id}`);

        } catch (error) {
            logger.error('Erreur notification payout initié:', error);
            throw error;
        }
    }

    /**
     * Notifier la finalisation réussie d'un payout
     * @param {Object} partner Partner bénéficiaire
     * @param {Object} payoutData Données du payout
     */
    async sendPayoutCompleted(partner, payoutData) {
        try {
            const message = `Transfert réussi: ${payoutData.amount} ${payoutData.currency} crédité sur votre compte`;
            
            await this.createNotification(
                partner._id,
                'PAYOUT_COMPLETED',
                message,
                {
                    transaction_id: payoutData.transaction_id,
                    amount: payoutData.amount,
                    currency: payoutData.currency,
                    completed_at: payoutData.completed_at
                }
            );

            // SMS de confirmation
            if (partner.phoneNumber) {
                try {
                    const twilioService = require('./twilio.service');
                    await twilioService.sendSMS(
                        partner.phoneNumber,
                        `✅ ChapeChape: Transfert de ${payoutData.amount} ${payoutData.currency} réussi ! Fonds crédités sur votre compte (ID: ${payoutData.transaction_id}).`
                    );
                } catch (smsError) {
                    logger.error('Erreur SMS payout complété:', smsError);
                }
            }

            // Email de reçu détaillé
            const user = await User.findById(partner._id);
            if (user && user.email) {
                try {
                    const emailService = require('./email.service');
                    await emailService.sendPayoutReceiptEmail(user, payoutData);
                } catch (emailError) {
                    logger.error('Erreur email reçu payout:', emailError);
                }
            }

            logger.info(`Notification payout complété envoyée au partner ${partner._id}`);

        } catch (error) {
            logger.error('Erreur notification payout complété:', error);
            throw error;
        }
    }

    /**
     * Notifier l'échec d'un payout
     * @param {Object} partner Partner bénéficiaire
     * @param {Object} payoutData Données du payout
     */
    async sendPayoutFailed(partner, payoutData) {
        try {
            const message = payoutData.will_retry ? 
                `Transfert temporairement échoué: ${payoutData.reason}. Nouvelle tentative programmée.` :
                `Transfert échoué définitivement: ${payoutData.reason}. Contactez le support.`;
            
            await this.createNotification(
                partner._id,
                'PAYOUT_FAILED',
                message,
                {
                    payout_id: payoutData.payout_id,
                    amount: payoutData.amount,
                    currency: payoutData.currency,
                    reason: payoutData.reason,
                    will_retry: payoutData.will_retry
                }
            );

            // SMS d'alerte
            if (partner.phoneNumber) {
                try {
                    const twilioService = require('./twilio.service');
                    const smsMessage = payoutData.will_retry ?
                        `⚠️ ChapeChape: Transfert de ${payoutData.amount} ${payoutData.currency} temporairement échoué (${payoutData.reason}). Nouvelle tentative en cours.` :
                        `❌ ChapeChape: Transfert de ${payoutData.amount} ${payoutData.currency} échoué (${payoutData.reason}). Contactez le support: support@chapechape.com`;
                    
                    await twilioService.sendSMS(partner.phoneNumber, smsMessage);
                } catch (smsError) {
                    logger.error('Erreur SMS payout échoué:', smsError);
                }
            }

            // Email d'alerte si échec définitif
            if (!payoutData.will_retry) {
                const user = await User.findById(partner._id);
                if (user && user.email) {
                    try {
                        const emailService = require('./email.service');
                        await emailService.sendPayoutFailureEmail(user, payoutData);
                    } catch (emailError) {
                        logger.error('Erreur email payout échoué:', emailError);
                    }
                }
            }

            logger.info(`Notification payout échoué envoyée au partner ${partner._id}`);

        } catch (error) {
            logger.error('Erreur notification payout échoué:', error);
            throw error;
        }
    }

    /**
     * Notifier un solde CinetPay insuffisant (pour admins)
     * @param {number} currentBalance Solde actuel
     * @param {number} requiredAmount Montant requis
     */
    async sendInsufficientBalanceAlert(currentBalance, requiredAmount) {
        try {
            // Notifier tous les admins
            const admins = await User.find({ 
                role: { $in: ['admin', 'superadmin'] },
                isActive: true
            });

            const message = `⚠️ Solde CinetPay insuffisant: ${currentBalance} XOF disponible, ${requiredAmount} XOF requis pour payouts`;

            for (const admin of admins) {
                await this.createNotification(
                    admin._id,
                    'INSUFFICIENT_BALANCE',
                    message,
                    {
                        current_balance: currentBalance,
                        required_amount: requiredAmount,
                        shortage: requiredAmount - currentBalance
                    }
                );

                // SMS urgent pour admins
                if (admin.phoneNumber) {
                    try {
                        const twilioService = require('./twilio.service');
                        await twilioService.sendSMS(
                            admin.phoneNumber,
                            `🚨 URGENT ChapeChape: Solde CinetPay insuffisant (${currentBalance} XOF). Rechargement requis pour continuer les payouts.`
                        );
                    } catch (smsError) {
                        logger.error('Erreur SMS solde insuffisant:', smsError);
                    }
                }
            }

            logger.warn(`Alerte solde insuffisant envoyée à ${admins.length} admins`);

        } catch (error) {
            logger.error('Erreur notification solde insuffisant:', error);
            throw error;
        }
    }

    // ----- NOUVELLES MÉTHODES UTILITAIRES POUR LES NOTIFICATIONS MANQUANTES -----

    /**
     * Notifier un changement de numéro de téléphone
     * @param {string} userId - ID de l'utilisateur
     * @param {string} userRole - Rôle de l'utilisateur ('client' ou 'partner')
     * @param {string} oldPhone - Ancien numéro
     * @param {string} newPhone - Nouveau numéro
     */
    async notifyPhoneChange(userId, userRole, oldPhone, newPhone) {
        try {
            const type = userRole === 'partner' 
                ? notificationTypes.PARTNER.PHONE_CHANGED 
                : notificationTypes.CLIENT.PHONE_CHANGED;

            await this.createNotification(userId, type, '', {
                oldPhone,
                newPhone,
                changedAt: new Date().toISOString()
            });

            logger.info(`Notification changement numéro envoyée à ${userRole} ${userId}`);
        } catch (error) {
            logger.error('Erreur notification changement numéro:', error);
            throw error;
        }
    }

    /**
     * Notifier l'envoi d'un code de vérification
     * @param {string} userId - ID de l'utilisateur
     * @param {string} userRole - Rôle de l'utilisateur
     * @param {string} phoneNumber - Numéro de téléphone
     * @param {string} channel - Canal utilisé (sms, whatsapp)
     */
    async notifyVerificationSent(userId, userRole, phoneNumber, channel) {
        try {
            const type = userRole === 'partner' 
                ? notificationTypes.PARTNER.VERIFICATION_SENT 
                : notificationTypes.CLIENT.VERIFICATION_SENT;

            await this.createNotification(userId, type, '', {
                phoneNumber,
                channel,
                sentAt: new Date().toISOString()
            });

            logger.info(`Notification code envoyé envoyée à ${userRole} ${userId}`);
        } catch (error) {
            logger.error('Erreur notification code envoyé:', error);
            throw error;
        }
    }

    /**
     * Notifier le succès d'une vérification
     * @param {string} userId - ID de l'utilisateur
     * @param {string} userRole - Rôle de l'utilisateur
     * @param {string} phoneNumber - Numéro vérifié
     */
    async notifyVerificationSuccess(userId, userRole, phoneNumber) {
        try {
            const type = userRole === 'partner' 
                ? notificationTypes.PARTNER.VERIFICATION_SUCCESS 
                : notificationTypes.CLIENT.VERIFICATION_SUCCESS;

            await this.createNotification(userId, type, '', {
                phoneNumber,
                verifiedAt: new Date().toISOString()
            });

            logger.info(`Notification vérification réussie envoyée à ${userRole} ${userId}`);
        } catch (error) {
            logger.error('Erreur notification vérification réussie:', error);
            throw error;
        }
    }

    /**
     * Notifier l'échec d'une vérification
     * @param {string} userId - ID de l'utilisateur
     * @param {string} userRole - Rôle de l'utilisateur
     * @param {string} phoneNumber - Numéro concerné
     * @param {string} reason - Raison de l'échec
     */
    async notifyVerificationFailed(userId, userRole, phoneNumber, reason) {
        try {
            const type = userRole === 'partner' 
                ? notificationTypes.PARTNER.VERIFICATION_FAILED 
                : notificationTypes.CLIENT.VERIFICATION_FAILED;

            await this.createNotification(userId, type, '', {
                phoneNumber,
                reason,
                failedAt: new Date().toISOString()
            });

            logger.info(`Notification vérification échouée envoyée à ${userRole} ${userId}`);
        } catch (error) {
            logger.error('Erreur notification vérification échouée:', error);
            throw error;
        }
    }

    /**
     * Notifier une nouvelle connexion
     * @param {string} userId - ID de l'utilisateur
     * @param {string} userRole - Rôle de l'utilisateur
     * @param {Object} loginData - Données de connexion
     */
    async notifyNewLogin(userId, userRole, loginData) {
        try {
            const type = userRole === 'partner' 
                ? notificationTypes.PARTNER.LOGIN_ALERT 
                : notificationTypes.CLIENT.LOGIN_ALERT;

            await this.createNotification(userId, type, '', {
                location: loginData.location,
                device: loginData.device,
                ipAddress: loginData.ipAddress,
                userAgent: loginData.userAgent,
                loginAt: new Date().toISOString()
            });

            logger.info(`Notification nouvelle connexion envoyée à ${userRole} ${userId}`);
        } catch (error) {
            logger.error('Erreur notification nouvelle connexion:', error);
            throw error;
        }
    }

    /**
     * Notifier une alerte de sécurité
     * @param {string} userId - ID de l'utilisateur
     * @param {string} userRole - Rôle de l'utilisateur
     * @param {string} alert - Type d'alerte
     * @param {Object} alertData - Données de l'alerte
     */
    async notifySecurityAlert(userId, userRole, alert, alertData) {
        try {
            const type = userRole === 'partner' 
                ? notificationTypes.PARTNER.SECURITY_ALERT 
                : notificationTypes.CLIENT.SECURITY_ALERT;

            await this.createNotification(userId, type, '', {
                alert,
                ...alertData,
                alertAt: new Date().toISOString()
            });

            logger.info(`Notification alerte sécurité envoyée à ${userRole} ${userId}`);
        } catch (error) {
            logger.error('Erreur notification alerte sécurité:', error);
            throw error;
        }
    }

    /**
     * Notifier l'initiation d'un transfert
     * @param {string} partnerId - ID du partenaire
     * @param {Object} transferData - Données du transfert
     */
    async notifyTransferInitiated(partnerId, transferData) {
        try {
            await this.createNotification(partnerId, notificationTypes.PARTNER.TRANSFER_INITIATED, '', {
                amount: transferData.amount,
                currency: transferData.currency,
                recipient: transferData.recipient,
                method: transferData.method,
                initiatedAt: new Date().toISOString()
            });

            logger.info(`Notification transfert initié envoyée au partner ${partnerId}`);
        } catch (error) {
            logger.error('Erreur notification transfert initié:', error);
            throw error;
        }
    }

    /**
     * Notifier le succès d'un transfert
     * @param {string} partnerId - ID du partenaire
     * @param {Object} transferData - Données du transfert
     */
    async notifyTransferSuccess(partnerId, transferData) {
        try {
            await this.createNotification(partnerId, notificationTypes.PARTNER.TRANSFER_SUCCESS, '', {
                amount: transferData.amount,
                currency: transferData.currency,
                recipient: transferData.recipient,
                method: transferData.method,
                transactionId: transferData.transactionId,
                completedAt: new Date().toISOString()
            });

            logger.info(`Notification transfert réussi envoyée au partner ${partnerId}`);
        } catch (error) {
            logger.error('Erreur notification transfert réussi:', error);
            throw error;
        }
    }

    /**
     * Notifier l'échec d'un transfert
     * @param {string} partnerId - ID du partenaire
     * @param {Object} transferData - Données du transfert
     */
    async notifyTransferFailed(partnerId, transferData) {
        try {
            await this.createNotification(partnerId, notificationTypes.PARTNER.TRANSFER_FAILED, '', {
                amount: transferData.amount,
                currency: transferData.currency,
                recipient: transferData.recipient,
                method: transferData.method,
                reason: transferData.reason,
                failedAt: new Date().toISOString()
            });

            logger.info(`Notification transfert échoué envoyée au partner ${partnerId}`);
        } catch (error) {
            logger.error('Erreur notification transfert échoué:', error);
            throw error;
        }
    }

    /**
     * Notifier l'envoi d'un code de vérification
     * @param {string} userId - ID de l'utilisateur
     * @param {string} phoneNumber - Numéro de téléphone
     * @param {string} channel - Canal utilisé (sms/whatsapp)
     */
    async notifyVerificationSent(userId, phoneNumber, channel) {
        try {
            const user = await User.findById(userId);
            if (!user) return;

            const type = user.role === 'partner' 
                ? notificationTypes.PARTNER.VERIFICATION_SENT 
                : notificationTypes.CLIENT.VERIFICATION_SENT;

            const message = `Code de vérification envoyé par ${channel.toUpperCase()} au ${phoneNumber}`;

            await this.createNotification(userId, type, message, {
                phoneNumber,
                channel,
                sentAt: new Date().toISOString()
            });

            logger.info(`Notification vérification envoyée à ${user.role} ${userId}`);
        } catch (error) {
            logger.error('Erreur notification vérification envoyée:', error);
            throw error;
        }
    }

    /**
     * Notifier le succès de la vérification
     * @param {string} userId - ID de l'utilisateur
     * @param {string} phoneNumber - Numéro de téléphone vérifié
     */
    async notifyVerificationSuccess(userId, phoneNumber) {
        try {
            const user = await User.findById(userId);
            if (!user) return;

            const type = user.role === 'partner' 
                ? notificationTypes.PARTNER.VERIFICATION_SUCCESS 
                : notificationTypes.CLIENT.VERIFICATION_SUCCESS;

            const message = `Numéro ${phoneNumber} vérifié avec succès`;

            await this.createNotification(userId, type, message, {
                phoneNumber,
                verifiedAt: new Date().toISOString()
            });

            logger.info(`Notification vérification réussie envoyée à ${user.role} ${userId}`);
        } catch (error) {
            logger.error('Erreur notification vérification réussie:', error);
            throw error;
        }
    }

    /**
     * Notifier une nouvelle connexion
     * @param {string} userId - ID de l'utilisateur
     * @param {string} ip - Adresse IP
     * @param {string} userAgent - User Agent
     */
    async notifyNewLogin(userId, ip, userAgent) {
        try {
            const user = await User.findById(userId);
            if (!user) return;

            const type = user.role === 'partner' 
                ? notificationTypes.PARTNER.LOGIN_ALERT 
                : notificationTypes.CLIENT.LOGIN_ALERT;

            const message = `Nouvelle connexion détectée depuis ${ip}`;

            await this.createNotification(userId, type, message, {
                ip,
                userAgent,
                loginAt: new Date().toISOString()
            });

            logger.info(`Notification nouvelle connexion envoyée à ${user.role} ${userId}`);
        } catch (error) {
            logger.error('Erreur notification nouvelle connexion:', error);
            throw error;
        }
    }
}

module.exports = new NotificationService();
