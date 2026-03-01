const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');
const residenceValidation = require('../validations/residence.validation');
const upload = require('../middlewares/upload.middleware');
const { uploadResidenceImages } = require('../config/cloudinary');
const residenceController = require('../controllers/residence/residence.controller');
const {
  createResidence,
  getResidences,
  getResidence,
  updateResidence,
  deleteResidence,
  searchResidences,
  uploadImages,
  deleteImage,
  getAllResidences,
  getPopularResidences,
  getResidenceCountByType,
  getTrendingResidences,
  checkResidenceAvailability,
  getFavoriteResidences,
  addToFavorites,
  removeFromFavorites
} = residenceController;
const Residence = require('../models/residence.model');

// =============================================================================
// RÈGLE FONDAMENTALE EXPRESS :
// Les routes sont matchées dans l'ORDRE DE DÉCLARATION.
// Toutes les routes statiques nommées DOIVENT être déclarées AVANT /:id,
// sinon /:id les capture en premier (ex: "my-residences" → findById("my-residences") → 500).
// Les routes nécessitant protect/authorize avant router.use(protect)
// doivent avoir ces middlewares appliqués INLINE sur le handler.
// =============================================================================

// -----------------------------------------------------------------------------
// BLOC 1 — Routes publiques statiques (sans authentification)
// Toutes déclarées avant /:id pour éviter toute capture parasite
// -----------------------------------------------------------------------------
router.get('/', getResidences);
router.get('/search', searchResidences);
router.get('/all', getAllResidences);
router.get('/popular', getPopularResidences);
router.get('/stats/count-by-type', getResidenceCountByType);
router.get('/trending', getTrendingResidences);

// Résidences d'un partenaire par son ID (accès public — app client / site vitrine)
router.get('/partner/:partnerId', async (req, res) => {
  try {
    const { partnerId } = req.params;
    if (!partnerId.match(/^[0-9a-fA-F]{24}$/)) {
      return res.status(400).json({ success: false, message: 'ID partenaire invalide' });
    }
    const residences = await Residence.find({
      partner: partnerId,
      deleted: { $ne: true }
    }).lean();
    if (!residences || residences.length === 0) {
      return res.status(404).json({ success: false, message: 'Aucune résidence trouvée pour ce partenaire' });
    }
    return res.json({ success: true, count: residences.length, data: residences });
  } catch (error) {
    console.error('Erreur GET /partner/:partnerId:', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur', error: error.message });
  }
});

// -----------------------------------------------------------------------------
// BLOC 2 — Routes protégées statiques avec protect/authorize INLINE
// Déclarées ici (avant /:id) pour ne pas être capturées par la route générique.
// protect et authorize sont appliqués directement sur chaque route.
// -----------------------------------------------------------------------------

// Résidences du partenaire connecté
router.get('/my-residences', protect, authorize('partner'), async (req, res) => {
  console.log('DEBUG /my-residences - route atteinte');
  try {
    const partnerId = req.user?.id ?? req.user?._id;
    if (!partnerId) {
      console.error('DEBUG /my-residences - req.user manquant, keys:', req.user ? Object.keys(req.user) : 'null');
      return res.status(401).json({ success: false, message: 'Utilisateur non identifié' });
    }
    const filter = { partner: partnerId, deleted: { $ne: true } };
    try {
      const residences = await Residence.find(filter).lean();
      console.log('DEBUG /my-residences - ok, count=', residences.length);
      return res.json({ success: true, data: residences });
    } catch (innerError) {
      console.error('DEBUG /my-residences - Erreur MongoDB:', innerError.message, innerError.stack);
      return res.status(500).json({
        success: false,
        message: 'Erreur lors de la récupération des résidences du partenaire',
        error: innerError.message
      });
    }
  } catch (error) {
    console.error('DEBUG /my-residences - Erreur détaillée:', error.message, error.stack);
    return res.status(500).json({
      success: false,
      message: 'Erreur lors de la récupération des résidences du partenaire',
      error: error.message
    });
  }
});

// Favoris du client connecté (compatibilité app client)
router.get('/favorites', protect, getFavoriteResidences);
router.post('/favorites/:id', protect, addToFavorites);
router.delete('/favorites/:id', protect, removeFromFavorites);

// -----------------------------------------------------------------------------
// BLOC 3 — Routes publiques dynamiques (avec paramètre :id)
// Déclarées EN DERNIER parmi les routes publiques, après toutes les routes
// statiques, pour ne pas capturer /my-residences, /favorites, /partner, etc.
// -----------------------------------------------------------------------------
router.get('/:id/availability', checkResidenceAvailability);

// Redirection vers l'endpoint des avis (compatibilité app client — accès public)
router.get('/:id/reviews', (req, res) => {
  res.redirect(301, `/api/reviews/residence/${req.params.id}?${new URLSearchParams(req.query).toString()}`);
});

// Route générique — DOIT RESTER EN DERNIÈRE position dans les routes GET publiques
router.get('/:id', getResidence);

// -----------------------------------------------------------------------------
// BLOC 4 — Middleware global protect + authorize pour toutes les routes suivantes
// Toutes les routes définies après ce bloc héritent de protect et authorize.
// -----------------------------------------------------------------------------
router.use(protect);
router.use(authorize('partner', 'admin'));

// Création et modification (validation Joi incluse)
router.post('/', validate(residenceValidation.createResidence), createResidence);
router.put('/:id', validate(residenceValidation.updateResidence), updateResidence);
router.delete('/:id', deleteResidence);

// Gestion des images
router.post('/:id/images/local', validate(residenceValidation.uploadImages), upload.residence.array('images', 5), uploadImages);
router.post('/:id/images/cloudinary', validate(residenceValidation.uploadImages), uploadResidenceImages, uploadImages);
router.post('/:id/images', validate(residenceValidation.uploadImages), uploadImages);
router.delete('/:id/images/:imageIndex', validate(residenceValidation.deleteImage), deleteImage);

// Points d'intérêt à proximité
router.post('/:id/nearby-places', residenceController.addNearbyPlace);
router.put('/:id/nearby-places', residenceController.updateNearbyPlaces);

// FAQs
router.post('/:id/faqs', residenceController.addFaq);
router.put('/:id/faqs', validate(residenceValidation.updateFaqs), residenceController.updateFaqs);

// Méthodes de paiement
router.put('/:id/payment-methods', validate(residenceValidation.updatePaymentMethods), residenceController.updatePaymentMethods);

// Équipements améliorés
router.put('/:id/enhanced-amenities', validate(residenceValidation.updateEnhancedAmenities), residenceController.updateEnhancedAmenities);

// Étoiles (admin seulement — protect + authorize('admin') inline pour surcharger le authorize global)
router.put('/:id/stars', authorize('admin'), residenceController.updateStars);

// Notations (clients authentifiés — accessible via protect global)
router.put('/:id/ratings', residenceController.updateRatings);

module.exports = router;
