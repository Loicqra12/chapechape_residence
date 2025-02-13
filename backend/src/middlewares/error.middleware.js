const ApiError = require('../utils/apiError');
const { logger } = require('../utils/logger');
const { ERROR_MESSAGES } = require('../utils/constants');

// Gestionnaire d'erreurs global
const errorHandler = (err, req, res, next) => {
    // Log l'erreur
    logger.error(`${err.name}: ${err.message}\n${err.stack}`);

    // Erreur par défaut
    let error = {
        success: false,
        message: err.message || ERROR_MESSAGES.SERVER_ERROR,
        errors: []
    };

    // Erreur de validation Mongoose
    if (err.name === 'ValidationError') {
        error.message = ERROR_MESSAGES.VALIDATION_ERROR;
        error.errors = Object.values(err.errors).map(e => e.message);
        return res.status(400).json(error);
    }

    // Erreur de cast Mongoose (ID invalide)
    if (err.name === 'CastError') {
        error.message = `Invalid ${err.path}: ${err.value}`;
        return res.status(400).json(error);
    }

    // Erreur de duplication MongoDB
    if (err.code === 11000) {
        const field = Object.keys(err.keyValue)[0];
        error.message = `Duplicate field value: ${field}`;
        return res.status(409).json(error);
    }

    // Erreur JWT
    if (err.name === 'JsonWebTokenError') {
        error.message = 'Invalid token';
        return res.status(401).json(error);
    }

    // Erreur d'expiration JWT
    if (err.name === 'TokenExpiredError') {
        error.message = 'Token expired';
        return res.status(401).json(error);
    }

    // Erreur personnalisée ApiError
    if (err instanceof ApiError) {
        return res.status(err.statusCode).json({
            success: false,
            message: err.message,
            errors: err.errors
        });
    }

    // Erreur de fichier trop grand
    if (err.code === 'LIMIT_FILE_SIZE') {
        error.message = 'File too large';
        return res.status(400).json(error);
    }

    // Erreur de type de fichier
    if (err.code === 'LIMIT_UNEXPECTED_FILE') {
        error.message = 'Invalid file type';
        return res.status(400).json(error);
    }

    // En production, ne pas envoyer les détails de l'erreur
    if (process.env.NODE_ENV === 'production') {
        error = {
            success: false,
            message: ERROR_MESSAGES.SERVER_ERROR
        };
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
