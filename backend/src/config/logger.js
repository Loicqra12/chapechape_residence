const winston = require('winston');
const DailyRotateFile = require('winston-daily-rotate-file');
const path = require('path');

// Configuration des niveaux de log personnalisés
const levels = {
    error: 0,
    warn: 1,
    info: 2,
    http: 3,
    debug: 4
};

// Configuration des couleurs pour la console
const colors = {
    error: 'red',
    warn: 'yellow',
    info: 'green',
    http: 'magenta',
    debug: 'blue'
};

winston.addColors(colors);

// Format personnalisé
const format = winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.errors({ stack: true }),
    winston.format.json(),
    winston.format.printf(
        (info) => `${info.timestamp} ${info.level}: ${info.message}${info.stack ? '\n' + info.stack : ''}`
    )
);

// Configuration des transports
const transports = [
    // Console en développement
    new winston.transports.Console({
        format: winston.format.combine(
            winston.format.colorize({ all: true }),
            winston.format.simple()
        )
    }),

    // Fichiers de log quotidiens pour les erreurs
    new DailyRotateFile({
        filename: path.join(__dirname, '../logs/error-%DATE%.log'),
        datePattern: 'YYYY-MM-DD',
        level: 'error',
        maxSize: '20m',
        maxFiles: '14d'
    }),

    // Fichiers de log quotidiens pour toutes les informations
    new DailyRotateFile({
        filename: path.join(__dirname, '../logs/combined-%DATE%.log'),
        datePattern: 'YYYY-MM-DD',
        maxSize: '20m',
        maxFiles: '14d'
    })
];

// Création du logger
const logger = winston.createLogger({
    level: process.env.NODE_ENV === 'development' ? 'debug' : 'info',
    levels,
    format,
    transports
});

// Middleware pour les requêtes HTTP
const httpLogger = (req, res, next) => {
    const start = Date.now();
    res.on('finish', () => {
        const duration = Date.now() - start;
        logger.http(
            `${req.method} ${req.originalUrl} ${res.statusCode} ${duration}ms`
        );
    });
    next();
};

// Fonction pour logger les performances
const logPerformance = (operation, duration) => {
    logger.info(`Performance - ${operation}: ${duration}ms`);
};

// Fonction pour logger les erreurs avec contexte
const logError = (error, context = {}) => {
    logger.error({
        message: error.message,
        stack: error.stack,
        context,
        timestamp: new Date().toISOString()
    });
};

module.exports = {
    logger,
    httpLogger,
    logPerformance,
    logError
};
