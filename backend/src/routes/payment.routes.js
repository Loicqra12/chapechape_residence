const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
const paymentController = require('../controllers/payment/payment.controller');

// Routes protégées (nécessitent une authentification)
router.post('/create-payment-intent', protect, paymentController.createPaymentIntent);
router.post('/:paymentId/confirm', protect, paymentController.confirmPayment);
router.get('/my-payments', protect, paymentController.getUserPayments);
router.post('/:paymentId/refund', protect, paymentController.requestRefund);

// Webhook Stripe (pas de protection car appelé par Stripe)
router.post('/webhook', express.raw({ type: 'application/json' }), paymentController.handleStripeWebhook);

module.exports = router;
