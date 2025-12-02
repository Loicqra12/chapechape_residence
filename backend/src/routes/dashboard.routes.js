const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
const { isAdmin } = require('../lib/roleMiddleware');
const dashboardController = require('../controllers/dashboard.controller');

router.get('/overview', protect, isAdmin, dashboardController.getOverview);
router.get('/financial-stats', protect, isAdmin, dashboardController.getFinancialStats);
router.get('/realtime', protect, isAdmin, dashboardController.getRealtimeStats);

module.exports = router;
