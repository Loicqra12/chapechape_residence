const responseTime = require('response-time');
const { logPerformance } = require('../config/logger');

// Middleware pour mesurer le temps de réponse
const performanceMonitor = responseTime((req, res, time) => {
    const route = `${req.method} ${req.originalUrl}`;
    logPerformance(route, time);

    // Alerter si le temps de réponse est trop long
    if (time > 1000) { // Plus d'une seconde
        logPerformance(`Performance Alert - Slow Response: ${route}`, time);
    }
});

// Middleware pour surveiller l'utilisation de la mémoire
const memoryMonitor = (req, res, next) => {
    const used = process.memoryUsage();
    const metrics = {
        rss: `${Math.round(used.rss / 1024 / 1024 * 100) / 100} MB`,
        heapTotal: `${Math.round(used.heapTotal / 1024 / 1024 * 100) / 100} MB`,
        heapUsed: `${Math.round(used.heapUsed / 1024 / 1024 * 100) / 100} MB`,
        external: `${Math.round(used.external / 1024 / 1024 * 100) / 100} MB`
    };

    // Alerter si l'utilisation de la mémoire est trop élevée
    if (used.heapUsed > 500 * 1024 * 1024) { // Plus de 500MB
        logPerformance('Memory Alert - High Memory Usage', metrics);
    }

    next();
};

// Middleware pour surveiller les erreurs de base de données
const dbErrorMonitor = (err, req, res, next) => {
    if (err.name === 'MongoError' || err.name === 'MongooseError') {
        logPerformance('Database Error', {
            error: err.message,
            code: err.code,
            operation: err.op
        });
    }
    next(err);
};

// Middleware pour surveiller les requêtes en cours
let currentRequests = 0;
const requestMonitor = (req, res, next) => {
    currentRequests++;

    // Alerter si trop de requêtes simultanées
    if (currentRequests > 100) {
        logPerformance('High Concurrent Requests', currentRequests);
    }

    res.on('finish', () => {
        currentRequests--;
    });

    next();
};

// Middleware pour surveiller les erreurs 404
const notFoundMonitor = (req, res, next) => {
    res.on('finish', () => {
        if (res.statusCode === 404) {
            logPerformance('404 Not Found', {
                path: req.originalUrl,
                method: req.method,
                ip: req.ip
            });
        }
    });
    next();
};

// Middleware pour surveiller les erreurs 500
const serverErrorMonitor = (err, req, res, next) => {
    if (res.statusCode >= 500) {
        logPerformance('Server Error', {
            error: err.message,
            path: req.originalUrl,
            method: req.method,
            stack: err.stack
        });
    }
    next(err);
};

// Collecter des métriques périodiques
setInterval(() => {
    const metrics = {
        uptime: process.uptime(),
        timestamp: Date.now(),
        activeRequests: currentRequests,
        memory: process.memoryUsage(),
        cpu: process.cpuUsage()
    };

    logPerformance('System Metrics', metrics);
}, 300000); // Toutes les 5 minutes

module.exports = {
    performanceMonitor,
    memoryMonitor,
    dbErrorMonitor,
    requestMonitor,
    notFoundMonitor,
    serverErrorMonitor
};
