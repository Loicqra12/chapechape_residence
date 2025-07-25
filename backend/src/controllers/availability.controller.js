const availabilityService = require('../services/availability.service');
const ApiError = require('../utils/apiError');
const asyncHandler = require('../middlewares/async.middleware');
const Availability = require('../models/availability.model');
const Residence = require('../models/residence.model');

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

/**
 * Nouvel endpoint spécifique pour la vérification de disponibilité avec format harmonisé
 * pour correspondre à l'application client Flutter
 * @route GET /availability/check
 */
exports.checkAvailabilityForFlutterApp = asyncHandler(async (req, res) => {
  const { residenceId, checkIn, checkOut } = req.query;
  
  // Validation des paramètres
  if (!residenceId || !checkIn || !checkOut) {
    throw new ApiError('Veuillez fournir residenceId, checkIn et checkOut', 400);
  }

  console.log(`[Availability] Vérification pour résidence: ${residenceId}, dates: ${checkIn} -> ${checkOut}`);
  
  try {
    // Convertir les dates en objets Date
    const startDate = new Date(checkIn);
    const endDate = new Date(checkOut);
    
    // Vérifier si les dates sont valides
    if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
      throw new ApiError('Dates invalides', 400);
    }
    
    if (startDate >= endDate) {
      throw new ApiError('La date de départ doit être ultérieure à la date d\'arrivée', 400);
    }

    // Récupérer la résidence
    const residence = await Residence.findById(residenceId);
    if (!residence) {
      throw new ApiError('Résidence introuvable', 404);
    }
    
    // IMPORTANT: Utiliser la méthode isPeriodAvailable du modèle Availability
    // C'est la même méthode que celle utilisée lors de la création de réservation
    // Note: isPeriodAvailable retourne directement un booléen, pas un objet
    const isAvailable = await Availability.isPeriodAvailable(residenceId, startDate, endDate);
    
    console.log(`[Availability] Résultat: ${isAvailable ? 'Disponible' : 'Non disponible'}`);
    
    // Si la période n'est pas disponible, nous pourrions récupérer les dates en conflit
    // Mais puisque isPeriodAvailable ne retourne pas cette information, nous laissons un tableau vide
    let conflictDates = [];
    
    // Si nécessaire, on pourrait faire une requête supplémentaire pour obtenir les dates bloquées
    if (!isAvailable) {
      // Note: Cette partie pourrait être améliorée en faisant une requête supplémentaire
      // pour obtenir les dates exactes qui sont en conflit
    }
    
    // Calculer le prix pour cette période
    const price = await residence.calculateTotalPrice(startDate, endDate);
    
    // Renvoyer la réponse au format attendu par le client Flutter
    res.status(200).json({
      success: true,
      data: {
        isAvailable: isAvailable,
        price: price,
        conflictDates: conflictDates,
        residenceId: residenceId,
        message: isAvailable 
          ? 'La résidence est disponible pour ces dates' 
          : 'La résidence n\'est pas disponible pour ces dates'
      }
    });
  } catch (error) {
    console.error(`[Availability] Erreur: ${error.message}`);
    if (error instanceof ApiError) throw error;
    throw new ApiError(`Erreur lors de la vérification de disponibilité: ${error.message}`, 500);
  }
});