const asyncHandler = require('../../middlewares/async.middleware');
const oneSignalService = require('../../services/onesignal.service');
const notificationTypes = require('../../utils/notification-types');

/**
 * Test d'envoi de notification directement via OneSignal, sans authentification
 * Ce contrôleur est uniquement pour les tests et devrait être désactivé en production
 */

// @desc    Tester l'envoi d'une notification simple
// @route   POST /api/test/notification/simple
// @access  Public (uniquement pour les tests)
exports.testSimpleNotification = asyncHandler(async (req, res) => {
    const { playerId, title, message } = req.body;
    
    if (!playerId) {
        return res.status(400).json({
            success: false,
            message: 'Le playerId (ID de l\'appareil OneSignal) est requis'
        });
    }
    
    try {
        const result = await oneSignalService.sendToUser(
            playerId,
            title || 'Test ChapeChape',
            message || 'Ceci est un test de notification push',
            { testData: true, timestamp: new Date().toISOString() }
        );
        
        res.status(200).json({
            success: true,
            message: 'Notification envoyée avec succès',
            data: result,
            playerId
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'envoi de la notification',
            error: error.message
        });
    }
});

// @desc    Tester l'envoi d'une notification à tous les appareils
// @route   POST /api/test/notification/all
// @access  Public (uniquement pour les tests)
exports.testAllDevicesNotification = asyncHandler(async (req, res) => {
    const { title, message } = req.body;
    
    try {
        const result = await oneSignalService.sendToAll(
            title || 'Message pour tous',
            message || 'Cette notification est envoyée à tous les appareils',
            { broadcast: true, timestamp: new Date().toISOString() }
        );
        
        res.status(200).json({
            success: true,
            message: 'Notification envoyée à tous les appareils',
            data: result
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'envoi de la notification',
            error: error.message
        });
    }
});

// @desc    Tester les notifications par type (client ou partenaire)
// @route   POST /api/test/notification/segment
// @access  Public (uniquement pour les tests)
exports.testSegmentNotification = asyncHandler(async (req, res) => {
    const { segment, title, message } = req.body;
    
    if (!segment) {
        return res.status(400).json({
            success: false,
            message: 'Le segment est requis (ex: "client" ou "partner")'
        });
    }
    
    try {
        const result = await oneSignalService.sendToSegment(
            segment,
            title || `Test pour ${segment}`,
            message || `Ceci est un test pour le segment ${segment}`,
            { segmentTest: true, segment, timestamp: new Date().toISOString() }
        );
        
        res.status(200).json({
            success: true,
            message: `Notification envoyée au segment ${segment}`,
            data: result
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'envoi de la notification',
            error: error.message
        });
    }
});

module.exports = exports;
