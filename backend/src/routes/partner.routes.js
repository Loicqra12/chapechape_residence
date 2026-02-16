const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
const { isPartner } = require('../lib/roleMiddleware');
const partnerController = require('../controllers/partner/partner.controller');
const uploadMiddleware = require('../middlewares/upload.middleware');

// Routes protégées pour les partenaires
router.use(protect, isPartner);

// Dashboard
router.get('/dashboard/overview', partnerController.getDashboardOverview);
router.get('/dashboard/finances', partnerController.getDashboardFinances);
router.get('/dashboard/realtime', partnerController.getDashboardRealtime);
router.get('/dashboard/my-cities-stats', partnerController.getMyCitiesStats);

// Profil du partenaire
router.get('/profile', partnerController.getPartnerProfile);
router.put('/profile', uploadMiddleware.profile.fields([
    { name: 'profileImage', maxCount: 1 },
    { name: 'profileimage', maxCount: 1 },
    { name: 'profile_image', maxCount: 1 },
    { name: 'image', maxCount: 1 },
    { name: 'document', maxCount: 1 }
]), partnerController.updatePartnerProfile);

// Route spécifique pour les documents
router.post('/documents', uploadMiddleware.document.single('document'), 
    partnerController.uploadDocument);

// Résidences du partenaire
router.get('/residences', partnerController.getPartnerResidences);

// Réservations du partenaire
router.get('/bookings', partnerController.getPartnerBookings);

// Statistiques du partenaire
router.get('/stats', partnerController.getPartnerStats);
router.get('/stats/residences', partnerController.getResidenceStats);
router.get('/stats/trends', partnerController.getTrends);
router.get('/earnings', partnerController.getEarnings);

module.exports = router;
