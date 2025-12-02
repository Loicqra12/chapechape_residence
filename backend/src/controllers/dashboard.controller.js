const asyncHandler = require('../middlewares/async.middleware');
const statsService = require('../services/stats.service');
const Reservation = require('../models/reservation.model');
const Payment = require('../models/payment.model');
const Residence = require('../models/residence.model');
const Message = require('../models/message.model');

// @desc    Get dashboard overview
// @route   GET /api/dashboard/overview
// @access  Private/Admin
exports.getOverview = asyncHandler(async (req, res) => {
  // Récupérer les stats de base via le service existant
  const adminStats = await statsService.getAdminStats();

  // Récupérer des stats détaillées pour les réservations
  const bookingStats = await Reservation.aggregate([
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 }
      }
    }
  ]);

  const bookings = {
    total: adminStats.totalReservations,
    confirmed: bookingStats.find(s => s._id === 'confirmed')?.count || 0,
    pending: bookingStats.find(s => s._id === 'pending')?.count || 0,
    completed: bookingStats.find(s => s._id === 'completed')?.count || 0,
    cancelled: bookingStats.find(s => s._id === 'cancelled')?.count || 0,
    refunded: bookingStats.find(s => s._id === 'refunded')?.count || 0
  };

  // Calculer le taux d'occupation (simplifié)
  const totalResidences = adminStats.totalResidences;
  const occupiedResidences = await Reservation.distinct('residence', {
    status: { $in: ['confirmed', 'checked_in'] },
    checkIn: { $lte: new Date() },
    checkOut: { $gte: new Date() }
  });
  const occupancyRate = totalResidences > 0 ? (occupiedResidences.length / totalResidences) * 100 : 0;

  // Récupérer les nouveaux messages
  const newMessages = await Message.countDocuments({ read: false });

  res.status(200).json({
    success: true,
    data: {
      bookings,
      occupancy_rate: Math.round(occupancyRate),
      performance: {
        total_revenue: adminStats.totalRevenue,
        average_rating: 4.5 // À implémenter réellement avec les avis
      },
      total_residences: totalResidences,
      new_messages: newMessages,
      response_rate: 98 // À implémenter
    }
  });
});

// @desc    Get financial stats
// @route   GET /api/dashboard/financial-stats
// @access  Private/Admin
exports.getFinancialStats = asyncHandler(async (req, res) => {
  // Récupérer les revenus par mois pour l'année en cours
  const currentYear = new Date().getFullYear();
  const monthlyRevenue = await Payment.aggregate([
    {
      $match: {
        status: 'completed',
        createdAt: {
          $gte: new Date(`${currentYear}-01-01`),
          $lte: new Date(`${currentYear}-12-31`)
        }
      }
    },
    {
      $group: {
        _id: { $month: '$createdAt' },
        revenue: { $sum: '$amount' }
      }
    },
    { $sort: { _id: 1 } }
  ]);

  res.status(200).json({
    success: true,
    data: {
      monthly_revenue: monthlyRevenue,
      total_revenue: monthlyRevenue.reduce((acc, curr) => acc + curr.revenue, 0)
    }
  });
});

// @desc    Get realtime stats
// @route   GET /api/dashboard/realtime
// @access  Private/Admin
exports.getRealtimeStats = asyncHandler(async (req, res) => {
  // Simuler des données temps réel pour l'instant
  // Idéalement, cela viendrait de Redis ou Socket.io
  const activeUsers = Math.floor(Math.random() * 50) + 10;

  res.status(200).json({
    success: true,
    data: {
      active_users: activeUsers,
      recent_bookings: await Reservation.find()
        .sort({ createdAt: -1 })
        .limit(5)
        .populate('user', 'firstName lastName')
        .populate('residence', 'title')
    }
  });
});
