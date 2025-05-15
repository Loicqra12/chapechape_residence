const logger = require('../utils/logger');
const axios = require('axios');
const Notification = require('../models/notification.model');

class OneSignalService {
    constructor() {
        this.appId = process.env.ONESIGNAL_APP_ID;
        this.apiKey = process.env.ONESIGNAL_API_KEY;
        // Pour l'API v2, on utilise la clé complète commençant par os_v2_...
        this.restApiKey = process.env.ONESIGNAL_API_KEY;
        this.enabled = false;
        this.baseUrl = 'https://api.onesignal.com';  // URL correcte dans la documentation la plus récente

        this.initialize();
    }

    initialize() {
        try {
            // Ne pas initialiser si les clés ne sont pas définies
            if (!this.appId || !this.restApiKey) {
                logger.warn('OneSignal non initialisé: APP_ID ou REST_API_KEY manquant');
                return;
            }

            this.enabled = true;
            logger.info('Service OneSignal initialisé avec succès');
        } catch (error) {
            logger.error('Erreur lors de l\'initialisation du service OneSignal:', error);
        }
    }

    async sendNotification(notificationData) {
        if (!this.enabled) {
            logger.warn('OneSignal désactivé, notification non envoyée');
            return null;
        }

        try {
            // S'assurer que l'app_id est inclus
            const notification = {
                app_id: this.appId,
                ...notificationData
            };

            logger.info(`Envoi de notification OneSignal: ${JSON.stringify(notification)}`);

            // Créer l'URL complète
            const url = `${this.baseUrl}/notifications`;
            
            // Déboguer les valeurs utilisées
            logger.info(`URL: ${url}`);
            logger.info(`Authorization: Key ${this.restApiKey.substring(0, 10)}...`);
            logger.info(`App ID: ${this.appId}`);
            
            const response = await axios({
                method: 'POST',
                url: url,
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Key ${this.restApiKey}`
                },
                data: notification
            });

            logger.info(`Réponse OneSignal: ${JSON.stringify(response.data)}`);
            return response.data;
        } catch (error) {
            logger.error('Erreur lors de l\'envoi de la notification OneSignal:', 
                error.response ? error.response.data : error.message);
            throw error;
        }
    }

    /**
     * Envoie une notification à un utilisateur spécifique
     * @param {string} playerId - ID de l'appareil OneSignal
     * @param {string} title - Titre de la notification
     * @param {string} message - Contenu de la notification
     * @param {Object} data - Données additionnelles
     * @returns {Promise} - Résultat de l'envoi
     */
    async sendToUser(playerId, title, message, data = {}) {
        if (!this.enabled || !playerId) {
            logger.warn('OneSignal désactivé ou ID manquant, notification non envoyée');
            return null;
        }

        return this.sendNotification({
            contents: {
                'en': message,
                'fr': message
            },
            headings: {
                'en': title,
                'fr': title
            },
            include_player_ids: [playerId],
            data
        });
    }

    /**
     * Envoie une notification à plusieurs utilisateurs par leurs IDs d'appareils
     * @param {Array<string>} playerIds - Liste des IDs d'appareils OneSignal
     * @param {string} title - Titre de la notification
     * @param {string} message - Contenu de la notification
     * @param {Object} data - Données additionnelles
     * @returns {Promise} - Résultat de l'envoi
     */
    async sendToMultipleUsers(playerIds, title, message, data = {}) {
        if (!this.enabled || !playerIds || !playerIds.length) {
            logger.warn('OneSignal désactivé ou aucun destinataire, notification non envoyée');
            return null;
        }

        return this.sendNotification({
            contents: {
                'en': message,
                'fr': message
            },
            headings: {
                'en': title,
                'fr': title
            },
            include_player_ids: playerIds,
            data
        });
    }

    /**
     * Envoie une notification à un segment d'utilisateurs
     * @param {string} segment - Nom du segment OneSignal
     * @param {string} title - Titre de la notification
     * @param {string} message - Contenu de la notification
     * @param {Object} data - Données additionnelles
     * @returns {Promise} - Résultat de l'envoi
     */
    async sendToSegment(segment, title, message, data = {}) {
        if (!this.enabled) {
            logger.warn('OneSignal désactivé, notification segment non envoyée');
            return null;
        }

        return this.sendNotification({
            contents: {
                'en': message,
                'fr': message
            },
            headings: {
                'en': title,
                'fr': title
            },
            included_segments: [segment],
            data
        });
    }

    /**
     * Envoie une notification à tous les utilisateurs
     * @param {string} title - Titre de la notification
     * @param {string} message - Contenu de la notification
     * @param {Object} data - Données additionnelles
     * @returns {Promise} - Résultat de l'envoi
     */
    async sendToAll(title, message, data = {}) {
        if (!this.enabled) {
            logger.warn('OneSignal désactivé, notification à tous non envoyée');
            return null;
        }

        return this.sendNotification({
            contents: {
                'en': message,
                'fr': message
            },
            headings: {
                'en': title,
                'fr': title
            },
            included_segments: ['All'],
            data
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
}

module.exports = new OneSignalService();
