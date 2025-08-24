const Joi = require('joi');
const apiError = require('../utils/apiError');

const logger = require('../utils/logger');

const validate = (schema) => (req, res, next) => {
    logger.info('Middleware de validation appelé', { 
        url: req.originalUrl, 
        method: req.method,
        hasSchema: !!schema 
    });
    
    const validSchema = pick(schema, ['params', 'query', 'body']);
    const object = pick(req, Object.keys(validSchema));
    const { value, error } = Joi.compile(validSchema)
        .prefs({ errors: { label: 'key' }, abortEarly: false })
        .validate(object);

    if (error) {
        const errorMessage = error.details
            .map((details) => details.message)
            .join(', ');
        logger.error('Erreur de validation', { error: errorMessage, body: req.body });
        return next(new apiError(errorMessage, 400));
    }
    
    logger.info('Validation réussie, passage au contrôleur');
    Object.assign(req, value);
    return next();
};

const pick = (object, keys) => {
    return keys.reduce((obj, key) => {
        if (object && Object.prototype.hasOwnProperty.call(object, key)) {
            obj[key] = object[key];
        }
        return obj;
    }, {});
};

module.exports = validate;
