const Promotion = require('../../models/promotion.model');
const Residence = require('../../models/residence.model');
const ErrorResponse = require('../../utils/errorResponse');
const asyncHandler = require('../../middlewares/async.middleware');
const mongoose = require('mongoose');
const { cacheService } = require('../../services/cache.service');

// @desc    Créer une nouvelle promotion
// @route   POST /api/promotions
// @access  Private (Admin/Partner)
exports.createPromotion = asyncHandler(async (req, res, next) => {
  // Si l'utilisateur est un partenaire, vérifier qu'il est propriétaire de la résidence
  if (req.user.role === 'partner') {
    const residence = await Residence.findById(req.body.residenceId);
    
    if (!residence) {
      return next(new ErrorResponse(`Résidence non trouvée avec l'id ${req.body.residenceId}`, 404));
    }
    
    // Vérifier que le partenaire est bien le propriétaire de la résidence
    if (residence.partner.toString() !== req.user.id) {
      return next(new ErrorResponse(`Vous n'êtes pas autorisé à créer une promotion pour cette résidence`, 403));
    }
  }
  
  // Ajouter les champs de création
  req.body.createdBy = req.user.id;
  req.body.updatedBy = req.user.id;
  
  const promotion = await Promotion.create(req.body);
  
  // Invalider le cache pour les promotions
  await cacheService.invalidatePattern('promotions_*');
  
  res.status(201).json({
    success: true,
    data: promotion
  });
});

// @desc    Récupérer toutes les promotions
// @route   GET /api/promotions
// @access  Public
exports.getPromotions = asyncHandler(async (req, res, next) => {
  // Récupérer du cache si disponible
  const cacheKey = 'promotions_all';
  const cached = await cacheService.get(cacheKey);
  
  if (cached) {
    return res.status(200).json({
      success: true,
      count: cached.length,
      data: cached
    });
  }
  
  // Construire la requête
  let query = Promotion.find({});
  
  // Filtrage par type si spécifié
  if (req.query.type) {
    query = query.find({ type: req.query.type });
  }
  
  // Filtrage par exclusivité si spécifié
  if (req.query.exclusive) {
    query = query.find({ isExclusive: req.query.exclusive === 'true' });
  }
  
  // Filtrage par résidence si spécifié
  if (req.query.residence) {
    query = query.find({ residenceId: req.query.residence });
  }
  
  // Filtrage par dates actives
  if (req.query.active === 'true') {
    const now = new Date();
    query = query.find({
      startDate: { $lte: now },
      endDate: { $gte: now },
      isActive: true
    });
  }
  
  // Tri
  if (req.query.sort) {
    const sortBy = req.query.sort.split(',').join(' ');
    query = query.sort(sortBy);
  } else {
    query = query.sort('-createdAt');
  }
  
  // Pagination
  const page = parseInt(req.query.page, 10) || 1;
  const limit = parseInt(req.query.limit, 10) || 10;
  const startIndex = (page - 1) * limit;
  const endIndex = page * limit;
  const total = await Promotion.countDocuments(query);
  
  query = query.skip(startIndex).limit(limit);
  
  // Exécuter la requête
  const promotions = await query;
  
  // Mettre en cache pour 15 minutes
  await cacheService.set(cacheKey, promotions, 900);
  
  // Pagination result
  const pagination = {};
  
  if (endIndex < total) {
    pagination.next = {
      page: page + 1,
      limit
    };
  }
  
  if (startIndex > 0) {
    pagination.prev = {
      page: page - 1,
      limit
    };
  }
  
  res.status(200).json({
    success: true,
    count: promotions.length,
    pagination,
    data: promotions
  });
});

// @desc    Récupérer les promotions actives
// @route   GET /api/promotions/active
// @access  Public
exports.getActivePromotions = asyncHandler(async (req, res, next) => {
  // Récupérer du cache si disponible
  const cacheKey = 'promotions_active';
  const cached = await cacheService.get(cacheKey);
  
  if (cached) {
    return res.status(200).json({
      success: true,
      count: cached.length,
      data: cached
    });
  }
  
  const now = new Date();
  
  // Construire la requête pour les promotions actives
  const promotions = await Promotion.find({
    startDate: { $lte: now },
    endDate: { $gte: now },
    isActive: true
  }).sort({ endDate: 1 }); // Trier par date de fin la plus proche
  
  // Mettre en cache pour 15 minutes
  await cacheService.set(cacheKey, promotions, 900);
  
  res.status(200).json({
    success: true,
    count: promotions.length,
    data: promotions
  });
});

// @desc    Récupérer les promotions exclusives
// @route   GET /api/promotions/exclusive
// @access  Public
exports.getExclusivePromotions = asyncHandler(async (req, res, next) => {
  // Récupérer du cache si disponible
  const cacheKey = 'promotions_exclusive';
  const cached = await cacheService.get(cacheKey);
  
  if (cached) {
    return res.status(200).json({
      success: true,
      count: cached.length,
      data: cached
    });
  }
  
  const now = new Date();
  
  // Construire la requête pour les promotions exclusives actives
  const promotions = await Promotion.find({
    isExclusive: true,
    startDate: { $lte: now },
    endDate: { $gte: now },
    isActive: true
  }).sort('-discountPercentage'); // Trier par pourcentage de réduction le plus élevé
  
  // Mettre en cache pour 30 minutes
  await cacheService.set(cacheKey, promotions, 1800);
  
  res.status(200).json({
    success: true,
    count: promotions.length,
    data: promotions
  });
});

// @desc    Récupérer les promotions d'une résidence
// @route   GET /api/promotions/residence/:id
// @access  Public
exports.getResidencePromotions = asyncHandler(async (req, res, next) => {
  const residenceId = req.params.id;
  
  // Récupérer du cache si disponible
  const cacheKey = `promotions_residence_${residenceId}`;
  const cached = await cacheService.get(cacheKey);
  
  if (cached) {
    return res.status(200).json({
      success: true,
      count: cached.length,
      data: cached
    });
  }
  
  // Vérifier que la résidence existe
  const residence = await Residence.findById(residenceId);
  
  if (!residence) {
    return next(new ErrorResponse(`Résidence non trouvée avec l'id ${residenceId}`, 404));
  }
  
  const now = new Date();
  
  // Construire la requête pour les promotions de la résidence
  const promotions = await Promotion.find({
    residenceId: residenceId,
    startDate: { $lte: now },
    endDate: { $gte: now },
    isActive: true
  });
  
  // Mettre en cache pour 30 minutes
  await cacheService.set(cacheKey, promotions, 1800);
  
  res.status(200).json({
    success: true,
    count: promotions.length,
    data: promotions
  });
});

// @desc    Récupérer une promotion par son ID
// @route   GET /api/promotions/:id
// @access  Public
exports.getPromotion = asyncHandler(async (req, res, next) => {
  const promotionId = req.params.id;
  
  // Récupérer du cache si disponible
  const cacheKey = `promotion_details_${promotionId}`;
  const cached = await cacheService.get(cacheKey);
  
  if (cached) {
    return res.status(200).json({
      success: true,
      data: cached
    });
  }
  
  const promotion = await Promotion.findById(promotionId);
  
  if (!promotion) {
    return next(new ErrorResponse(`Promotion non trouvée avec l'id ${promotionId}`, 404));
  }
  
  // Récupérer la résidence associée
  let enrichedPromotion = promotion.toObject();
  
  if (promotion.residenceId) {
    const residence = await Residence.findById(promotion.residenceId).select('title images price address city');
    if (residence) {
      enrichedPromotion.residence = residence;
    }
  }
  
  // Mettre en cache pour 30 minutes
  await cacheService.set(cacheKey, enrichedPromotion, 1800);
  
  res.status(200).json({
    success: true,
    data: enrichedPromotion
  });
});

// @desc    Mettre à jour une promotion
// @route   PUT /api/promotions/:id
// @access  Private (Admin/Partner)
exports.updatePromotion = asyncHandler(async (req, res, next) => {
  let promotion = await Promotion.findById(req.params.id);
  
  if (!promotion) {
    return next(new ErrorResponse(`Promotion non trouvée avec l'id ${req.params.id}`, 404));
  }
  
  // Vérifier les permissions
  if (req.user.role === 'partner') {
    const residence = await Residence.findById(promotion.residenceId);
    
    if (!residence) {
      return next(new ErrorResponse(`Résidence non trouvée`, 404));
    }
    
    // Vérifier que le partenaire est bien le propriétaire de la résidence
    if (residence.partner.toString() !== req.user.id) {
      return next(new ErrorResponse(`Vous n'êtes pas autorisé à modifier cette promotion`, 403));
    }
  }
  
  // Ajouter l'information de mise à jour
  req.body.updatedBy = req.user.id;
  req.body.updatedAt = Date.now();
  
  // Mettre à jour la promotion
  promotion = await Promotion.findByIdAndUpdate(req.params.id, req.body, {
    new: true,
    runValidators: true
  });
  
  // Invalider tous les caches liés aux promotions
  await cacheService.invalidatePattern('promotions_*');
  await cacheService.invalidate(`promotion_details_${req.params.id}`);
  
  res.status(200).json({
    success: true,
    data: promotion
  });
});

// @desc    Supprimer une promotion
// @route   DELETE /api/promotions/:id
// @access  Private (Admin/Partner)
exports.deletePromotion = asyncHandler(async (req, res, next) => {
  const promotion = await Promotion.findById(req.params.id);
  
  if (!promotion) {
    return next(new ErrorResponse(`Promotion non trouvée avec l'id ${req.params.id}`, 404));
  }
  
  // Vérifier les permissions
  if (req.user.role === 'partner') {
    const residence = await Residence.findById(promotion.residenceId);
    
    if (!residence) {
      return next(new ErrorResponse(`Résidence non trouvée`, 404));
    }
    
    // Vérifier que le partenaire est bien le propriétaire de la résidence
    if (residence.partner.toString() !== req.user.id) {
      return next(new ErrorResponse(`Vous n'êtes pas autorisé à supprimer cette promotion`, 403));
    }
  }
  
  await promotion.deleteOne();
  
  // Invalider tous les caches liés aux promotions
  await cacheService.invalidatePattern('promotions_*');
  await cacheService.invalidate(`promotion_details_${req.params.id}`);
  
  res.status(200).json({
    success: true,
    data: {}
  });
});
