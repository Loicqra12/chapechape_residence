const express = require('express');
const { protect } = require('../middlewares/auth.middleware');
const {
    registerDevice,
    unregisterDevice,
    updateNotificationPreferences,
    getNotificationPreferences
} = require('../controllers/device.controller');

const router = express.Router();

// Protection des routes
router.use(protect);

// Routes de gestion des appareils et des préférences de notification
router.post('/register', registerDevice);
router.delete('/unregister', unregisterDevice);
router.put('/preferences', updateNotificationPreferences);
router.get('/preferences', getNotificationPreferences);

module.exports = router;
