const Partner = require('../../models/partner.model');
const Residence = require('../../models/residence.model');
const Booking = require('../../models/booking.model');
const Payment = require('../../models/payment.model');
const statsService = require('../../services/stats.service');
const dashboardService = require('../../services/dashboard.service');
const ApiError = require('../../utils/apiError');
const asyncHandler = require('../../middlewares/async.middleware');

// Obtenir le profil du partenaire
exports.getPartnerProfile = asyncHandler(async (req, res) => {
    const partner = await Partner.findById(req.user.id).select('-password');
    res.status(200).json({
        success: true,
        data: partner
    });
});

// Mettre à jour le profil du partenaire
exports.updatePartnerProfile = asyncHandler(async (req, res) => {
    const { firstName, lastName, email, phone, address } = req.body;
    const partner = await Partner.findByIdAndUpdate(
        req.user.id,
        { firstName, lastName, email, phone, address },
        { new: true, runValidators: true }
    ).select('-password');

    res.status(200).json({
        success: true,
        data: partner
    });
});

// Obtenir les résidences du partenaire
exports.getPartnerResidences = asyncHandler(async (req, res) => {
    const residences = await Residence.find({ partner: req.user.id });
    res.status(200).json({
        success: true,
        data: residences
    });
});

// Obtenir les réservations des résidences du partenaire
exports.getPartnerBookings = asyncHandler(async (req, res) => {
    const residences = await Residence.find({ partner: req.user.id });
    const residenceIds = residences.map(residence => residence._id);

    const bookings = await Booking.find({
        residence: { $in: residenceIds }
    }).populate('residence user');

    res.status(200).json({
        success: true,
        data: bookings
    });
});

// Statistiques du partenaire
exports.getPartnerStats = asyncHandler(async (req, res) => {
    const partnerId = req.user.id;
    const stats = await statsService.getPartnerStats(partnerId);
    
    res.status(200).json({
        success: true,
        data: stats
    });
});

// Statistiques par résidence
exports.getResidenceStats = asyncHandler(async (req, res) => {
    const partnerId = req.user.id;
    const { startDate, endDate } = req.query;
    
    const residences = await Residence.find({ partner: partnerId });
    const residenceIds = residences.map(r => r._id);

    const stats = await Promise.all(residenceIds.map(async (residenceId) => {
        const residenceStats = await statsService.getResidenceStats(residenceId, startDate, endDate);
        return {
            ...residenceStats,
            residence: await Residence.findById(residenceId).select('title location images')
        };
    }));

    res.status(200).json({
        success: true,
        data: stats
    });
});

// Tendances
exports.getTrends = asyncHandler(async (req, res) => {
    const partnerId = req.user.id;
    const { period = 'monthly', startDate, endDate } = req.query;

    const trends = await statsService.getTrends(partnerId, period, startDate, endDate);

    res.status(200).json({
        success: true,
        data: trends
    });
});

// Revenus
exports.getEarnings = asyncHandler(async (req, res) => {
    const partnerId = req.user.id;
    const { startDate, endDate } = req.query;

    const earnings = await Payment.aggregate([
        {
            $match: {
                partner: partnerId,
                status: 'completed',
                createdAt: {
                    ...(startDate && { $gte: new Date(startDate) }),
                    ...(endDate && { $lte: new Date(endDate) })
                }
            }
        },
        {
            $group: {
                _id: {
                    year: { $year: '$createdAt' },
                    month: { $month: '$createdAt' }
                },
                totalEarnings: { $sum: '$amount' },
                count: { $sum: 1 }
            }
        },
        {
            $sort: { '_id.year': -1, '_id.month': -1 }
        }
    ]);

    res.status(200).json({
        success: true,
        data: earnings
    });
});

// Vue d'ensemble du dashboard
exports.getDashboardOverview = asyncHandler(async (req, res) => {
    const partnerId = req.user.id;
    const overview = await dashboardService.getOverview(partnerId);
    
    res.status(200).json({
        success: true,
        data: overview
    });
});

// Statistiques financières détaillées
exports.getDashboardFinances = asyncHandler(async (req, res) => {
    const partnerId = req.user.id;
    const financialStats = await dashboardService.getFinancialStats(partnerId);
    
    res.status(200).json({
        success: true,
        data: financialStats
    });
});

// Analytics en temps réel
exports.getDashboardRealtime = asyncHandler(async (req, res) => {
    const partnerId = req.user.id;
    const realtimeStats = await dashboardService.getRealTimeAnalytics(partnerId);
    
    res.status(200).json({
        success: true,
        data: realtimeStats
    });
});
