const express = require('express');
const { sendTestEmail, sendTemplateTest } = require('../controllers/test/email.test.controller');
const notificationTestController = require('../controllers/test/notification-test.controller');
// Importer le middleware d'authentification mais ne pas l'utiliser pour les tests
// const { authenticate } = require('../middlewares/auth.middleware');

const router = express.Router();

/**
 * Routes de test uniquement disponibles en environnement de développement
 * Ces routes sont intentionnellement non protégées pour faciliter les tests
 */

// Aucune authentification requise pour les routes de test
router.post('/email/send', sendTestEmail);
router.post('/email/template', sendTemplateTest);

// Routes de test pour les notifications - NE PAS UTILISER EN PRODUCTION
router.post('/notification/simple', notificationTestController.testSimpleNotification);
router.post('/notification/all', notificationTestController.testAllDevicesNotification);
router.post('/notification/segment', notificationTestController.testSegmentNotification);

module.exports = router;
