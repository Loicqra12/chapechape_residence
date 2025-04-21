/**
 * Erreurs spécifiques au domaine des résidences
 * Utilise les codes d'erreur standardisés pour assurer une gestion cohérente
 */

const ApiError = require('../apiError');
const { RESIDENCE } = require('../errorCodes');

class ResidenceErrors {
    /**
     * Erreur lorsqu'une résidence n'est pas trouvée
     * @param {string} residenceId - ID de la résidence
     * @param {Object} data - Données supplémentaires
     */
    static notFound(residenceId, data = {}) {
        return ApiError.notFound(
            `Résidence avec l'ID ${residenceId} non trouvée`,
            RESIDENCE.NOT_FOUND,
            { residenceId, ...data }
        );
    }

    /**
     * Erreur lorsque les données de la résidence sont invalides
     * @param {Array} errors - Liste des erreurs de validation
     */
    static invalidData(errors = []) {
        return ApiError.validationError(
            'Données de résidence invalides',
            RESIDENCE.INVALID_DATA,
            errors
        );
    }

    /**
     * Erreur lorsque l'utilisateur n'est pas autorisé à accéder à la résidence
     * @param {string} userId - ID de l'utilisateur
     * @param {string} residenceId - ID de la résidence
     * @param {string} action - Action tentée
     */
    static unauthorizedAccess(userId, residenceId, action) {
        return ApiError.forbidden(
            `Vous n'êtes pas autorisé à ${action} cette résidence`,
            RESIDENCE.UNAUTHORIZED_ACCESS,
            { userId, residenceId, action }
        );
    }

    /**
     * Erreur lorsque le nombre d'images dépasse la limite
     * @param {number} currentCount - Nombre actuel d'images
     * @param {number} maxImages - Nombre maximum d'images autorisé
     */
    static maxImagesExceeded(currentCount, maxImages) {
        return ApiError.badRequest(
            `Le nombre d'images (${currentCount}) dépasse la limite autorisée (${maxImages})`,
            RESIDENCE.MAX_IMAGES_EXCEEDED,
            [],
            { currentCount, maxImages }
        );
    }

    /**
     * Erreur lorsque la résidence n'est pas disponible
     * @param {string} residenceId - ID de la résidence
     * @param {string} reason - Raison de l'indisponibilité
     */
    static unavailable(residenceId, reason = 'La résidence n\'est pas disponible') {
        return ApiError.badRequest(
            reason,
            RESIDENCE.UNAVAILABLE,
            [],
            { residenceId }
        );
    }

    /**
     * Erreur lorsqu'une résidence avec des caractéristiques similaires existe déjà
     * @param {string} address - Adresse de la résidence
     * @param {string} existingResidenceId - ID de la résidence existante
     */
    static alreadyExists(address, existingResidenceId) {
        return ApiError.conflict(
            `Une résidence existe déjà à cette adresse: ${address}`,
            RESIDENCE.ALREADY_EXISTS,
            [],
            { address, existingResidenceId }
        );
    }

    /**
     * Erreur lorsque le prix de la résidence est invalide
     * @param {number} price - Prix fourni
     * @param {string} reason - Raison de l'invalidité
     */
    static invalidPrice(price, reason = 'Prix invalide') {
        return ApiError.badRequest(
            reason,
            RESIDENCE.INVALID_PRICE,
            [],
            { price }
        );
    }

    /**
     * Erreur lorsque la localisation de la résidence est invalide
     * @param {Object} location - Données de localisation
     * @param {string} reason - Raison de l'invalidité
     */
    static invalidLocation(location, reason = 'Localisation invalide') {
        return ApiError.badRequest(
            reason,
            RESIDENCE.INVALID_LOCATION,
            [],
            { location }
        );
    }

    /**
     * Erreur lorsqu'une opération sur la résidence a échoué
     * @param {string} operation - Opération tentée
     * @param {string} reason - Raison de l'échec
     * @param {Object} data - Données supplémentaires
     */
    static operationFailed(operation, reason, data = {}) {
        return ApiError.internal(
            `L'opération '${operation}' a échoué: ${reason}`,
            RESIDENCE.OPERATION_FAILED,
            data
        );
    }
}

module.exports = ResidenceErrors;
