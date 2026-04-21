const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
const { isAdmin } = require('../lib/roleMiddleware');
const dashboardController = require('../controllers/dashboard.controller');

router.get('/overview', protect, isAdmin, dashboardController.getOverview);
router.get('/financial-stats', protect, isAdmin, dashboardController.getFinancialStats);
router.get('/realtime', protect, isAdmin, dashboardController.getRealtimeStats);
router.get('/performance-metrics', protect, isAdmin, dashboardController.getPerformanceMetrics);
router.get('/residence-stats', protect, isAdmin, dashboardController.getResidenceStats);
router.get('/communication-stats', protect, isAdmin, dashboardController.getCommunicationStats);
router.get('/revenue-analytics', protect, isAdmin, dashboardController.getRevenueAnalytics);
router.get('/reports', protect, isAdmin, dashboardController.getReports);

module.exports = router;
