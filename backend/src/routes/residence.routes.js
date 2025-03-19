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
      
      // Essayer d'abord avec le champ partner._id
      const residences = await Residence.find({ 'partner._id': req.user.id }).lean();
      if (residences.length > 0) {
        console.log(`DEBUG - /my-residences - ${residences.length} résidences trouvées avec partner._id`);
        return res.json({ success: true, data: residences });
      }
      
      // Si aucune résidence n'est trouvée, essayer avec partner directement
      console.log('DEBUG - /my-residences - Aucune résidence trouvée avec partner._id, essai avec partner');
      const residencesAlt = await Residence.find({ partner: req.user.id }).lean();
      console.log(`DEBUG - /my-residences - ${residencesAlt.length} résidences trouvées avec partner`);
      
      res.json({ success: true, data: residencesAlt });
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
router.post('/:id/images', upload.array('images', 5), uploadImages);

module.exports = router;
