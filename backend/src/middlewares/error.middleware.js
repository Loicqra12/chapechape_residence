const ApiError = require('../utils/apiError');
const { logger } = require('../utils/logger');
const { ERROR_MESSAGES } = require('../utils/constants');
const errorCodes = require('../utils/errorCodes');

/**
 * Middleware de gestion d'erreurs global pour l'API
 * Traite toutes les erreurs et renvoie une réponse standardisée
 */
const errorHandler = (err, req, res, next) => {
    // Log l'erreur
    logger.error(`${err.name}: ${err.message}\n${err.stack}`);

    // Structure de réponse d'erreur standardisée
    let error = {
        success: false,
        message: err.message || ERROR_MESSAGES.SERVER_ERROR,
        errorCode: err.errorCode || errorCodes.GENERAL.SERVER_ERROR,
        errors: err.errors || [],
        data: err.data || {}
    };

    // Erreur de validation Mongoose
    if (err.name === 'ValidationError') {
        const errors = Object.values(err.errors).map(e => ({
            field: e.path,
            message: e.message
        }));
        
        return res.status(400).json({
            success: false,
            message: ERROR_MESSAGES.VALIDATION_ERROR,
            errorCode: errorCodes.GENERAL.VALIDATION_ERROR,
            errors: errors,
            data: {}
        });
    }

    // Erreur de cast Mongoose (ID invalide)
    if (err.name === 'CastError') {
        return res.status(400).json({
            success: false,
            message: `Invalid ${err.path}: ${err.value}`,
            errorCode: errorCodes.GENERAL.VALIDATION_ERROR,
            errors: [{
                field: err.path,
                message: `Invalid ${err.path} format`
            }],
            data: {}
        });
    }

    // Erreur de duplication MongoDB
    if (err.code === 11000) {
        const field = Object.keys(err.keyValue)[0];
        const value = err.keyValue[field];
        
        // Déterminer le code d'erreur approprié en fonction du champ dupliqué
        let errorCode = errorCodes.GENERAL.VALIDATION_ERROR;
        
        if (field === 'email') {
            errorCode = errorCodes.USER.DUPLICATE_EMAIL;
        }
        
        return res.status(409).json({
            success: false,
            message: `Duplicate value for field: ${field}`,
            errorCode: errorCode,
            errors: [{
                field: field,
                message: `The ${field} '${value}' is already taken`
            }],
            data: {}
        });
    }

    // Erreur JWT
    if (err.name === 'JsonWebTokenError') {
        return res.status(401).json({
            success: false,
            message: 'Invalid token',
            errorCode: errorCodes.AUTH.INVALID_TOKEN,
            errors: [],
            data: {}
        });
    }

    // Erreur d'expiration JWT
    if (err.name === 'TokenExpiredError') {
        return res.status(401).json({
            success: false,
            message: 'Token expired',
            errorCode: errorCodes.AUTH.EXPIRED_TOKEN,
            errors: [],
            data: {}
        });
    }

    // Erreur personnalisée ApiError
    if (err instanceof ApiError) {
        return res.status(err.statusCode).json({
            success: false,
            message: err.message,
            errorCode: err.errorCode,
            errors: err.errors,
            data: err.data
        });
    }

    // Erreur de fichier trop grand
    if (err.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({
            success: false,
            message: 'File too large',
            errorCode: errorCodes.MEDIA.FILE_TOO_LARGE,
            errors: [],
            data: { maxSize: process.env.MAX_FILE_SIZE || '5MB' }
        });
    }

    // Erreur de type de fichier
    if (err.code === 'LIMIT_UNEXPECTED_FILE') {
        return res.status(400).json({
            success: false,
            message: 'Invalid file type',
            errorCode: errorCodes.MEDIA.INVALID_TYPE,
            errors: [],
            data: {}
        });
    }

    // En production, ne pas envoyer les détails de l'erreur
    if (process.env.NODE_ENV === 'production') {
        // Conserver le code d'erreur si disponible
        const errorResponse = {
            success: false,
            message: ERROR_MESSAGES.SERVER_ERROR,
            errorCode: error.errorCode || errorCodes.GENERAL.SERVER_ERROR,
            errors: [],
            data: {}
        };
        
        // Pour les erreurs 4xx, on peut préserver le message d'erreur même en production
        if (err.statusCode && err.statusCode < 500) {
            errorResponse.message = err.message;
            errorResponse.errors = err.errors || [];
        }
        
        return res.status(err.statusCode || 500).json(errorResponse);
    }

    // Erreur par défaut
    res.status(err.statusCode || 500).json(error);
};

// Gestionnaire pour les routes non trouvées
const notFound = (req, res, next) => {
    next(new ApiError(`Not found - ${req.originalUrl}`, 404));
};

module.exports = {
    errorHandler,
    notFound
};
