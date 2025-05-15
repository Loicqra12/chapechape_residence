const express = require('express');
const router = express.Router();
const notificationTestController = require('../controllers/test/notification-test.controller');

// Routes de test pour les notifications - NE PAS UTILISER EN PRODUCTION
router.post('/simple', notificationTestController.testSimpleNotification);
router.post('/all', notificationTestController.testAllDevicesNotification);
router.post('/segment', notificationTestController.testSegmentNotification);

module.exports = router;
