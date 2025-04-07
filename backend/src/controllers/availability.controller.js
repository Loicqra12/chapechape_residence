const availabilityService = require('../services/availability.service');
const { ApiError } = require('../utils/apiError');
const asyncHandler = require('../middlewares/async.middleware');

/**
 * Vérifier la disponibilité d'une résidence pour des dates données
 * @route GET /residences/:residenceId/availability
 */
exports.checkAvailability = asyncHandler(async (req, res) => {
  const { residenceId, startDate, endDate } = req.query;
  
  if (!residenceId || !startDate || !endDate) {
    throw new ApiError('Veuillez fournir residenceId, startDate et endDate', 400);
  }

  const isAvailable = await availabilityService.checkAvailability(
    residenceId,
    startDate,
    endDate
  );

  res.status(200).json({
    success: true,
    data: { isAvailable }
  });
});

/**
 * Obtenir le calendrier de disponibilité d'une résidence pour une période
 * @route GET /residences/:residenceId/availability/calendar
 */
exports.getAvailabilityCalendar = asyncHandler(async (req, res) => {
  const { residenceId, startDate, endDate } = req.query;
  
  if (!residenceId || !startDate || !endDate) {
    throw new ApiError('Veuillez fournir residenceId, startDate et endDate', 400);
  }

  const calendar = await availabilityService.getAvailabilityCalendar(
    residenceId,
    startDate,
    endDate
  );

  res.status(200).json({
    success: true,
    data: calendar
  });
});

/**
 * Bloquer une plage de dates pour une résidence
 * @route PUT /residences/:residenceId/availability/block
 */
exports.blockDates = asyncHandler(async (req, res) => {
  const { residenceId, startDate, endDate, reason } = req.body;
  
  if (!residenceId || !startDate || !endDate) {
    throw new ApiError('Veuillez fournir residenceId, startDate et endDate', 400);
  }

  const blocked = await availabilityService.blockDates(
    residenceId,
    startDate,
    endDate,
    reason
  );

  res.status(200).json({
    success: true,
    data: blocked
  });
});

/**
 * Débloquer une plage de dates pour une résidence
 * @route PUT /residences/:residenceId/availability/unblock
 */
exports.unblockDates = asyncHandler(async (req, res) => {
  const { residenceId, startDate, endDate } = req.body;
  
  if (!residenceId || !startDate || !endDate) {
    throw new ApiError('Veuillez fournir residenceId, startDate et endDate', 400);
  }

  const unblocked = await availabilityService.unblockDates(
    residenceId,
    startDate,
    endDate
  );

  res.status(200).json({
    success: true,
    data: unblocked
  });
});

/**
 * Mettre à jour le prix pour une date spécifique
 * @route PUT /residences/:residenceId/availability/pricing
 */
exports.updatePricing = asyncHandler(async (req, res) => {
  const { residenceId, date, price } = req.body;
  
  if (!residenceId || !date || price === undefined) {
    throw new ApiError('Veuillez fournir residenceId, date et price', 400);
  }

  const updated = await availabilityService.updatePricing(
    residenceId,
    date,
    price
  );

  res.status(200).json({
    success: true,
    data: updated
  });
});