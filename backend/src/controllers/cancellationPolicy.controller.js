const asyncHandler = require('../middlewares/async.middleware');
const { ApiError } = require('../utils/apiError');
const CancellationPolicy = require('../models/cancellationPolicy.model');
const Residence = require('../models/residence.model');

/**
 * Obtenir toutes les politiques d'annulation
 * @route GET /api/cancellation-policies
 * @access Public
 */
exports.getCancellationPolicies = asyncHandler(async (req, res) => {
  const policies = await CancellationPolicy.find()
    .sort({ isDefault: -1, name: 1 });

  res.status(200).json({
    success: true,
    data: policies
  });
});

/**
 * Obtenir une politique d'annulation par ID
 * @route GET /api/cancellation-policies/:id
 * @access Public
 */
exports.getCancellationPolicy = asyncHandler(async (req, res) => {
  const policy = await CancellationPolicy.findById(req.params.id);

  if (!policy) {
    throw new ApiError('Politique d\'annulation non trouvée', 404);
  }

  res.status(200).json({
    success: true,
    data: policy
  });
});

/**
 * Créer une nouvelle politique d'annulation
 * @route POST /api/cancellation-policies
 * @access Admin only
 */
exports.createCancellationPolicy = asyncHandler(async (req, res) => {
  const policy = await CancellationPolicy.create({
    ...req.body,
    createdBy: req.user._id
  });

  res.status(201).json({
    success: true,
    data: policy
  });
});

/**
 * Mettre à jour une politique d'annulation
 * @route PUT /api/cancellation-policies/:id
 * @access Admin only
 */
exports.updateCancellationPolicy = asyncHandler(async (req, res) => {
  const policy = await CancellationPolicy.findByIdAndUpdate(
    req.params.id,
    req.body,
    {
      new: true,
      runValidators: true
    }
  );

  if (!policy) {
    throw new ApiError('Politique d\'annulation non trouvée', 404);
  }

  res.status(200).json({
    success: true,
    data: policy
  });
});

/**
 * Supprimer une politique d'annulation
 * @route DELETE /api/cancellation-policies/:id
 * @access Admin only
 */
exports.deleteCancellationPolicy = asyncHandler(async (req, res) => {
  const policy = await CancellationPolicy.findById(req.params.id);

  if (!policy) {
    throw new ApiError('Politique d\'annulation non trouvée', 404);
  }

  // Vérifier si la politique est utilisée par des résidences
  const residencesUsingPolicy = await Residence.countDocuments({
    cancellationPolicy: req.params.id
  });

  if (residencesUsingPolicy > 0) {
    throw new ApiError(
      'Cette politique ne peut pas être supprimée car elle est utilisée par des résidences',
      400
    );
  }

  await policy.remove();

  res.status(200).json({
    success: true,
    data: {}
  });
});

/**
 * Calculer le montant de remboursement pour une réservation
 * @route POST /api/cancellation-policies/:id/calculate-refund
 * @access Public
 */
exports.calculateRefund = asyncHandler(async (req, res) => {
  const { reservationTotal, checkInDate } = req.body;
  const policy = await CancellationPolicy.findById(req.params.id);

  if (!policy) {
    throw new ApiError('Politique d\'annulation non trouvée', 404);
  }

  // Calculer le nombre d'heures avant le check-in
  const now = new Date();
  const checkIn = new Date(checkInDate);
  const hoursBeforeCheckIn = Math.max(0, (checkIn - now) / (1000 * 60 * 60));

  const refundAmount = policy.calculateRefund(reservationTotal, hoursBeforeCheckIn);

  res.status(200).json({
    success: true,
    data: {
      refundAmount,
      hoursBeforeCheckIn,
      policy: policy.name
    }
  });
});

/**
 * Vérifier si une modification est possible et calculer les frais
 * @route POST /api/cancellation-policies/:id/check-modification
 * @access Public
 */
exports.checkModification = asyncHandler(async (req, res) => {
  const { checkInDate, oldTotal, newTotal } = req.body;
  const policy = await CancellationPolicy.findById(req.params.id);

  if (!policy) {
    throw new ApiError('Politique d\'annulation non trouvée', 404);
  }

  // Calculer le nombre d'heures avant le check-in
  const now = new Date();
  const checkIn = new Date(checkInDate);
  const hoursBeforeCheckIn = Math.max(0, (checkIn - now) / (1000 * 60 * 60));

  const isAllowed = policy.isModificationAllowed(hoursBeforeCheckIn);
  const modificationFee = isAllowed ? policy.calculateModificationFee(newTotal, oldTotal) : null;

  res.status(200).json({
    success: true,
    data: {
      isAllowed,
      modificationFee,
      hoursBeforeCheckIn,
      policy: policy.name
    }
  });
});
