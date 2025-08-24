const healthService = require('../services/health.service');
const logger = require('../utils/logger');

/**
 * Contrôleur pour les endpoints de health checks
 */

/**
 * Route health check générale
 */
exports.getGeneralHealth = async (req, res) => {
    try {
        const dbStatus = req.app.locals.dbConnection ? 'connected' : 'disconnected';
        
        res.status(200).json({
            success: true,
            message: "Server is running",
            timestamp: new Date().toISOString(),
            database: dbStatus,
            environment: process.env.NODE_ENV || 'development'
        });
    } catch (error) {
        logger.error('Erreur lors du health check général:', error);
        res.status(500).json({ 
            success: false, 
            message: 'Internal server error', 
            timestamp: new Date().toISOString() 
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
