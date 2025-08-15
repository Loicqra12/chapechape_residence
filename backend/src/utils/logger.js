const winston = require('winston');
require('winston-daily-rotate-file');
const path = require('path');
const morgan = require('morgan');

// 🔒 SÉCURITÉ : Système de sanitization des logs
// Liste des champs sensibles à masquer dans les logs
const SENSITIVE_FIELDS = [
    'password', 'token', 'auth', 'secret', 'key', 'private', 'credential',
    'api_key', 'apikey', 'authorization', 'bearer', 'jwt', 'session',
    'cookie', 'csrf', 'otp', 'pin', 'ssn', 'credit_card', 'card_number',
    'cvv', 'expiry', 'bank_account', 'stripe_secret', 'paypal_secret',
    'oauth_secret', 'client_secret', 'refresh_token', 'access_token',
    'mongo_uri', 'database_url', 'db_password', 'smtp_password',
    'twilio_auth_token', 'brevo_api_key', 'cloudinary_secret',
    'onesignal_key', 'google_api_key', 'firebase_private_key'
];

/**
 * Sanitise récursivement un objet en masquant les champs sensibles
 * @param {any} obj - L'objet à sanitiser
 * @param {number} depth - Profondeur de récursion (protection contre les références circulaires)
 * @returns {any} - L'objet sanitisé
 */
function sanitizeObject(obj, depth = 0) {
    if (depth > 10) return '[CIRCULAR]'; // Protection contre la récursion infinie
    
    if (obj === null || obj === undefined) return obj;
    
    if (typeof obj === 'string') {
        // Masquer les patterns sensibles dans les chaînes
        return obj.replace(/(password|token|secret|key|auth)\s*[=:]\s*[^\s&,]+/gi, '$1=***MASKED***');
    }
    
    if (typeof obj !== 'object') return obj;
    
    if (Array.isArray(obj)) {
        return obj.map(item => sanitizeObject(item, depth + 1));
    }
    
    const sanitized = {};
    for (const [key, value] of Object.entries(obj)) {
        const lowerKey = key.toLowerCase();
        const isSensitive = SENSITIVE_FIELDS.some(field => lowerKey.includes(field));
        
        if (isSensitive) {
            sanitized[key] = '***MASKED***';
        } else {
            sanitized[key] = sanitizeObject(value, depth + 1);
        }
    }
    
    return sanitized;
}

/**
 * Format Winston personnalisé avec sanitization automatique
 */
const sanitizeFormat = winston.format((info) => {
    // Sanitiser le message principal
    if (typeof info.message === 'object') {
        info.message = sanitizeObject(info.message);
    } else if (typeof info.message === 'string') {
        info.message = sanitizeObject(info.message);
    }
    
    // Sanitiser tous les autres champs
    Object.keys(info).forEach(key => {
        if (key !== 'level' && key !== 'timestamp') {
            info[key] = sanitizeObject(info[key]);
        }
    });
    
    return info;
});

const logDir = path.join(__dirname, '../../logs');

// 🔒 Formats personnalisés avec sanitization de sécurité
const formats = [
    winston.format.timestamp(),
    sanitizeFormat(), // Application de la sanitization AVANT la sérialisation JSON
    winston.format.json()
];

// Configuration de Winston
const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.combine(...formats),
    transports: [
        new winston.transports.DailyRotateFile({
            filename: path.join(logDir, '%DATE%-error.log'),
            datePattern: 'YYYY-MM-DD',
            zippedArchive: true,
            maxSize: '20m',
            maxFiles: '14d',
            level: 'error'
        }),
        new winston.transports.DailyRotateFile({
            filename: path.join(logDir, '%DATE%-combined.log'),
            datePattern: 'YYYY-MM-DD',
            zippedArchive: true,
            maxSize: '20m',
            maxFiles: '14d'
        })
    ]
});

// Ajouter la sortie console en développement
if (process.env.NODE_ENV !== 'production') {
    logger.add(new winston.transports.Console({
        format: winston.format.combine(
            winston.format.colorize(),
            winston.format.simple()
        )
    }));
}

// Créer un stream pour Morgan
const stream = {
    write: (message) => {
        logger.info(message.trim());
    }
};

// Middleware HTTP avec Morgan
const httpLogger = morgan('combined', { stream });

// Logging des requêtes HTTP
logger.http = httpLogger;

// Fonctions de logging spécialisées
const logPerformance = (operation, duration, details = {}) => {
    logger.info('Performance Metric', {
        type: 'performance',
        operation,
        duration,
        ...details
    });
};

const logUserAction = (userId, action, details = {}) => {
    logger.info('User Action', {
        type: 'user_action',
        userId,
        action,
        ...details
    });
};

const logSecurityEvent = (type, details = {}) => {
    logger.warn('Security Event', {
        type: 'security',
        securityType: type,
        ...details
    });
};

const logSystemEvent = (type, details = {}) => {
    logger.info('System Event', {
        type: 'system',
        systemType: type,
        ...details
    });
};

module.exports = {
    error: logger.error.bind(logger),
    warn: logger.warn.bind(logger),
    info: logger.info.bind(logger),
    debug: logger.debug.bind(logger),
    http: httpLogger,
    logPerformance,
    logUserAction,
    logSecurityEvent,
    logSystemEvent
};
