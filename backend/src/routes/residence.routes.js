const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/auth.middleware');
const upload = require('../middlewares/upload.middleware');
const {
    createResidence,
    getResidences,
    getResidence,
    updateResidence,
    deleteResidence,
    searchResidences,
    uploadImages
} = require('../controllers/residence/residence.controller');
const Residence = require('../models/residence.model');

// Routes publiques
router.get('/', getResidences);
router.get('/search', searchResidences);

// Routes protégées (partenaires uniquement)
router.use(protect);

// Récupérer les résidences du partenaire connecté
router.get('/my-residences', async (req, res) => {
  try {
    console.log('DEBUG - /my-residences - Utilisateur:', req.user);
    console.log('DEBUG - /my-residences - ID Utilisateur:', req.user.id);
    console.log('DEBUG - /my-residences - Rôle Utilisateur:', req.user.role);
    
    // Vérifier si l'utilisateur est un partenaire
    if (req.user.role !== 'partner') {
      console.log('DEBUG - /my-residences - Utilisateur non partenaire');
      return res.status(403).json({ 
        success: false, 
        message: 'Seuls les partenaires peuvent accéder à leurs résidences' 
      });
    }
    
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

// Route publique avec paramètre id - doit être après les routes spécifiques
router.get('/:id', getResidence);

// Routes qui nécessitent des droits de partenaire ou d'administrateur
router.use(authorize('partner', 'admin'));

router.post('/', createResidence);
router.put('/:id', updateResidence);
router.delete('/:id', deleteResidence);

// Route pour l'upload d'images
router.post('/:id/images', upload.residence.array('images', 5), uploadImages);

module.exports = router;
