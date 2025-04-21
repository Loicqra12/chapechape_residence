/**
 * Erreurs spécifiques au domaine des réservations
 * Utilise les codes d'erreur standardisés pour assurer une gestion cohérente
 */

const ApiError = require('../apiError');
const { BOOKING } = require('../errorCodes');

class BookingErrors {
    /**
     * Erreur lorsqu'une réservation n'est pas trouvée
     * @param {string} bookingId - ID de la réservation
     * @param {Object} data - Données supplémentaires
     */
    static notFound(bookingId, data = {}) {
        return ApiError.notFound(
            `Réservation avec l'ID ${bookingId} non trouvée`,
            BOOKING.NOT_FOUND,
            { bookingId, ...data }
        );
    }

    /**
     * Erreur lorsque les dates de réservation ne sont pas valides
     * @param {string} message - Message d'erreur spécifique
     * @param {Object} data - Données des dates invalides
     */
    static invalidDates(message = 'Dates de réservation invalides', data = {}) {
        return ApiError.badRequest(
            message,
            BOOKING.INVALID_DATES,
            [],
            data
        );
    }

    /**
     * Erreur lorsqu'il y a un conflit de dates pour une réservation
     * @param {Date} checkIn - Date d'arrivée
     * @param {Date} checkOut - Date de départ
     * @param {string} residenceId - ID de la résidence
     */
    static dateConflict(checkIn, checkOut, residenceId) {
        return ApiError.conflict(
            'La résidence n\'est pas disponible pour ces dates',
            BOOKING.DATE_CONFLICT,
            {
                checkIn,
                checkOut,
                residenceId
            }
        );
    }

    /**
     * Erreur lorsqu'une réservation a déjà le statut demandé
     * @param {string} bookingId - ID de la réservation
     * @param {string} currentStatus - Statut actuel
     */
    static alreadyInStatus(bookingId, currentStatus) {
        let errorCode;
        let message;

        switch (currentStatus) {
            case 'confirmed':
                errorCode = BOOKING.ALREADY_CONFIRMED;
                message = 'La réservation est déjà confirmée';
                break;
            case 'cancelled':
                errorCode = BOOKING.ALREADY_CANCELLED;
                message = 'La réservation est déjà annulée';
                break;
            case 'completed':
                errorCode = BOOKING.ALREADY_CONFIRMED;
                message = 'La réservation est déjà terminée';
                break;
            default:
                errorCode = BOOKING.INVALID_STATUS_CHANGE;
                message = `La réservation est déjà en statut ${currentStatus}`;
        }

        return ApiError.badRequest(
            message,
            errorCode,
            [],
            { bookingId, currentStatus }
        );
    }

    /**
     * Erreur lorsqu'un changement de statut n'est pas permis
     * @param {string} bookingId - ID de la réservation
     * @param {string} currentStatus - Statut actuel
     * @param {string} targetStatus - Statut cible
     */
    static invalidStatusChange(bookingId, currentStatus, targetStatus) {
        return ApiError.badRequest(
            `Impossible de changer le statut de '${currentStatus}' à '${targetStatus}'`,
            BOOKING.INVALID_STATUS_CHANGE,
            [],
            { bookingId, currentStatus, targetStatus }
        );
    }

    /**
     * Erreur lorsque le nombre de personnes dépasse la limite
     * @param {number} guestCount - Nombre de personnes demandé
     * @param {number} maxGuests - Nombre maximum autorisé
     */
    static guestLimitExceeded(guestCount, maxGuests) {
        return ApiError.badRequest(
            `Le nombre de personnes (${guestCount}) dépasse la limite autorisée (${maxGuests})`,
            BOOKING.GUEST_LIMIT_EXCEEDED,
            [],
            { guestCount, maxGuests }
        );
    }

    /**
     * Erreur lorsque la durée minimale de séjour n'est pas atteinte
     * @param {number} requestedNights - Nombre de nuits demandé
     * @param {number} minimumNights - Nombre minimum de nuits requis
     */
    static minimumStayNotMet(requestedNights, minimumNights) {
        return ApiError.badRequest(
            `La durée du séjour (${requestedNights} nuits) est inférieure au minimum requis (${minimumNights} nuits)`,
            BOOKING.MINIMUM_STAY_NOT_MET,
            [],
            { requestedNights, minimumNights }
        );
    }

    /**
     * Erreur lorsque la résidence n'est pas disponible
     * @param {string} residenceId - ID de la résidence
     * @param {string} reason - Raison de l'indisponibilité
     */
    static residenceUnavailable(residenceId, reason = 'La résidence n\'est pas disponible') {
        return ApiError.badRequest(
            reason,
            BOOKING.RESIDENCE_UNAVAILABLE,
            [],
            { residenceId }
        );
    }

    /**
     * Erreur lorsque l'utilisateur n'est pas autorisé à effectuer une action sur la réservation
     * @param {string} userId - ID de l'utilisateur
     * @param {string} bookingId - ID de la réservation
     * @param {string} action - Action tentée
     */
    static unauthorizedAction(userId, bookingId, action) {
        return ApiError.forbidden(
            `Vous n'êtes pas autorisé à ${action} cette réservation`,
            BOOKING.UNAUTHORIZED_ACTION,
            { userId, bookingId, action }
        );
    }
}

module.exports = BookingErrors;
