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
    checkResidenceAvailability,
    getFavoriteResidences,
    addToFavorites,
    removeFromFavorites
} = residenceController;
const Residence = require('../models/residence.model');

// Routes publiques
router.get('/', getResidences);
router.get('/search', searchResidences);
router.get('/all', getAllResidences);
router.get('/popular', getPopularResidences); // Nouveau: résidences populaires pour app client

// Routes protégées (partenaires uniquement)
router.use(protect);

// Récupérer les résidences du partenaire connecté
router.get('/my-residences', authorize('partner'), async (req, res) => {
  try {
    console.log('DEBUG - /my-residences - Utilisateur:', req.user);
    console.log('DEBUG - /my-residences - ID Utilisateur:', req.user.id);
    console.log('DEBUG - /my-residences - Rôle Utilisateur:', req.user.role);
    
    // Récupérer les résidences du partenaire avec un try/catch interne
    try {
      console.log('DEBUG - /my-residences - Recherche des résidences pour partner:', req.user.id);
      
      // Vérifier si le partenaire existe dans la base de données
      const filter = { partner: req.user.id, deleted: { $ne: true } }; // Exclure les résidences supprimées
      console.log('DEBUG - /my-residences - Filtre de recherche:', JSON.stringify(filter));
      
      // Récupérer toutes les résidences pour vérification (DEBUG)
      const allResidences = await Residence.find({ partner: req.user.id }).lean();
      console.log(`DEBUG - TOUTES les résidences pour ce partenaire (sans filtre): ${allResidences.length}`);
      
      if (allResidences.length > 0) {
        allResidences.forEach(res => {
          console.log(`- Résidence ID: ${res._id}, Titre: ${res.title}, Status: ${res.status}, Supprimée: ${res.deleted || false}`);
        });
      } else {
        console.log('Aucune résidence trouvée du tout pour ce partenaire (sans filtre)');
      }
      
      // Maintenant avec le filtre 'deleted'
      const residences = await Residence.find(filter).lean();
      console.log(`DEBUG - /my-residences - ${residences.length} résidences trouvées après filtrage`);
      
      if (residences.length > 0) {
        residences.forEach(res => {
          console.log(`- APRÈS FILTRE - Résidence ID: ${res._id}, Titre: ${res.title}, Status: ${res.status}`);
        });
      }
      
      res.json({ success: true, data: residences });
    } catch (innerError) {
      console.error('DEBUG - /my-residences - Erreur spécifique lors de la recherche:', innerError);
      throw innerError; // Re-lancer l'erreur pour le catch externe
    }
  } catch (error) {
    console.error('Erreur détaillée lors de la récupération des résidences du partenaire:', error);
    res.status(500).json({ 
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

// Routes spécifiques avec paramètre id - doivent être après les routes générales mais avant la route générique /:id
router.get('/:id/availability', checkResidenceAvailability); // Nouveau: vérification disponibilité pour app client

// Route publique avec paramètre id - doit être après les routes spécifiques
router.get('/:id', getResidence);

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
