/**
 * Service de gestion et journalisation centralisée des erreurs
 * Permet de tracer les erreurs métier et techniques
 */

const { logger } = require('../utils/logger');
const errorCodes = require('../utils/errorCodes');

class ErrorService {
    /**
     * Journalise une erreur avec le contexte complet
     * @param {Error|ApiError} error - L'erreur à journaliser
     * @param {Object} context - Contexte supplémentaire (utilisateur, requête, etc.)
     */
    logError(error, context = {}) {
        // Extraire les détails de l'erreur
        const errorDetails = {
            message: error.message,
            stack: error.stack,
            statusCode: error.statusCode,
            errorCode: error.errorCode,
            errors: error.errors,
            isOperational: error.isOperational,
            context: this._sanitizeContext(context)
        };

        // Choisir le niveau de log en fonction de la gravité
        if (error.statusCode >= 500) {
            logger.error('SERVER_ERROR', errorDetails);
        } else if (error.statusCode >= 400) {
            logger.warn('CLIENT_ERROR', errorDetails);
        } else {
            logger.info('OTHER_ERROR', errorDetails);
        }

        // Si l'erreur est critique, on peut envoyer une alerte
        if (this._isCriticalError(error)) {
            this._sendAlert(error, context);
        }

        return errorDetails;
    }

    /**
     * Journalise une erreur liée à une réservation
     * @param {Error|ApiError} error - L'erreur à journaliser
     * @param {Object} booking - La réservation concernée
     * @param {Object} user - L'utilisateur qui a généré l'erreur
     */
    logBookingError(error, booking, user) {
        // Extraire les informations essentielles de la réservation
        const bookingInfo = booking ? {
            id: booking._id,
            residenceId: booking.residence,
            status: booking.status,
            checkIn: booking.checkIn,
            checkOut: booking.checkOut
        } : null;

        // Extraire les informations essentielles de l'utilisateur
        const userInfo = user ? {
            id: user._id,
            email: user.email,
            role: user.role
        } : null;

        // Journaliser avec le contexte approprié
        return this.logError(error, {
            domain: 'booking',
            booking: bookingInfo,
            user: userInfo
        });
    }

    /**
     * Journalise une erreur liée à un paiement
     * @param {Error|ApiError} error - L'erreur à journaliser
     * @param {Object} payment - Le paiement concerné
     * @param {Object} user - L'utilisateur qui a généré l'erreur
     */
    logPaymentError(error, payment, user) {
        // Extraire les informations essentielles du paiement
        const paymentInfo = payment ? {
            id: payment._id,
            amount: payment.amount,
            status: payment.status,
            method: payment.method,
            reservationId: payment.reservation
        } : null;

        // Extraire les informations essentielles de l'utilisateur
        const userInfo = user ? {
            id: user._id,
            email: user.email,
            role: user.role
        } : null;

        // Journaliser avec le contexte approprié
        return this.logError(error, {
            domain: 'payment',
            payment: paymentInfo,
            user: userInfo
        });
    }

    /**
     * Journalise une erreur liée à l'authentification
     * @param {Error|ApiError} error - L'erreur à journaliser 
     * @param {Object} user - Informations sur l'utilisateur (si disponible)
     * @param {Object} req - Objet requête Express
     */
    logAuthError(error, user, req) {
        // Extraire des informations sur l'utilisateur (si disponible)
        const userInfo = user ? {
            id: user._id,
            email: user.email,
            role: user.role
        } : null;

        // Extraire des informations sur la requête
        const requestInfo = req ? {
            ip: req.ip,
            userAgent: req.headers['user-agent'],
            method: req.method,
            path: req.path
        } : null;

        // Journaliser avec le contexte approprié
        return this.logError(error, {
            domain: 'authentication',
            user: userInfo,
            request: requestInfo
        });
    }

    /**
     * Nettoie le contexte des informations sensibles
     * @param {Object} context - Le contexte à nettoyer
     * @returns {Object} - Le contexte nettoyé
     * @private
     */
    _sanitizeContext(context) {
        // Créer une copie du contexte
        const sanitized = JSON.parse(JSON.stringify(context));

        // Liste des champs sensibles à supprimer
        const sensitiveFields = ['password', 'token', 'refreshToken', 'creditCard', 'cardNumber'];

        // Fonction récursive pour nettoyer les objets imbriqués
        const sanitizeObject = (obj) => {
            if (!obj || typeof obj !== 'object') return;

            for (const key in obj) {
                if (sensitiveFields.includes(key)) {
                    obj[key] = '[REDACTED]';
                } else if (typeof obj[key] === 'object') {
                    sanitizeObject(obj[key]);
                }
            }
        };

        sanitizeObject(sanitized);
        return sanitized;
    }

    /**
     * Vérifie si une erreur est critique
     * @param {Error|ApiError} error - L'erreur à vérifier
     * @returns {boolean} - True si l'erreur est critique
     * @private
     */
    _isCriticalError(error) {
        // Les erreurs serveur sont considérées comme critiques
        if (error.statusCode >= 500) return true;

        // Certains codes d'erreur métier peuvent aussi être critiques
        const criticalErrorCodes = [
            errorCodes.PAYMENT.FAILED,
            errorCodes.BOOKING.INVALID_STATUS_CHANGE,
            errorCodes.AUTH.ACCOUNT_DISABLED
        ];

        return error.errorCode && criticalErrorCodes.includes(error.errorCode);
    }

    /**
     * Envoie une alerte pour les erreurs critiques
     * @param {Error|ApiError} error - L'erreur critique
     * @param {Object} context - Le contexte de l'erreur
     * @private
     */
    _sendAlert(error, context) {
        // Implémentation à personnaliser (email, SMS, notification Slack, etc.)
        logger.error('CRITICAL_ERROR_ALERT', {
            message: error.message,
            errorCode: error.errorCode,
            context: this._sanitizeContext(context)
        });

        // TODO: Intégrer avec un service d'alerte externe
        // Exemple: sendSlackNotification('Erreur critique: ' + error.message);
    }
}

module.exports = new ErrorService();
