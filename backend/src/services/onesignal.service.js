const logger = require('../utils/logger');
const axios = require('axios');
const Notification = require('../models/notification.model');
const { getCategoryByNotificationType } = require('../utils/notification-types');

const ANDROID_CHANNELS = {
  bookings: 'chapechape_bookings',
  payments: 'chapechape_payments',
  messages: 'chapechape_messages',
  promotions: 'chapechape_promotions',
  system: 'chapechape_system',
};

function isHttpsUrl(url) {
  return typeof url === 'string' && /^https:\/\/\S+/i.test(url.trim());
}

class OneSignalService {
    constructor() {
        this.appId = process.env.ONESIGNAL_APP_ID;
        this.apiKey = process.env.ONESIGNAL_API_KEY;
        // Priorité à la variable REST dédiée, fallback rétro-compatible
        this.restApiKey = process.env.ONESIGNAL_REST_API_KEY || process.env.ONESIGNAL_API_KEY;
        this.enabled = false;
        this.baseUrl = 'https://api.onesignal.com';
        this.defaultLargeIconUrl = process.env.CHAPECHAPE_NOTIFICATION_LOGO_URL || null;

        this.initialize();
    }

    initialize() {
        try {
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

    /**
     * Construit un payload Android enrichi (titre métier + icônes + groupe + canal).
     * Les URL optionnelles ne sont ajoutées que si HTTPS valide.
     */
    buildRichNotificationPayload(title, message, data = {}, targets = {}) {
        const type = data.type || data.pushType || '';
        const category = data.category || getCategoryByNotificationType(type);
        const channelId = ANDROID_CHANNELS[category] || ANDROID_CHANNELS.system;

        // data métier sans champs purement visuels (évite doublons inutiles côté app)
        const {
            imageUrl,
            largeIconUrl,
            bigPicture,
            ...restData
        } = data || {};

        const payload = {
            contents: {
                en: message,
                fr: message,
            },
            headings: {
                en: title,
                fr: title,
            },
            small_icon: 'ic_stat_chapechape',
            android_accent_color: 'FFFF9800',
            existing_android_channel_id: channelId,
            android_group: `chapechape_${category}`,
            priority: 10,
            ttl: 86400,
            data: {
                ...restData,
                type: restData.type || type,
                category,
            },
            ...targets,
        };

        const largeIcon = largeIconUrl || this.defaultLargeIconUrl;
        if (isHttpsUrl(largeIcon)) {
            payload.large_icon = largeIcon.trim();
        }

        const picture = bigPicture || imageUrl;
        if (isHttpsUrl(picture)) {
            payload.big_picture = picture.trim();
            // iOS rich media (best effort, ignoré si non supporté)
            payload.ios_attachments = { image: picture.trim() };
        }

        return payload;
    }

    async sendNotification(notificationData) {
        if (!this.enabled) {
            logger.warn('OneSignal désactivé, notification non envoyée');
            return null;
        }

        try {
            const notification = {
                app_id: this.appId,
                ...notificationData
            };

            const hasPlayerTargets = Array.isArray(notification.include_subscription_ids);
            const hasSegmentTargets = Array.isArray(notification.included_segments);
            const targetCount = hasPlayerTargets ? notification.include_subscription_ids.length : 0;
            const segments = hasSegmentTargets ? notification.included_segments : [];
            const dataKeys = notification.data && typeof notification.data === 'object'
                ? Object.keys(notification.data)
                : [];

            logger.info('Envoi notification OneSignal', {
                targetMode: hasPlayerTargets ? 'subscription_ids' : (hasSegmentTargets ? 'segments' : 'unknown'),
                targetCount,
                segments,
                hasData: dataKeys.length > 0,
                dataKeys,
                channel: notification.existing_android_channel_id || null,
                group: notification.android_group || null,
                hasBigPicture: !!notification.big_picture,
                hasLargeIcon: !!notification.large_icon,
            });

            const url = `${this.baseUrl}/notifications`;

            const response = await axios({
                method: 'POST',
                url: url,
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Key ${this.restApiKey}`
                },
                data: notification
            });

            const result = {
                success: true,
                status: 'sent',
                providerId: response.data?.id || null,
                recipients: response.data?.recipients ?? 0,
                raw: response.data,
            };

            if (!result.providerId || result.recipients <= 0) {
                logger.warn('OneSignal a répondu sans destinataire utile', result);
                return {
                    ...result,
                    success: false,
                    status: 'skipped',
                    reason: 'no_recipients',
                };
            }

            logger.info('Réponse OneSignal reçue', {
                notificationId: result.providerId,
                recipients: result.recipients,
            });
            return result;
        } catch (error) {
            logger.error('Erreur lors de l\'envoi de la notification OneSignal:', {
                message: error.message,
                status: error.response?.status,
                errorCode: error.response?.data?.errors?.[0] || error.response?.data?.error
            });
            throw error;
        }
    }

    async sendToUser(playerId, title, message, data = {}) {
        if (!this.enabled || !playerId) {
            logger.warn('OneSignal désactivé ou ID manquant, notification non envoyée');
            return null;
        }

        return this.sendNotification(
            this.buildRichNotificationPayload(title, message, data, {
                include_subscription_ids: [playerId],
            })
        );
    }

    async sendToMultipleUsers(playerIds, title, message, data = {}) {
        if (!this.enabled || !playerIds || !playerIds.length) {
            logger.warn('OneSignal désactivé ou aucun destinataire, notification non envoyée');
            return null;
        }

        return this.sendNotification(
            this.buildRichNotificationPayload(title, message, data, {
                include_subscription_ids: playerIds,
            })
        );
    }

    async sendToSegment(segment, title, message, data = {}) {
        if (!this.enabled) {
            logger.warn('OneSignal désactivé, notification segment non envoyée');
            return null;
        }

        return this.sendNotification(
            this.buildRichNotificationPayload(title, message, data, {
                included_segments: [segment],
            })
        );
    }

    async sendToAll(title, message, data = {}) {
        if (!this.enabled) {
            logger.warn('OneSignal désactivé, notification à tous non envoyée');
            return null;
        }

        return this.sendNotification(
            this.buildRichNotificationPayload(title, message, data, {
                included_segments: ['All'],
            })
        );
    }

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
