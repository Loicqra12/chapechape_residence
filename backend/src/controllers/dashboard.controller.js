const asyncHandler = require('../middlewares/async.middleware');
const statsService = require('../services/stats.service');
const Reservation = require('../models/reservation.model');
const Payment = require('../models/payment.model');
const Residence = require('../models/residence.model');
const { Message } = require('../models/message.model');
const Review = require('../models/review.model');

function safeDate(input) {
  if (!input) return null;
  const d = new Date(input);
  return Number.isNaN(d.getTime()) ? null : d;
}

function parseTimeframeToDays(timeframe) {
  switch (timeframe) {
    case 'week':
      return 7;
    case 'month':
      return 30;
    case 'quarter':
      return 90;
    case 'year':
      return 365;
    default:
      return 30;
  }
}

function buildMonthArrayFromAggResults(results, year) {
  // results: [{ _id: <monthNumber>, revenue|count: <value> }]
  const arr = Array(12).fill(0);
  results.forEach((r) => {
    const monthIdx = (r._id || 1) - 1;
    if (monthIdx >= 0 && monthIdx < 12) arr[monthIdx] = Number(r.value || r.count || r.revenue || 0);
  });
  return arr;
}

function formatAverageDurationDays(avgDays) {
  if (!avgDays || Number.isNaN(avgDays)) return 0;
  return Math.round(avgDays * 10) / 10;
}

// @desc    Get dashboard overview
// @route   GET /api/dashboard/overview
// @access  Private/Admin
exports.getOverview = asyncHandler(async (req, res) => {
  const now = new Date();
  const rangeStart = new Date(now);
  rangeStart.setDate(rangeStart.getDate() - 30);

  const currentYear = now.getFullYear();
  const yearStart = new Date(currentYear, 0, 1, 0, 0, 0, 0);
  const yearEndExclusive = new Date(currentYear + 1, 0, 1, 0, 0, 0, 0);

  const [
    bookingStats,
    completedAvgDuration,
    totalRevenueRange,
    avgRatingRange,
    unreadMessages7d,
    respondedMessages7d,
    avgResponseTimeHours7d,
    activeSupportDistinctSenders7d,
    totalResidences,
    availableResidences,
    withPoolResidences,
    avgPriceResidences,
    occupiedResidences,
    monthlyBookingsYear,
    monthlyRevenueYear
  ] = await Promise.all([
    // Réservations sur les 30 derniers jours
    Reservation.aggregate([
      {
        $match: {
          createdAt: { $gte: rangeStart }
        }
      },
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 }
        }
      }
    ]),

    // Durée moyenne des réservations complétées (en jours) sur les 30 derniers jours
    Reservation.aggregate([
      {
        $match: {
          status: 'completed',
          createdAt: { $gte: rangeStart }
        }
      },
      {
        $group: {
          _id: null,
          avgDays: {
            $avg: {
              $divide: [
                {
                  $subtract: [
                    { $ifNull: ['$actualCheckOut', '$checkOut'] },
                    { $ifNull: ['$actualCheckIn', '$checkIn'] }
                  ]
                },
                1000 * 60 * 60 * 24
              ]
            }
          }
        }
      }
    ]),

    // Revenu (paiements) sur les 30 derniers jours
    Payment.aggregate([
      {
        $match: {
          status: 'paid',
          createdAt: { $gte: rangeStart }
        }
      },
      {
        $group: {
          _id: null,
          total: { $sum: '$amount' }
        }
      }
    ]),

    // Note moyenne (avis) sur les 30 derniers jours
    Review.aggregate([
      {
        $match: {
          createdAt: { $gte: rangeStart }
        }
      },
      {
        $group: {
          _id: null,
          avgOverall: { $avg: '$rating.overall' }
        }
      }
    ]),

    // Communication sur 7 jours
    Message.countDocuments({
      read: false,
      createdAt: { $gte: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000) }
    }),
    Message.countDocuments({
      read: true,
      createdAt: { $gte: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000) }
    }),
    Message.aggregate([
      {
        $match: {
          read: true,
          readAt: { $exists: true, $ne: null },
          createdAt: { $gte: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000) }
        }
      },
      {
        $group: {
          _id: null,
          avgHours: {
            $avg: {
              $divide: [
                { $subtract: ['$readAt', '$createdAt'] },
                1000 * 60 * 60
              ]
            }
          }
        }
      }
    ]),
    // Nombre d'agents "actifs" sur 7 jours (en pratique: nombre d'expéditeurs distincts)
    Message.distinct('sender', {
      createdAt: { $gte: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000) }
    }),

    // Résidences
    Residence.countDocuments({ deleted: { $ne: true } }),
    Residence.countDocuments({ deleted: { $ne: true }, status: 'available' }),
    Residence.countDocuments({ deleted: { $ne: true }, amenities: 'pool' }),
    Residence.aggregate([
      {
        $match: { deleted: { $ne: true }, status: 'available' }
      },
      {
        $group: { _id: null, avgPrice: { $avg: '$price' } }
      }
    ]),

    // Occupancy rate (occupation réelle sur aujourd'hui)
    Reservation.distinct('residence', {
      status: { $in: ['confirmed', 'in_stay'] },
      checkIn: { $lte: now },
      checkOut: { $gte: now }
    }),

    // Tendances annuelles bookings (créés dans l'année courante)
    Reservation.aggregate([
      {
        $match: {
          createdAt: { $gte: yearStart, $lt: yearEndExclusive }
        }
      },
      {
        $group: {
          _id: { $month: '$createdAt' },
          count: { $sum: 1 }
        }
      },
      { $sort: { _id: 1 } }
    ]),

    // Tendances annuelles revenue (payments)
    Payment.aggregate([
      {
        $match: {
          status: 'paid',
          createdAt: { $gte: yearStart, $lt: yearEndExclusive }
        }
      },
      {
        $group: {
          _id: { $month: '$createdAt' },
          revenue: { $sum: '$amount' }
        }
      },
      { $sort: { _id: 1 } }
    ])
  ]);

  const bookingsByStatus = bookingStats.reduce((acc, curr) => {
    acc[curr._id] = curr.count;
    return acc;
  }, {});

  const bookings = {
    total: Object.values(bookingsByStatus).reduce((sum, v) => sum + v, 0),
    confirmed: Number(bookingsByStatus.confirmed || 0),
    pending: Number(bookingsByStatus.pending || 0),
    completed: Number(bookingsByStatus.completed || 0),
    cancelled: Number(bookingsByStatus.cancelled || 0),
    refunded: Number(bookingsByStatus.refunded || 0)
  };

  const occupiedCount = occupiedResidences.length || 0;
  const occupancyRate = totalResidences > 0 ? (occupiedCount / totalResidences) * 100 : 0;

  const responseTotalMessages7d = Number(unreadMessages7d) + Number(respondedMessages7d);
  const responseRate = responseTotalMessages7d > 0 ? (respondedMessages7d / responseTotalMessages7d) * 100 : 100;

  const avgResponseTimeHours = avgResponseTimeHours7d?.[0]?.avgHours || 0;
  const avgDurationDays = completedAvgDuration?.[0]?.avgDays || 0;
  const averageDurationDays = formatAverageDurationDays(avgDurationDays);

  const totalRevenue = totalRevenueRange?.[0]?.total || 0;
  const averageRating = avgRatingRange?.[0]?.avgOverall || 0;
  const averagePrice = avgPriceResidences?.[0]?.avgPrice || 0;

  const monthlyBookings = monthlyBookingsYear.reduce((acc, r) => {
    const idx = (r._id || 1) - 1;
    if (idx >= 0 && idx < 12) acc[idx] = r.count;
    return acc;
  }, Array(12).fill(0));

  const monthlyRevenue = monthlyRevenueYear.reduce((acc, r) => {
    const idx = (r._id || 1) - 1;
    if (idx >= 0 && idx < 12) acc[idx] = r.revenue;
    return acc;
  }, Array(12).fill(0));

  const activeSupportCount = Array.isArray(activeSupportDistinctSenders7d) ? activeSupportDistinctSenders7d.length : 0;

  res.status(200).json({
    success: true,
    data: {
      bookings,
      occupancy_rate: Math.round(occupancyRate),
      performance: {
        total_revenue: totalRevenue,
        average_rating: Math.round(averageRating * 10) / 10,
        average_duration_days: averageDurationDays
      },
      total_residences: totalResidences,
      residence_stats: {
        available: availableResidences,
        with_pool: withPoolResidences,
        average_price: Math.round(averagePrice)
      },
      communication_stats: {
        new_messages: Number(unreadMessages7d),
        total_messages: responseTotalMessages7d,
        response_rate: Math.round(responseRate * 10) / 10,
        average_response_time_hours: Math.round(avgResponseTimeHours * 10) / 10,
        active_support: activeSupportCount
      },
      monthly_bookings: monthlyBookings,
      monthly_revenue: monthlyRevenue
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
        status: 'paid',
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
  const now = new Date();
  const activeUsers = await Reservation.distinct('user', {
    status: { $in: ['confirmed', 'in_stay'] },
    checkIn: { $lte: now },
    checkOut: { $gte: now }
  });

  res.status(200).json({
    success: true,
    data: {
      active_users: activeUsers.length,
      recent_bookings: await Reservation.find()
        .sort({ createdAt: -1 })
        .limit(5)
        .populate('user', 'firstName lastName')
        .populate('residence', 'title')
    }
  });
});

// @desc    Get performance metrics (réservations)
// @route   GET /api/dashboard/performance-metrics
// @access  Private/Admin
exports.getPerformanceMetrics = asyncHandler(async (req, res) => {
  const timeframe = req.query.timeframe || 'month';
  const startDate = safeDate(req.query.startDate);
  const endDate = safeDate(req.query.endDate);

  const end = endDate || new Date();
  const start = startDate || new Date(end.getTime() - parseTimeframeToDays(timeframe) * 24 * 60 * 60 * 1000);

  const bookingStats = await Reservation.aggregate([
    {
      $match: {
        createdAt: { $gte: start, $lte: end }
      }
    },
    {
      $group: {
        _id: '$status',
        count: { $sum: 1 }
      }
    }
  ]);

  const byStatus = bookingStats.reduce((acc, curr) => {
    acc[curr._id] = curr.count;
    return acc;
  }, {});

  const pendingBookings = Number(byStatus.pending || 0);
  const confirmedBookings = Number(byStatus.confirmed || 0);
  const completedBookings = Number(byStatus.completed || 0);
  const cancelledBookings = Number(byStatus.cancelled || 0);
  const refundedBookings = Number(byStatus.refunded || 0);

  const totalBookings = pendingBookings + confirmedBookings + completedBookings + cancelledBookings + refundedBookings + Number(byStatus.payment_pending || 0) + Number(byStatus.awaiting_approval || 0) + Number(byStatus.expired || 0) + Number(byStatus.in_stay || 0);

  const conversionRate = totalBookings > 0 ? ((confirmedBookings + completedBookings) / totalBookings) * 100 : 0;
  const cancellationRate = totalBookings > 0 ? ((cancelledBookings + refundedBookings) / totalBookings) * 100 : 0;

  const durationAgg = await Reservation.aggregate([
    {
      $match: {
        status: 'completed',
        createdAt: { $gte: start, $lte: end }
      }
    },
    {
      $group: {
        _id: null,
        avgDays: {
          $avg: {
            $divide: [
              {
                $subtract: [
                  { $ifNull: ['$actualCheckOut', '$checkOut'] },
                  { $ifNull: ['$actualCheckIn', '$checkIn'] }
                ]
              },
              1000 * 60 * 60 * 24
            ]
          }
        }
      }
    }
  ]);

  const avgDays = durationAgg?.[0]?.avgDays || 0;
  const averageDuration = completedBookings > 0 ? `${Math.round(avgDays)}j` : '0j';

  res.status(200).json({
    success: true,
    data: {
      totalBookings,
      pendingBookings,
      confirmedBookings,
      completedBookings,
      cancelledBookings,
      refundedBookings,
      conversionRate: Math.round(conversionRate * 10) / 10,
      cancellationRate: Math.round(cancellationRate * 10) / 10,
      averageDuration
    }
  });
});

// @desc    Get residence stats (résidences)
// @route   GET /api/dashboard/residence-stats
// @access  Private/Admin
exports.getResidenceStats = asyncHandler(async (req, res) => {
  const timeframe = req.query.timeframe || 'month';
  const startDate = safeDate(req.query.startDate);
  const endDate = safeDate(req.query.endDate);

  const end = endDate || new Date();
  const start = startDate || new Date(end.getTime() - parseTimeframeToDays(timeframe) * 24 * 60 * 60 * 1000);

  const VACATION_TYPES = new Set([
    'hotel',
    'hotel_passage',
    'motel',
    'boutique_hotel',
    'hotel_luxe',
    'guest_house',
    'residence_hoteliere',
    'bungalow',
    'lodge',
    'case_traditionnelle',
    'maison_flottante',
    'campement_touristique'
  ]);

  const residences = await Residence.find({ deleted: { $ne: true } })
    .select('_id title images price type status amenities stars rating city address locationData')
    .lean();

  const total = residences.length;
  const available = residences.filter((r) => r.status === 'available').length;
  const withPool = residences.filter((r) => (r.amenities || []).includes('pool')).length;
  const vacation = residences.filter((r) => VACATION_TYPES.has(r.type)).length;
  const special = residences.filter((r) => (r.stars || 0) >= 4).length;

  // Total bookings & completed bookings par résidence (dans la période)
  const bookingAgg = await Reservation.aggregate([
    {
      $match: {
        createdAt: { $gte: start, $lte: end },
        residence: { $in: residences.map((r) => r._id) },
        status: { $in: ['pending', 'confirmed', 'completed', 'in_stay'] }
      }
    },
    {
      $group: {
        _id: '$residence',
        totalBookings: { $sum: 1 },
        completedBookings: {
          $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] }
        }
      }
    }
  ]);

  const bookingsByResidenceId = bookingAgg.reduce((acc, curr) => {
    acc[String(curr._id)] = curr;
    return acc;
  }, {});

  const mostBooked = residences
    .map((r) => {
      const b = bookingsByResidenceId[String(r._id)] || { totalBookings: 0, completedBookings: 0 };
      const totalBookings = Number(b.totalBookings || 0);
      const completedBookings = Number(b.completedBookings || 0);
      const occupancyRate = totalBookings > 0 ? (completedBookings / totalBookings) * 100 : 0;

      return {
        _id: r._id,
        title: r.title,
        imageUrl: r.images?.[0] || '',
        displayAddress: `${r.city || r.address || 'N/A'}, ${r.locationData?.country || 'CI'}`.replace(/undefined/g, ''),
        hasPool: (r.amenities || []).includes('pool'),
        isVacationResidence: VACATION_TYPES.has(r.type),
        isSpecialResidence: (r.stars || 0) >= 4,
        occupancyRate,
        completedBookings,
        totalBookings
      };
    })
    .sort((a, b) => b.occupancyRate - a.occupancyRate)
    .slice(0, 5);

  const occupancy_rate =
    total > 0
      ? residences.reduce((sum, r) => {
          const b = bookingsByResidenceId[String(r._id)] || { totalBookings: 0, completedBookings: 0 };
          const totalBookings = Number(b.totalBookings || 0);
          const completedBookings = Number(b.completedBookings || 0);
          const rr = totalBookings > 0 ? (completedBookings / totalBookings) * 100 : 0;
          return sum + rr;
        }, 0) / total
      : 0;

  res.status(200).json({
    success: true,
    data: {
      total,
      available,
      withPool,
      vacation,
      special,
      occupancy_rate: Math.round(occupancy_rate * 10) / 10,
      most_booked: mostBooked
    }
  });
});

// @desc    Get communication stats (messages)
// @route   GET /api/dashboard/communication-stats
// @access  Private/Admin
exports.getCommunicationStats = asyncHandler(async (req, res) => {
  const now = new Date();
  const start7d = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

  const [messagesTotal, messagesUnread, messagesResponded, byDay] = await Promise.all([
    Message.countDocuments({ createdAt: { $gte: start7d } }),
    Message.countDocuments({ createdAt: { $gte: start7d }, read: false }),
    Message.countDocuments({ createdAt: { $gte: start7d }, read: true }),
    Message.aggregate([
      {
        $match: {
          createdAt: { $gte: start7d }
        }
      },
      {
        $group: {
          _id: {
            $dateToString: {
              format: '%Y-%m-%d',
              date: '$createdAt'
            }
          },
          total: { $sum: 1 },
          unread: { $sum: { $cond: [{ $eq: ['$read', false] }, 1, 0] } },
          responded: { $sum: { $cond: [{ $eq: ['$read', true] }, 1, 0] } }
        }
      },
      { $sort: { _id: 1 } }
    ])
  ]);

  const responseRate = messagesTotal > 0 ? (messagesResponded / messagesTotal) * 100 : 100;

  // moyenne "temps de réponse" approximative: readAt - createdAt (en heures)
  const avgResponseAgg = await Message.aggregate([
    {
      $match: {
        createdAt: { $gte: start7d },
        read: true,
        readAt: { $exists: true, $ne: null }
      }
    },
    {
      $group: {
        _id: null,
        avgHours: {
          $avg: {
            $divide: [
              { $subtract: ['$readAt', '$createdAt'] },
              1000 * 60 * 60
            ]
          }
        }
      }
    }
  ]);

  const averageResponseTime = avgResponseAgg?.[0]?.avgHours || 0;

  const dayKeys = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(now.getTime() - (6 - i) * 24 * 60 * 60 * 1000);
    return d.toISOString().split('T')[0];
  });

  const byDayMap = byDay.reduce((acc, curr) => {
    acc[curr._id] = curr;
    return acc;
  }, {});

  const messagesByDay = dayKeys.map((k) => {
    const d = byDayMap[k] || { total: 0, unread: 0, responded: 0 };
    return { date: k, total: d.total, unread: d.unread, responded: d.responded };
  });

  const tickets = {
    total: 0,
    open: 0,
    resolved: 0,
    pending: 0,
    averageResolutionTime: 0,
    byType: [
      { type: 'Support', total: 0, resolved: 0, pending: 0 },
      { type: 'Technique', total: 0, resolved: 0, pending: 0 },
      { type: 'Commercial', total: 0, resolved: 0, pending: 0 }
    ]
  };

  res.status(200).json({
    success: true,
    data: {
      messages: {
        total: messagesTotal,
        unread: messagesUnread,
        responseRate: Math.round(responseRate * 10) / 10,
        byDay: messagesByDay
      },
      tickets
    }
  });
});

// @desc    Revenue analytics (revenus + répartitions)
// @route   GET /api/dashboard/revenue-analytics
// @access  Private/Admin
exports.getRevenueAnalytics = asyncHandler(async (req, res) => {
  const timeframe = req.query.timeframe || 'month';
  const startDate = safeDate(req.query.startDate);
  const endDate = safeDate(req.query.endDate);

  const end = endDate || new Date();
  const start = startDate || new Date(end.getTime() - parseTimeframeToDays(timeframe) * 24 * 60 * 60 * 1000);

  // Longueur de la période pour calculer la croissance
  const periodMs = end.getTime() - start.getTime();
  const prevEnd = new Date(start.getTime());
  const prevStart = new Date(prevEnd.getTime() - periodMs);

  const completedReservationsAgg = await Reservation.aggregate([
    {
      $match: {
        createdAt: { $gte: start, $lte: end },
        status: 'completed'
      }
    },
    {
      $lookup: {
        from: 'residences',
        localField: 'residence',
        foreignField: '_id',
        as: 'residenceDoc'
      }
    },
    { $unwind: '$residenceDoc' },
    {
      $match: {
        'residenceDoc.deleted': { $ne: true }
      }
    }
  ]);

  const totalBookings = completedReservationsAgg.length;
  const totalRevenue = completedReservationsAgg.reduce((sum, r) => sum + (r.totalPrice || 0), 0);
  const averageRevenue = totalBookings > 0 ? totalRevenue / totalBookings : 0;

  // Revenu précédent pour growth
  const prevRevenueAgg = await Reservation.aggregate([
    {
      $match: {
        createdAt: { $gte: prevStart, $lte: prevEnd },
        status: 'completed'
      }
    },
    {
      $group: {
        _id: null,
        revenue: { $sum: '$totalPrice' }
      }
    }
  ]);
  const prevRevenue = prevRevenueAgg?.[0]?.revenue || 0;
  const growth = prevRevenue > 0 ? ((totalRevenue - prevRevenue) / prevRevenue) * 100 : 0;

  // revenueByResidenceType (pie)
  const revenueByResidenceType = Object.values(
    completedReservationsAgg.reduce((acc, r) => {
      const type = r.residenceDoc?.type || 'other';
      if (!acc[type]) {
        acc[type] = { type, revenue: 0, bookings: 0, hasPool: 0 };
      }
      acc[type].revenue += r.totalPrice || 0;
      acc[type].bookings += 1;
      if ((r.residenceDoc?.amenities || []).includes('pool')) acc[type].hasPool += 1;
      return acc;
    }, {})
  );

  // revenueByPeriod (line) - on regroupe par mois si timeframe est month/quarter/year sinon par semaine/jour
  const groupKey =
    timeframe === 'week'
      ? { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } }
      : { $dateToString: { format: '%b %Y', date: '$createdAt' } };

  const revenueByPeriodAgg = await Reservation.aggregate([
    {
      $match: {
        createdAt: { $gte: start, $lte: end },
        status: 'completed'
      }
    },
    {
      $group: {
        _id: groupKey,
        revenue: { $sum: '$totalPrice' },
        bookings: { $sum: 1 }
      }
    },
    { $sort: { _id: 1 } }
  ]);

  const revenueByPeriod = revenueByPeriodAgg.map((p) => ({
    period: p._id,
    revenue: p.revenue || 0,
    target: (p.revenue || 0) * 1.05
  }));

  // revenueByPaymentMethod (bar) - basé sur Payment
  const revenueByPaymentMethodAgg = await Payment.aggregate([
    {
      $match: {
        status: 'paid',
        createdAt: { $gte: start, $lte: end }
      }
    },
    {
      $group: {
        _id: '$paymentMethod',
        amount: { $sum: '$amount' },
        count: { $sum: 1 }
      }
    },
    { $sort: { amount: -1 } }
  ]);

  const revenueByPaymentMethod = revenueByPaymentMethodAgg.map((m) => ({
    method: m._id,
    amount: m.amount || 0,
    count: m.count || 0
  }));

  // revenueByResidence (bar)
  const revenueByResidenceAgg = await Reservation.aggregate([
    {
      $match: {
        createdAt: { $gte: start, $lte: end },
        status: 'completed'
      }
    },
    {
      $group: {
        _id: '$residence',
        revenue: { $sum: '$totalPrice' },
        bookings: { $sum: 1 }
      }
    },
    { $sort: { revenue: -1 } },
    { $limit: 8 },
    {
      $lookup: {
        from: 'residences',
        localField: '_id',
        foreignField: '_id',
        as: 'residenceDoc'
      }
    },
    { $unwind: { path: '$residenceDoc', preserveNullAndEmptyArrays: true } },
    {
      $project: {
        name: '$residenceDoc.title',
        revenue: 1
      }
    }
  ]);

  const revenueByResidence = revenueByResidenceAgg.map((r) => ({
    name: r.name || 'Inconnu',
    revenue: r.revenue || 0
  }));

  res.status(200).json({
    success: true,
    data: {
      totalRevenue,
      growth: Math.round(growth * 10) / 10,
      averageRevenue,
      totalBookings,
      revenueByResidenceType,
      revenueByPeriod,
      revenueByPaymentMethod,
      revenueByResidence
    }
  });
});

// @desc    Reports (occupation / revenue / performance)
// @route   GET /api/dashboard/reports
// @access  Private/Admin
exports.getReports = asyncHandler(async (req, res) => {
  const reportType = req.query.type || 'occupancy';
  const startDate = safeDate(req.query.startDate);
  const endDate = safeDate(req.query.endDate);

  const end = endDate || new Date();
  const start = startDate || new Date(end.getTime() - 30 * 24 * 60 * 60 * 1000);

  if (reportType === 'occupancy') {
    const residences = await Residence.find({ deleted: { $ne: true } })
      .select('_id title images price type amenities stars')
      .lean();

    const VACATION_TYPES = new Set([
      'hotel',
      'hotel_passage',
      'motel',
      'boutique_hotel',
      'hotel_luxe',
      'guest_house',
      'residence_hoteliere',
      'bungalow',
      'lodge',
      'case_traditionnelle',
      'maison_flottante',
      'campement_touristique'
    ]);

    const bookingAgg = await Reservation.aggregate([
      {
        $match: {
          createdAt: { $gte: start, $lte: end },
          residence: { $in: residences.map((r) => r._id) },
          status: { $in: ['pending', 'confirmed', 'completed', 'in_stay'] }
        }
      },
      {
        $group: {
          _id: '$residence',
          totalBookings: { $sum: 1 },
          completedBookings: { $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] } }
        }
      }
    ]);

    const byResidence = bookingAgg.reduce((acc, curr) => {
      acc[String(curr._id)] = curr;
      return acc;
    }, {});

    const occupancyByResidence = residences.map((r) => {
      const b = byResidence[String(r._id)] || { totalBookings: 0, completedBookings: 0 };
      const totalBookings = Number(b.totalBookings || 0);
      const completedBookings = Number(b.completedBookings || 0);
      const occupancyRate = totalBookings > 0 ? (completedBookings / totalBookings) * 100 : 0;

      return {
        residenceId: r._id,
        residenceName: r.title,
        occupancyRate,
        totalBookings,
        completedBookings,
        isVacationResidence: VACATION_TYPES.has(r.type),
        isSpecialResidence: (r.stars || 0) >= 4
      };
    });

    return res.status(200).json({
      success: true,
      data: { occupancyByResidence }
    });
  }

  if (reportType === 'revenue') {
    const totalRevenueAgg = await Reservation.aggregate([
      {
        $match: { createdAt: { $gte: start, $lte: end }, status: 'completed' }
      },
      {
        $group: { _id: null, totalRevenue: { $sum: '$totalPrice' } }
      }
    ]);
    const totalRevenue = totalRevenueAgg?.[0]?.totalRevenue || 0;

    const revenueByPaymentMethodAgg = await Payment.aggregate([
      {
        $match: { status: 'paid', createdAt: { $gte: start, $lte: end } }
      },
      {
        $group: {
          _id: '$paymentMethod',
          amount: { $sum: '$amount' },
          count: { $sum: 1 }
        }
      },
      { $sort: { amount: -1 } }
    ]);

    const revenueByPaymentMethod = revenueByPaymentMethodAgg.map((m) => ({
      method: m._id,
      amount: m.amount || 0,
      count: m.count || 0
    }));

    // revenueByPeriod: mois
    const startMonth = new Date(start);
    startMonth.setDate(1);

    const revenueByPeriodAgg = await Reservation.aggregate([
      {
        $match: { createdAt: { $gte: start, $lte: end }, status: 'completed' }
      },
      {
        $group: {
          _id: { $dateToString: { format: '%b %Y', date: '$createdAt' } },
          revenue: { $sum: '$totalPrice' }
        }
      },
      { $sort: { _id: 1 } }
    ]);

    const revenueByPeriod = revenueByPeriodAgg.map((p) => ({
      period: p._id,
      revenue: p.revenue || 0,
      target: (p.revenue || 0) * 1.05
    }));

    return res.status(200).json({
      success: true,
      data: { totalRevenue, revenueByPaymentMethod, revenueByPeriod }
    });
  }

  // reportType === 'performance'
  const bookingAggPeriod = await Reservation.aggregate([
    {
      $match: {
        createdAt: { $gte: start, $lte: end },
        status: { $in: ['pending', 'confirmed', 'completed', 'cancelled', 'refunded'] }
      }
    },
    {
      $group: {
        _id: { $dateToString: { format: '%b %Y', date: '$createdAt' } },
        totalBookings: { $sum: 1 },
        completedBookings: { $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] } },
        confirmedBookings: { $sum: { $cond: [{ $eq: ['$status', 'confirmed'] }, 1, 0] } }
      }
    },
    { $sort: { _id: 1 } }
  ]);

  const performanceByPeriod = bookingAggPeriod.map((p) => {
    const conversionRate = p.totalBookings > 0 ? ((p.confirmedBookings + p.completedBookings) / p.totalBookings) * 100 : 0;
    return {
      period: p._id,
      conversionRate: Math.round(conversionRate * 10) / 10,
      completedBookings: p.completedBookings || 0
    };
  });

  const totalBookingsAll = bookingAggPeriod.reduce((sum, p) => sum + (p.totalBookings || 0), 0);
  const totalCompletedAll = bookingAggPeriod.reduce((sum, p) => sum + (p.completedBookings || 0), 0);
  const totalConfirmedAll = bookingAggPeriod.reduce((sum, p) => sum + (p.confirmedBookings || 0), 0);

  const conversionRateAll = totalBookingsAll > 0 ? ((totalConfirmedAll + totalCompletedAll) / totalBookingsAll) * 100 : 0;

  res.status(200).json({
    success: true,
    data: {
      conversionRate: Math.round(conversionRateAll * 10) / 10,
      performanceByPeriod
    }
  });
});
