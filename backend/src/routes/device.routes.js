const express = require('express');
const { protect } = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');
const {
    registerDevice,
    unregisterDevice,
    updateNotificationPreferences,
    getNotificationPreferences
} = require('../controllers/device.controller');
const {
    registerDevice: registerDeviceValidation,
    unregisterDevice: unregisterDeviceValidation,
    updateNotificationPreferences: notificationPreferencesValidation
} = require('../validations/device.validation');

const router = express.Router();

// Protection des routes
router.use(protect);

// Routes de gestion des appareils et des préférences de notification
router.post('/register', validate(registerDeviceValidation), registerDevice);
router.delete('/unregister', validate(unregisterDeviceValidation), unregisterDevice);
router.put('/preferences', validate(notificationPreferencesValidation), updateNotificationPreferences);
router.get('/preferences', getNotificationPreferences);

module.exports = router;
