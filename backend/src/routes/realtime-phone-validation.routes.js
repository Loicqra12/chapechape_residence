const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
const realtimeValidationController = require('../controllers/realtime-phone-validation.controller');

// @desc    Validation rapide de format (public avec rate limit)
// @route   POST /api/phone/validate/quick
// @access  Private
router.post('/quick', 
    protect,
    realtimeValidationController.quickValidatePhone
);

// @desc    Validation complète pour paiement
// @route   POST /api/phone/validate/payment
// @access  Private (Partner uniquement)
router.post('/payment',
    protect,
    realtimeValidationController.validateForPayment
);

// @desc    Validation en lot
// @route   POST /api/phone/validate/batch
// @access  Private
router.post('/batch',
    protect,
    realtimeValidationController.batchValidatePhones
);

// @desc    Obtenir les opérateurs supportés par pays
// @route   GET /api/phone/operators/:country
// @access  Public
router.get('/operators/:country',
    realtimeValidationController.getSupportedOperators
);

// @desc    Statistiques de validation
// @route   GET /api/phone/validate/stats
// @access  Private
router.get('/stats',
    protect,
    realtimeValidationController.getValidationStats
);

// @desc    Health check de l'API
// @route   GET /api/phone/validate/health
// @access  Public
router.get('/health',
    realtimeValidationController.healthCheck
);

module.exports = router;
