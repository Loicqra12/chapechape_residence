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

// Vérification rapide du statut par transactionId (lookup direct — PROB #7 fix)
router.get('/status/:transactionId', protect, paymentController.getPaymentStatus);

// Vérifier le statut d'un paiement CinetPay en temps réel
router.get('/cinetpay/verify/:transactionId', protect, paymentController.verifyCinetPayPayment);
router.post('/:paymentId/refund', protect, validate(paymentValidation.requestRefund), paymentController.requestRefund);

// Webhook Stripe + Wave + CinetPay paiement : montés dans app.js (hors paymentLimiter)

module.exports = router;
