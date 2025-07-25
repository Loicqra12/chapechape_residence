const express = require('express');
const router = express.Router();
const availabilityController = require('../controllers/availability.controller');
const { protect, authorize } = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');
const availabilityValidation = require('../validations/availability.validation');

// Routes publiques - ACCESSIBLE À TOUS LES UTILISATEURS
// IMPORTANT : Ces routes doivent être déclarées AVANT les middlewares protect & authorize

// Route existante pour la vérification de disponibilité
router.get(
  '/check',
  validate(availabilityValidation.checkAvailability),
  availabilityController.checkAvailability
);

// Nouvel endpoint public dédié pour l'application mobile Flutter - SANS AUTHENTIFICATION REQUISE
router.get(
  '/flutter-check',
  validate(availabilityValidation.checkFlutterAvailability),
  availabilityController.checkAvailabilityForFlutterApp
);

// Calendrier de disponibilité (public)
router.get(
  '/calendar',
  validate(availabilityValidation.getAvailabilityCalendar),
  availabilityController.getAvailabilityCalendar
);

// Routes protégées (propriétaire de résidence uniquement)
router.use(protect);
router.use(authorize('partner', 'admin'));

router.put(
  '/block',
  validate(availabilityValidation.blockDates),
  availabilityController.blockDates
);

router.put(
  '/unblock',
  validate(availabilityValidation.unblockDates),
  availabilityController.unblockDates
);

router.put(
  '/pricing',
  validate(availabilityValidation.updatePricing),
  availabilityController.updatePricing
);

module.exports = router;