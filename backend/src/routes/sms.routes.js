const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/auth.middleware');
const smsController = require('../controllers/sms.controller');

// Protection des routes - authentification requise
router.use(protect);

// Routes pour l'envoi de SMS (réservées aux partenaires et administrateurs)
router.route('/send')
    .post(authorize('admin', 'partenaire'), smsController.sendSMS);

// Route pour envoyer des notifications SMS liées aux réservations
router.route('/booking')
    .post(authorize('admin', 'partenaire'), smsController.sendBookingNotification);

// Route pour envoyer des instructions de paiement spécifiques à l'Afrique
router.route('/payment-instructions')
    .post(authorize('admin', 'partenaire'), smsController.sendPaymentInstructions);

module.exports = router;
