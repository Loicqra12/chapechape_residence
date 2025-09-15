const express = require('express');
const router = express.Router();
const { protect, restrictTo } = require('../middlewares/auth.middleware');
const countryController = require('../controllers/country-management.controller');

// Routes publiques
// @desc    Obtenir tous les pays supportés
// @route   GET /api/countries
// @access  Public
router.get('/', countryController.getAllCountries);

// @desc    Obtenir la configuration d'un pays
// @route   GET /api/countries/:countryCode
// @access  Public
router.get('/:countryCode', countryController.getCountryConfig);

// @desc    Détecter le pays depuis un numéro
// @route   POST /api/countries/detect
// @access  Public
router.post('/detect', countryController.detectCountryFromPhone);

// @desc    Vérifier le support d'une fonctionnalité
// @route   GET /api/countries/:countryCode/support/:feature
// @access  Public
router.get('/:countryCode/support/:feature', countryController.checkCountrySupport);

// @desc    Obtenir les pays par phase
// @route   GET /api/countries/phases/:phase
// @access  Public
router.get('/phases/:phase', countryController.getCountriesByPhase);

// @desc    Obtenir les opérateurs d'un pays
// @route   GET /api/countries/:countryCode/operators
// @access  Public
router.get('/:countryCode/operators', countryController.getCountryOperators);

// Routes protégées
// @desc    Obtenir les réglementations d'un pays
// @route   GET /api/countries/:countryCode/regulations
// @access  Private
router.get('/:countryCode/regulations', 
    protect, 
    countryController.getCountryRegulations
);

// Routes admin uniquement
// @desc    Proposer une expansion
// @route   POST /api/countries/propose-expansion
// @access  Private (Admin)
router.post('/propose-expansion', 
    protect, 
    restrictTo('admin', 'superadmin'),
    countryController.proposeExpansion
);

// @desc    Statistiques globales des pays
// @route   GET /api/countries/stats
// @access  Private (Admin)
router.get('/stats', 
    protect, 
    restrictTo('admin', 'superadmin'),
    countryController.getCountriesStats
);

module.exports = router;
