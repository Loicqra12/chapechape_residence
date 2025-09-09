const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');
const paymentValidation = require('../validations/payment.validation');
const paymentController = require('../controllers/payment/payment.controller');

// Routes protégées (nécessitent une authentification)
router.post('/create-payment-intent', protect, validate(paymentValidation.createPaymentIntent), paymentController.createPaymentIntent);
router.post('/:paymentId/confirm', protect, validate(paymentValidation.confirmPayment), paymentController.confirmPayment);
router.get('/my-payments', protect, validate(paymentValidation.getUserPayments), paymentController.getUserPayments);

// Vérifier le statut d'un paiement CinetPay en temps réel
router.get('/cinetpay/verify/:transactionId', protect, paymentController.verifyCinetPayPayment);
router.post('/:paymentId/refund', protect, validate(paymentValidation.requestRefund), paymentController.requestRefund);

// Webhook Stripe (pas de protection car appelé par Stripe)
router.post('/webhook', express.raw({ type: 'application/json' }), paymentController.handleStripeWebhook);

// Webhook CinetPay (pas de protection car appelé par CinetPay)
router.post('/cinetpay/webhook', express.urlencoded({ extended: true }), paymentController.handleCinetPayWebhook);

// Webhook Wave (pas de protection car appelé par Wave)
// Utilisation de express.raw() pour accéder au corps brut pour vérification HMAC
router.post('/wave/webhook', express.raw({ type: 'application/json' }), paymentController.handleWaveWebhook);


module.exports = router;
