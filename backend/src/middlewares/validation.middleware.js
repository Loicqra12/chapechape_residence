const ApiError = require('../utils/apiError');
const { ERROR_MESSAGES } = require('../utils/constants');
const { validationResult } = require('express-validator');

// Middleware de validation générique
const validate = (schema) => {
    return (req, res, next) => {
        const { error } = schema.validate(req.body);
        if (error) {
            return res.status(400).json({
                success: false,
                message: error.details[0].message
            });
        }
        next();
    };
};

// Middleware de validation des paramètres
const validateParams = (schema) => {
    return (req, res, next) => {
        const { error } = schema.validate(req.params);
        if (error) {
            return res.status(400).json({
                success: false,
                message: error.details[0].message
            });
        }
        next();
    };
};

// Middleware de validation des requêtes
const validateQuery = (schema) => {
    return (req, res, next) => {
        const { error } = schema.validate(req.query);
        if (error) {
            return res.status(400).json({
                success: false,
                message: error.details[0].message
            });
        }
        next();
    };
};

// Middleware de validation des fichiers
const validateFiles = (options = {}) => {
    return (req, res, next) => {
        if (!req.files && !req.file) {
            return next();
        }

        const files = req.files || [req.file];
        const {
            maxSize = 5 * 1024 * 1024, // 5MB
            allowedTypes = ['image/jpeg', 'image/png', 'image/webp'],
            maxCount = 10
        } = options;

        // Vérifier le nombre de fichiers
        if (files.length > maxCount) {
            return res.status(400).json({
                success: false,
                message: `Maximum ${maxCount} files allowed`
            });
        }

        // Vérifier chaque fichier
        for (const file of files) {
            // Vérifier la taille
            if (file.size > maxSize) {
                return res.status(400).json({
                    success: false,
                    message: `File size should be less than ${maxSize / (1024 * 1024)}MB`
                });
            }

            // Vérifier le type
            if (!allowedTypes.includes(file.mimetype)) {
                return res.status(400).json({
                    success: false,
                    message: `File type not allowed. Allowed types: ${allowedTypes.join(', ')}`
                });
            }
        }

        next();
    };
};

// Middleware de validation des dates
const validateDates = (checkInField = 'checkIn', checkOutField = 'checkOut') => {
    return (req, res, next) => {
        const checkIn = new Date(req.body[checkInField]);
        const checkOut = new Date(req.body[checkOutField]);
        const now = new Date();

        // Vérifier si les dates sont valides
        if (isNaN(checkIn.getTime()) || isNaN(checkOut.getTime())) {
            return res.status(400).json({
                success: false,
                message: 'Invalid date format'
            });
        }

        // Vérifier si la date d'arrivée est dans le futur
        if (checkIn < now) {
            return res.status(400).json({
                success: false,
                message: 'Check-in date must be in the future'
            });
        }

        // Vérifier si la date de départ est après la date d'arrivée
        if (checkOut <= checkIn) {
            return res.status(400).json({
                success: false,
                message: 'Check-out date must be after check-in date'
            });
        }

        next();
    };
};

// Middleware de validation des IDs MongoDB
const validateMongoId = (paramName = 'id') => {
    return (req, res, next) => {
        const id = req.params[paramName];
        if (!id.match(/^[0-9a-fA-F]{24}$/)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid ID format'
            });
        }
        next();
    };
};

// Middleware de validation pour express-validator
const validateExpressValidator = (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
        return res.status(400).json({
            success: false,
            message: 'Erreurs de validation',
            errors: errors.array()
        });
    }
    next();
};

module.exports = {
    validate: validateExpressValidator, // Pour express-validator (utilisé dans pricing.routes.js)
    validateJoi: validate, // Pour Joi (utilisé ailleurs)
    validateParams,
    validateQuery,
    validateFiles,
    validateDates,
    validateMongoId
};
