const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
const { isPartner } = require('../lib/roleMiddleware');
const partnerController = require('../controllers/partner/partner.controller');
const uploadMiddleware = require('../middlewares/upload.middleware');
const { publicAuthView } = require('../security/partner-capabilities');

router.use(protect, isPartner);

router.get('/capabilities', (req, res) => {
  res.status(200).json({
    success: true,
    role: req.user.role,
    ...publicAuthView(req.user),
  });
});

router.get('/dashboard/overview', partnerController.getDashboardOverview);
router.get('/dashboard/finances', partnerController.getDashboardFinances);
router.get('/dashboard/realtime', partnerController.getDashboardRealtime);
router.get('/dashboard/my-cities-stats', partnerController.getMyCitiesStats);

router.get('/profile', partnerController.getPartnerProfile);
router.put('/profile', uploadMiddleware.profile.fields([
    { name: 'profileImage', maxCount: 1 },
    { name: 'profileimage', maxCount: 1 },
    { name: 'profile_image', maxCount: 1 },
    { name: 'image', maxCount: 1 },
    { name: 'document', maxCount: 1 }
]), partnerController.updatePartnerProfile);

router.post('/documents', uploadMiddleware.document.single('document'),
    partnerController.uploadDocument);

router.get('/residences', partnerController.getPartnerResidences);
router.get('/bookings', partnerController.getPartnerBookings);
router.get('/stats', partnerController.getPartnerStats);
router.get('/stats/residences', partnerController.getResidenceStats);
router.get('/stats/trends', partnerController.getTrends);
router.get('/earnings', partnerController.getEarnings);

module.exports = router;
