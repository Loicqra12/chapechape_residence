const express = require('express');
const router = express.Router();
const availabilityController = require('../controllers/availability.controller');
const { protect, authorize } = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');
const availabilityValidation = require('../validations/availability.validation');

// Routes publiques
router.get(
  '/check',
  validate(availabilityValidation.checkAvailability),
  availabilityController.checkAvailability
);

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