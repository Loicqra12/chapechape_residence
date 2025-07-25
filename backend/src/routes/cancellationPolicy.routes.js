const express = require('express');
const router = express.Router();
const cancellationPolicyController = require('../controllers/cancellationPolicy.controller');
const { protect, authorize } = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');
// Validation temporairement désactivée car le module n'existe pas
// const { cancellationPolicyValidation } = require('../validations');

// Fonction de validation temporaire qui accepte tout
const tempValidation = () => (req, res, next) => next();

// Routes publiques
router.get(
  '/',
  validate(tempValidation()),
  cancellationPolicyController.getCancellationPolicies
);

router.get(
  '/:id',
  validate(tempValidation()),
  cancellationPolicyController.getCancellationPolicy
);

router.post(
  '/:id/calculate-refund',
  validate(tempValidation()),
  cancellationPolicyController.calculateRefund
);

router.post(
  '/:id/check-modification',
  validate(tempValidation()),
  cancellationPolicyController.checkModification
);

// Routes protégées (admin uniquement)
router.use(protect);
router.use(authorize('admin'));

router.post(
  '/',
  validate(tempValidation()),
  cancellationPolicyController.createCancellationPolicy
);

router.put(
  '/:id',
  validate(tempValidation()),
  cancellationPolicyController.updateCancellationPolicy
);

router.delete(
  '/:id',
  validate(tempValidation()),
  cancellationPolicyController.deleteCancellationPolicy
);

module.exports = router;
