const availabilityService = require('../services/availability.service');
const partnerBlockService = require('../services/partner-block.service');
const externalReservationService = require('../services/external-reservation.service');
const calendarProjection = require('../services/calendar-projection.service');
const ApiError = require('../utils/apiError');
const asyncHandler = require('../middlewares/async.middleware');
const Residence = require('../models/residence.model');
const Availability = require('../models/availability.model');
const { canManageResidence } = require('../security/resource-access');

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
    data: {
      isAvailable: typeof isAvailable?.available === 'boolean' ? isAvailable.available : isAvailable,
      conflictDates: isAvailable?.unavailableDates || isAvailable?.blockedDates || [],
    }
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

  const calendar = await calendarProjection.getPublicCalendar(
    residenceId,
    startDate,
    endDate
  );

  res.status(200).json({
    success: true,
    data: calendar
  });
});

exports.getPartnerCalendar = asyncHandler(async (req, res) => {
  const { residenceId, startDate, endDate } = req.query;
  if (!residenceId || !startDate || !endDate) {
    throw new ApiError('Veuillez fournir residenceId, startDate et endDate', 400);
  }
  const calendar = await calendarProjection.getPartnerCalendar(
    req.user,
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
  const { residenceId, startDate, endDate, reason, bookingType, type } = req.body;

  if (!residenceId || !startDate || !endDate) {
    throw new ApiError('Veuillez fournir residenceId, startDate et endDate', 400);
  }

  const blocked = await partnerBlockService.createBlock(req.user, {
    residenceId,
    startDate,
    endDate,
    reason,
    bookingType,
    type,
  });

  res.status(200).json({
    success: true,
    data: blocked
  });
});

exports.unblockDates = asyncHandler(async (req, res) => {
  const { residenceId, startDate, endDate, blockId } = req.body;

  if (blockId) {
    const released = await partnerBlockService.releaseBlock(req.user, blockId);
    return res.status(200).json({ success: true, data: released });
  }

  if (!residenceId || !startDate || !endDate) {
    throw new ApiError('Veuillez fournir residenceId, startDate et endDate, ou blockId', 400);
  }

  const unblocked = await partnerBlockService.unblockRange(req.user, {
    residenceId,
    startDate,
    endDate,
  });

  res.status(200).json({
    success: true,
    data: unblocked
  });
});

exports.createBlock = asyncHandler(async (req, res) => {
  const block = await partnerBlockService.createBlock(req.user, req.body);
  res.status(201).json({ success: true, data: block });
});

exports.listBlocks = asyncHandler(async (req, res) => {
  const { residenceId, status } = req.query;
  if (!residenceId) {
    throw new ApiError('residenceId requis', 400);
  }
  const blocks = await partnerBlockService.listBlocks(req.user, { residenceId, status });
  res.status(200).json({ success: true, data: blocks });
});

exports.deleteBlock = asyncHandler(async (req, res) => {
  const released = await partnerBlockService.releaseBlock(req.user, req.params.id);
  res.status(200).json({ success: true, data: released });
});

exports.createExternal = asyncHandler(async (req, res) => {
  const external = await externalReservationService.createExternalReservation(req.user, req.body);
  res.status(201).json({
    success: true,
    data: externalReservationService.toPartnerView(external),
  });
});

exports.listExternal = asyncHandler(async (req, res) => {
  const { residenceId, status } = req.query;
  if (!residenceId) {
    throw new ApiError('residenceId requis', 400);
  }
  const items = await externalReservationService.listExternalReservations(req.user, { residenceId, status });
  res.status(200).json({
    success: true,
    data: items.map((item) => externalReservationService.toPartnerView(item)),
  });
});

exports.getExternal = asyncHandler(async (req, res) => {
  const external = await externalReservationService.getExternalReservation(req.user, req.params.id);
  res.status(200).json({
    success: true,
    data: externalReservationService.toPartnerView(external),
  });
});

exports.updateExternal = asyncHandler(async (req, res) => {
  const external = await externalReservationService.modifyExternalReservation(
    req.user,
    req.params.id,
    req.body
  );
  res.status(200).json({
    success: true,
    data: externalReservationService.toPartnerView(external),
  });
});

exports.deleteExternal = asyncHandler(async (req, res) => {
  const cancelled = await externalReservationService.cancelExternalReservation(req.user, req.params.id);
  res.status(200).json({
    success: true,
    data: externalReservationService.toPartnerView(cancelled),
  });
});

exports.completeExternal = asyncHandler(async (req, res) => {
  const completed = await externalReservationService.completeExternalReservation(req.user, req.params.id);
  res.status(200).json({
    success: true,
    data: externalReservationService.toPartnerView(completed),
  });
});

/**
 * Mettre à jour le prix pour une date spécifique
 * @route PUT /residences/:residenceId/availability/pricing
 */
exports.updatePricing = asyncHandler(async (req, res) => {
  const { residenceId, date, price } = req.body;
  const numericPrice = Number(price);

  if (!residenceId || !date || price === undefined) {
    throw new ApiError('Veuillez fournir residenceId, date et price', 400);
  }
  if (!Number.isFinite(numericPrice) || numericPrice < 0) {
    throw new ApiError('Prix invalide', 400);
  }

  const residence = await Residence.findById(residenceId).select('partner');
  if (!residence) {
    throw new ApiError('Résidence introuvable', 404);
  }
  if (!canManageResidence(residence, req.user)) {
    throw new ApiError('Non autorisé à modifier le tarif de cette résidence', 403);
  }

  const day = new Date(date);
  if (Number.isNaN(day.getTime())) {
    throw new ApiError('Date invalide', 400);
  }
  day.setUTCHours(0, 0, 0, 0);

  const updated = await Availability.findOneAndUpdate(
    { residenceId, date: day },
    { $set: { price: numericPrice } },
    { new: true, projection: { price: 1, date: 1, residenceId: 1, status: 1 } }
  );

  if (!updated) {
    throw new ApiError('Aucune disponibilité pour cette date', 404);
  }

  res.status(200).json({
    success: true,
    data: updated
  });
});

/**
 * Nouvel endpoint spécifique pour la vérification de disponibilité avec format harmonisé
 * pour correspondre à l'application client Flutter
 * @route GET /availability/check
 */
exports.checkAvailabilityForFlutterApp = asyncHandler(async (req, res) => {
  const { residenceId, checkIn, checkOut } = req.query;

  if (!residenceId || !checkIn || !checkOut) {
    throw new ApiError('Veuillez fournir residenceId, checkIn et checkOut', 400);
  }

  const startDate = new Date(checkIn);
  const endDate = new Date(checkOut);
  if (Number.isNaN(startDate.getTime()) || Number.isNaN(endDate.getTime())) {
    throw new ApiError('Dates invalides', 400);
  }
  if (startDate >= endDate) {
    throw new ApiError('La date de départ doit être ultérieure à la date d\'arrivée', 400);
  }

  const residence = await Residence.findById(residenceId);
  if (!residence) {
    throw new ApiError('Résidence introuvable', 404);
  }

  const occupancy = await calendarProjection.checkPublicAvailability(
    residenceId,
    startDate,
    endDate
  );
  const price = await residence.calculateTotalPrice(startDate, endDate);

  res.status(200).json({
    success: true,
    data: {
      isAvailable: occupancy.available,
      price,
      conflictDates: occupancy.occupations.map((occ) => ({
        start: occ.start,
        end: occ.end,
      })),
      residenceId,
      message: occupancy.available
        ? 'La résidence est disponible pour ces dates'
        : 'La résidence n\'est pas disponible pour ces dates',
    },
  });
});