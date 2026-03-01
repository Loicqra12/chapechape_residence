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

// Routes publiques (accessibles sans authentification)
// ⚠️ IMPORTANT: Les routes statiques DOIVENT être définies avant /:id pour éviter la capture
router.get('/', getResidences);
router.get('/search', searchResidences);
router.get('/all', getAllResidences);
router.get('/popular', getPopularResidences);
router.get('/stats/count-by-type', getResidenceCountByType);
router.get('/trending', getTrendingResidences);

// Route pour récupérer les résidences d'un partenaire spécifique (par son ID)
// Doit être avant /:id pour ne pas être capturée par la route générique
router.get('/partner/:partnerId', async (req, res) => {
  try {
    const { partnerId } = req.params;
    // Validation basique de l'ObjectId
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

router.get('/:id/availability', checkResidenceAvailability);
router.get('/:id', getResidence); // Détail résidence — public (visiteurs non connectés)

// Routes protégées (partenaires uniquement)
router.use(protect);

// ⚠️ IMPORTANT : /my-residences doit être défini IMMÉDIATEMENT après router.use(protect)
// et avant toute route avec paramètre dynamique (/:id) pour éviter la capture par Express.
// Récupérer les résidences du partenaire connecté
router.get('/my-residences', authorize('partner'), async (req, res) => {
  console.log('DEBUG /my-residences - route atteinte');
  try {
    const partnerId = req.user?.id ?? req.user?._id ?? (req.user && req.user.id);
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

// Routes pour les favoris (compatibilité app client) - nécessitent une authentification
router.get('/favorites', protect, getFavoriteResidences);
router.post('/favorites/:id', protect, addToFavorites);
router.delete('/favorites/:id', protect, removeFromFavorites);

// Route de redirection pour les avis (compatibilité app client)
router.get('/:id/reviews', (req, res) => {
  // Redirection vers l'endpoint existant des avis
  res.redirect(301, `/api/reviews/residence/${req.params.id}?${new URLSearchParams(req.query).toString()}`);
});

// Routes qui nécessitent des droits de partenaire ou d'administrateur
router.use(authorize('partner', 'admin'));

// Ajout de la validation Joi pour la création et la mise à jour
router.post('/', validate(residenceValidation.createResidence), createResidence);
router.put('/:id', validate(residenceValidation.updateResidence), updateResidence);
router.delete('/:id', deleteResidence);

// Routes pour la gestion des images
// 1. Route traditionnelle avec upload de fichiers physiques
router.post('/:id/images/local', validate(residenceValidation.uploadImages), upload.residence.array('images', 5), uploadImages);

// 2. Route avec upload direct vers Cloudinary (via multer-storage-cloudinary)
router.post('/:id/images/cloudinary', validate(residenceValidation.uploadImages), uploadResidenceImages, uploadImages);

// 3. Route pour recevoir directement des URLs Cloudinary (depuis l'app mobile/web)
router.post('/:id/images', validate(residenceValidation.uploadImages), uploadImages);

// 4. Route pour supprimer une image spécifique
router.delete('/:id/images/:imageIndex', validate(residenceValidation.deleteImage), deleteImage);

// Routes pour les nouvelles fonctionnalités
router.post('/:id/nearby-places', protect, authorize('partner'), residenceController.addNearbyPlace);
router.put('/:id/nearby-places', protect, authorize('partner'), residenceController.updateNearbyPlaces);

// Routes avec validation Joi pour les FAQs
router.post('/:id/faqs', protect, authorize('partner'), residenceController.addFaq);
router.put('/:id/faqs', protect, authorize('partner'), validate(residenceValidation.updateFaqs), residenceController.updateFaqs);

// Routes avec validation Joi pour les méthodes de paiement
router.put('/:id/payment-methods', protect, authorize('partner'), validate(residenceValidation.updatePaymentMethods), residenceController.updatePaymentMethods);

// Routes avec validation Joi pour les équipements améliorés
router.put('/:id/enhanced-amenities', protect, authorize('partner'), validate(residenceValidation.updateEnhancedAmenities), residenceController.updateEnhancedAmenities);

// Autres routes
router.put('/:id/stars', protect, authorize('admin'), residenceController.updateStars);
router.put('/:id/ratings', protect, residenceController.updateRatings);

module.exports = router;
