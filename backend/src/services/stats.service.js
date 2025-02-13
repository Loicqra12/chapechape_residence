const Residence = require('../models/residence.model');
const Reservation = require('../models/reservation.model');
const User = require('../models/user.model');
const Payment = require('../models/payment.model');
const mongoose = require('mongoose');

class StatsService {
    // Obtenir les résidences les plus vues
    async getMostViewedResidences(limit = 10) {
        return await Residence.find()
            .sort({ viewCount: -1 })
            .limit(limit)
            .select('title location price viewCount images');
    }

    // Obtenir les résidences les plus réservées
    async getMostBookedResidences(limit = 10) {
        const reservations = await Reservation.aggregate([
            {
                $group: {
                    _id: '$residence',
                    bookingCount: { $sum: 1 },
                    totalRevenue: { $sum: '$totalPrice' }
                }
            },
            { $sort: { bookingCount: -1 } },
            { $limit: limit },
            {
                $lookup: {
                    from: 'residences',
                    localField: '_id',
                    foreignField: '_id',
                    as: 'residenceDetails'
                }
            },
            { $unwind: '$residenceDetails' }
        ]);

        return reservations;
    }

    // Obtenir les revenus globaux
    async getGlobalRevenue(startDate, endDate) {
        const query = {
            status: 'completed',
            createdAt: {}
        };

        if (startDate) query.createdAt.$gte = new Date(startDate);
        if (endDate) query.createdAt.$lte = new Date(endDate);

        const revenue = await Payment.aggregate([
            { $match: query },
            {
                $group: {
                    _id: null,
                    totalRevenue: { $sum: '$amount' },
                    count: { $sum: 1 }
                }
            }
        ]);

        return revenue[0] || { totalRevenue: 0, count: 0 };
    }

    // Obtenir les statistiques du partenaire
    async getPartnerStats(partnerId) {
        // Convertir partnerId en ObjectId si ce n'est pas déjà fait
        const partnerObjectId = typeof partnerId === 'string' ? new mongoose.Types.ObjectId(partnerId) : partnerId;

        const [residences, bookings, revenue] = await Promise.all([
            Residence.countDocuments({ partner: partnerObjectId }),
            Reservation.countDocuments({
                residence: { $in: await Residence.find({ partner: partnerObjectId }).distinct('_id') },
                status: 'completed'
            }),
            Payment.aggregate([
                {
                    $match: {
                        partner: partnerObjectId,
                        status: 'completed'
                    }
                },
                {
                    $group: {
                        _id: null,
                        total: { $sum: '$amount' }
                    }
                }
            ])
        ]);

        return {
            totalResidences: residences,
            totalBookings: bookings,
            totalRevenue: revenue[0]?.total || 0
        };
    }

    // Obtenir les tendances des réservations
    async getTrends(partnerId, period = 'monthly', startDate, endDate) {
        const start = startDate ? new Date(startDate) : new Date(new Date().setMonth(new Date().getMonth() - 12));
        const end = endDate ? new Date(endDate) : new Date();

        // Convertir partnerId en ObjectId si ce n'est pas déjà fait
        const partnerObjectId = typeof partnerId === 'string' ? new mongoose.Types.ObjectId(partnerId) : partnerId;

        const residenceIds = await Residence.find({ partner: partnerObjectId }).distinct('_id');

        const groupBy = {
            monthly: {
                year: { $year: '$createdAt' },
                month: { $month: '$createdAt' }
            },
            weekly: {
                year: { $year: '$createdAt' },
                week: { $week: '$createdAt' }
            },
            daily: {
                year: { $year: '$createdAt' },
                month: { $month: '$createdAt' },
                day: { $dayOfMonth: '$createdAt' }
            }
        };

        const trends = await Reservation.aggregate([
            {
                $match: {
                    residence: { $in: residenceIds },
                    createdAt: { $gte: start, $lte: end },
                    status: 'completed'
                }
            },
            {
                $group: {
                    _id: groupBy[period],
                    bookings: { $sum: 1 },
                    revenue: { $sum: '$totalPrice' }
                }
            },
            {
                $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 }
            }
        ]);

        return {
            period,
            data: trends.map(t => ({
                date: this._formatTrendDate(t._id, period),
                bookings: t.bookings,
                revenue: t.revenue
            }))
        };
    }

    // Formater la date pour les tendances
    _formatTrendDate(dateGroup, period) {
        const year = dateGroup.year;
        const month = dateGroup.month;
        const day = dateGroup.day;

        switch (period) {
            case 'monthly':
                return `${year}-${month.toString().padStart(2, '0')}`;
            case 'weekly':
                return `${year}-W${dateGroup.week.toString().padStart(2, '0')}`;
            case 'daily':
                return `${year}-${month.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}`;
            default:
                return '';
        }
    }

    // Obtenir les statistiques globales pour l'admin
    async getAdminStats() {
        const [totalUsers, totalResidences, reservationStats, paymentStats] = await Promise.all([
            User.countDocuments({ role: 'user' }),
            Residence.countDocuments(),
            Reservation.aggregate([
                {
                    $group: {
                        _id: null,
                        count: { $sum: 1 }
                    }
                }
            ]),
            Payment.aggregate([
                {
                    $match: { status: 'completed' }
                },
                {
                    $group: {
                        _id: null,
                        total: { $sum: '$amount' }
                    }
                }
            ])
        ]);

        return {
            totalUsers,
            totalResidences,
            totalReservations: reservationStats[0]?.count || 0,
            totalRevenue: paymentStats[0]?.total || 0,
            totalPayments: paymentStats[0]?.count || 0
        };
    }

    // Obtenir les statistiques d'une résidence
    async getResidenceStats(residenceId, startDate, endDate) {
        const start = startDate ? new Date(startDate) : new Date(new Date().setMonth(new Date().getMonth() - 1));
        const end = endDate ? new Date(endDate) : new Date();

        // Convertir residenceId en ObjectId si ce n'est pas déjà fait
        const residenceObjectId = typeof residenceId === 'string' ? new mongoose.Types.ObjectId(residenceId) : residenceId;

        const [bookings, revenue, averageStay] = await Promise.all([
            Reservation.countDocuments({
                residence: residenceObjectId,
                status: 'completed',
                createdAt: { $gte: start, $lte: end }
            }),
            Payment.aggregate([
                {
                    $match: {
                        residence: residenceObjectId,
                        status: 'completed',
                        createdAt: { $gte: start, $lte: end }
                    }
                },
                {
                    $group: {
                        _id: null,
                        total: { $sum: '$amount' }
                    }
                }
            ]),
            Reservation.aggregate([
                {
                    $match: {
                        residence: residenceObjectId,
                        status: 'completed',
                        createdAt: { $gte: start, $lte: end }
                    }
                },
                {
                    $group: {
                        _id: null,
                        averageStay: {
                            $avg: {
                                $divide: [
                                    { $subtract: ['$checkOut', '$checkIn'] },
                                    1000 * 60 * 60 * 24 // Convertir en jours
                                ]
                            }
                        }
                    }
                }
            ])
        ]);

        return {
            totalBookings: bookings,
            totalRevenue: revenue[0]?.total || 0,
            averageStayDuration: averageStay[0]?.averageStay || 0,
            period: {
                start: start.toISOString(),
                end: end.toISOString()
            }
        };
    }
}

module.exports = new StatsService();
