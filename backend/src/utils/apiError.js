/**
 * Classe d'erreur standardisée pour l'API ChapeChape
 * Permet une gestion cohérente des erreurs à travers l'application
 */
class ApiError extends Error {
    /**
     * Crée une nouvelle instance d'ApiError
     * @param {string} message - Message d'erreur lisible par l'homme
     * @param {number} statusCode - Code de statut HTTP
     * @param {string} errorCode - Code d'erreur spécifique (de errorCodes.js)
     * @param {Array} errors - Liste d'erreurs détaillées (facultatif)
     * @param {Object} data - Données supplémentaires liées à l'erreur (facultatif)
     */
    constructor(message, statusCode = 500, errorCode = 'GENERAL_SERVER_ERROR', errors = [], data = {}) {
        super(message);
        this.statusCode = statusCode;
        this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
        this.errorCode = errorCode;
        this.errors = errors;
        this.data = data;
        this.isOperational = true;

        Error.captureStackTrace(this, this.constructor);
    }

    /**
     * Crée une erreur 400 Bad Request
     * @param {string} message - Message d'erreur
     * @param {string} errorCode - Code d'erreur spécifique
     * @param {Array} errors - Liste d'erreurs détaillées
     * @param {Object} data - Données supplémentaires
     */
    static badRequest(message = 'Bad Request', errorCode = 'GENERAL_BAD_REQUEST', errors = [], data = {}) {
        return new ApiError(message, 400, errorCode, errors, data);
    }

    /**
     * Crée une erreur 401 Unauthorized
     * @param {string} message - Message d'erreur
     * @param {string} errorCode - Code d'erreur spécifique
     */
    static unauthorized(message = 'Unauthorized', errorCode = 'GENERAL_UNAUTHORIZED_ACCESS', data = {}) {
        return new ApiError(message, 401, errorCode, [], data);
    }

    /**
     * Crée une erreur 403 Forbidden
     * @param {string} message - Message d'erreur
     * @param {string} errorCode - Code d'erreur spécifique
     */
    static forbidden(message = 'Forbidden', errorCode = 'GENERAL_FORBIDDEN_ACCESS', data = {}) {
        return new ApiError(message, 403, errorCode, [], data);
    }

    /**
     * Crée une erreur 404 Not Found
     * @param {string} message - Message d'erreur
     * @param {string} errorCode - Code d'erreur spécifique
     */
    static notFound(message = 'Resource not found', errorCode = 'GENERAL_RESOURCE_NOT_FOUND', data = {}) {
        return new ApiError(message, 404, errorCode, [], data);
    }

    /**
     * Crée une erreur 409 Conflict
     * @param {string} message - Message d'erreur
     * @param {string} errorCode - Code d'erreur spécifique
     */
    static conflict(message = 'Conflict', errorCode = 'GENERAL_CONFLICT', data = {}) {
        return new ApiError(message, 409, errorCode, [], data);
    }

    /**
     * Crée une erreur 422 Unprocessable Entity
     * @param {string} message - Message d'erreur
     * @param {string} errorCode - Code d'erreur spécifique
     * @param {Array} errors - Liste d'erreurs détaillées
     */
    static validationError(message = 'Validation Error', errorCode = 'GENERAL_VALIDATION_ERROR', errors = []) {
        return new ApiError(message, 422, errorCode, errors);
    }

    /**
     * Crée une erreur 500 Internal Server Error
     * @param {string} message - Message d'erreur
     * @param {string} errorCode - Code d'erreur spécifique
     */
    static internal(message = 'Internal Server Error', errorCode = 'GENERAL_SERVER_ERROR', data = {}) {
        return new ApiError(message, 500, errorCode, [], data);
    }

    /**
     * Crée une erreur 503 Service Unavailable
     * @param {string} message - Message d'erreur
     * @param {string} errorCode - Code d'erreur spécifique
     */
    static serviceUnavailable(message = 'Service Unavailable', errorCode = 'GENERAL_SERVICE_UNAVAILABLE', data = {}) {
        return new ApiError(message, 503, errorCode, [], data);
    }
}

module.exports = ApiError;
