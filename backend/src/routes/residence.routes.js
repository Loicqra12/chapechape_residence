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

// Routes publiques
router.get('/', getResidences);
router.get('/search', searchResidences);
router.get('/:id', getResidence);

// Routes protégées (partenaires uniquement)
router.use(protect);
router.use(authorize('partner', 'admin'));

router.post('/', createResidence);
router.put('/:id', updateResidence);
router.delete('/:id', deleteResidence);

// Route pour l'upload d'images
router.post('/:id/images', upload.array('images', 5), uploadImages);

module.exports = router;
