const mongoose = require('mongoose');
const healthService = require('../services/health.service');
const logger = require('../utils/logger');
const readiness = require('../runtime/readiness');
const { fingerprintFromUri } = require('../utils/mongo-fingerprint');
const { EXPECTED_PROD_MONGO_FINGERPRINT } = require('../runtime/prod-constants');
const { workerLabel } = require('../runtime/agenda-cluster');

let cachedTransactions = null;

async function transactionsStatus() {
    if (mongoose.connection.readyState !== 1) {
        return 'unavailable';
    }
    if (cachedTransactions) return cachedTransactions;
    try {
        const hello = await mongoose.connection.db.admin().command({ hello: 1 });
        cachedTransactions = (hello.setName || hello.msg === 'isdbgrid')
            ? 'available'
            : 'unavailable';
    } catch (err) {
        cachedTransactions = 'unavailable';
    }
    return cachedTransactions;
}

function mongoFingerprintSafe() {
    try {
        return fingerprintFromUri(process.env.MONGODB_URI);
    } catch (err) {
        return null;
    }
}

function runtimePublic() {
    const fp = mongoFingerprintSafe();
    return {
        node: process.version,
        env: process.env.NODE_ENV || 'development',
        port: process.env.PORT || null,
        gitCommit: process.env.GIT_COMMIT || null,
        worker: workerLabel(),
        uptimeSec: Math.round(process.uptime()),
        mongoFingerprint: fp ? fp.fingerprint : null,
        mongoFingerprintExpected: EXPECTED_PROD_MONGO_FINGERPRINT,
        mongoFingerprintMatch: fp ? fp.fingerprint === EXPECTED_PROD_MONGO_FINGERPRINT : false,
    };
}

exports.getLiveness = (req, res) => {
    res.status(200).json({
        success: true,
        status: 'alive',
        message: 'Server is running',
        timestamp: new Date().toISOString(),
    });
};

exports.getReadiness = async (req, res) => {
    const mongoOk = mongoose.connection.readyState === 1;
    const tx = mongoOk ? await transactionsStatus() : 'unavailable';
    const redisRequired = process.env.REDIS_REQUIRED === 'true';
    let redisOk = !redisRequired;
    if (redisRequired) {
        try {
            const redis = require('../config/redis');
            const pong = await redis.getClient().ping();
            redisOk = pong === 'PONG' || pong === 'pong' || pong === true;
        } catch (err) {
            redisOk = false;
        }
    }
    const agendaRequired = process.env.DISABLE_AGENDA !== 'true';
    const agendaOk = !agendaRequired || readiness.isAgendaStarted();
    const ready = readiness.isReady() && mongoOk && redisOk && agendaOk && tx === 'available';
    const body = {
        success: ready,
        status: ready ? 'ready' : 'not_ready',
        timestamp: new Date().toISOString(),
        shuttingDown: readiness.isShuttingDown(),
        checks: {
            process: readiness.isReady(),
            mongo: mongoOk ? 'connected' : 'disconnected',
            transactions: tx,
            redis: redisRequired ? (redisOk ? 'ok' : 'down') : 'not_required',
            agenda: agendaRequired ? (agendaOk ? 'started' : 'not_started') : 'disabled',
        },
        runtime: runtimePublic(),
    };
    res.status(ready ? 200 : 503).json(body);
};

exports.getGeneralHealth = async (req, res) => {
    try {
        const connected = mongoose.connection.readyState === 1;
        const fp = mongoFingerprintSafe();
        res.status(200).json({
            success: true,
            message: 'Server is running',
            timestamp: new Date().toISOString(),
            database: connected ? 'connected' : 'disconnected',
            transactions: await transactionsStatus(),
            environment: process.env.NODE_ENV || 'development',
            mongoFingerprint: fp ? fp.fingerprint : null,
            gitCommit: process.env.GIT_COMMIT || null,
            worker: workerLabel(),
            uptimeSec: Math.round(process.uptime()),
            socketCrossWorker: (() => {
                try {
                    return require('../services/socket.service').isCrossWorkerEnabled();
                } catch (err) {
                    return false;
                }
            })(),
        });
    } catch (error) {
        logger.error('Erreur lors du health check général:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            timestamp: new Date().toISOString(),
        });
    }
};

/**
 * Route health check pour les services de paiement
 */
exports.getPaymentServicesHealth = async (req, res) => {
    try {
        const healthResults = await healthService.checkPaymentSystemHealth();
        
        // Déterminer le code de statut HTTP en fonction du statut global
        let statusCode = 200; // OK par défaut
        if (healthResults.status === 'down') {
            statusCode = 503; // Service Unavailable
        } else if (healthResults.status === 'degraded') {
            statusCode = 207; // Multi-Status
        }
        
        res.status(statusCode).json({
            success: true,
            ...healthResults
        });
    } catch (error) {
        logger.error('Erreur lors du health check des services de paiement:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la vérification des services de paiement',
            error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error',
            timestamp: new Date().toISOString()
        });
    }
};

/**
 * Route health check pour le service payment timer
 */
exports.getPaymentTimerHealth = async (req, res) => {
    try {
        const timerHealth = await healthService.checkPaymentTimerHealth();
        
        // Déterminer le code de statut HTTP
        let statusCode = 200; // OK par défaut
        if (timerHealth.status === 'down') {
            statusCode = 503; // Service Unavailable
        } else if (timerHealth.status === 'unconfigured') {
            statusCode = 409; // Conflict - service existe mais mal configuré
        } else if (timerHealth.status === 'error') {
            statusCode = 500; // Internal Server Error
        }
        
        res.status(statusCode).json({
            success: true,
            ...timerHealth
        });
    } catch (error) {
        logger.error('Erreur lors du health check du payment timer:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la vérification du payment timer',
            error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error',
            timestamp: new Date().toISOString()
        });
    }
};
