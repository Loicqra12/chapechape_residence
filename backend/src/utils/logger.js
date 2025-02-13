const winston = require('winston');
require('winston-daily-rotate-file');
const path = require('path');
const morgan = require('morgan');

const logDir = path.join(__dirname, '../../logs');

// Formats personnalisés
const formats = [
    winston.format.timestamp(),
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
