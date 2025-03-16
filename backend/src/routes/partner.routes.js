const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
const { isPartner } = require('../lib/roleMiddleware');
const partnerController = require('../controllers/partner/partner.controller');

// Routes protégées pour les partenaires
router.use(protect, isPartner);

// Dashboard
router.get('/dashboard/overview', partnerController.getDashboardOverview);
router.get('/dashboard/finances', partnerController.getDashboardFinances);
router.get('/dashboard/realtime', partnerController.getDashboardRealtime);

// Profil du partenaire
router.get('/profile', partnerController.getPartnerProfile);
router.put('/profile', partnerController.updatePartnerProfile);

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
