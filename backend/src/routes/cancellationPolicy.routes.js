const express = require('express');
const router = express.Router();
const cancellationPolicyController = require('../controllers/cancellationPolicy.controller');
const { protect, authorize } = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');
const { cancellationPolicyValidation } = require('../validations');

// Routes publiques
router.get(
  '/',
  validate(cancellationPolicyValidation.getCancellationPolicies),
  cancellationPolicyController.getCancellationPolicies
);

router.get(
  '/:id',
  validate(cancellationPolicyValidation.getCancellationPolicy),
  cancellationPolicyController.getCancellationPolicy
);

router.post(
  '/:id/calculate-refund',
  validate(cancellationPolicyValidation.calculateRefund),
  cancellationPolicyController.calculateRefund
);

router.post(
  '/:id/check-modification',
  validate(cancellationPolicyValidation.checkModification),
  cancellationPolicyController.checkModification
);

// Routes protégées (admin uniquement)
router.use(protect);
router.use(authorize('admin'));

router.post(
  '/',
  validate(cancellationPolicyValidation.createCancellationPolicy),
  cancellationPolicyController.createCancellationPolicy
);

router.put(
  '/:id',
  validate(cancellationPolicyValidation.updateCancellationPolicy),
  cancellationPolicyController.updateCancellationPolicy
);

router.delete(
  '/:id',
  validate(cancellationPolicyValidation.deleteCancellationPolicy),
  cancellationPolicyController.deleteCancellationPolicy
);

module.exports = router;
