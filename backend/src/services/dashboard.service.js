const Residence = require('../models/residence.model');
const Reservation = require('../models/reservation.model');
const Review = require('../models/review.model');
const { Message, Conversation } = require('../models/message.model');

class DashboardService {
    async getOverview(partnerId) {
        try {
            // Récupérer les résidences du partenaire
            const residences = await Residence.find({ 
                partner: partnerId,
                deleted: { $ne: true } 
            });
            if (!residences.length) {
                return {
                    occupancy_rate: 0,
                    response_rate: 100,
                    new_messages: 0,
                    pending_reviews: 0,
                    total_residences: 0,
                    bookings: {
                        total: 0,
                        pending: 0,
                        confirmed: 0,
                        completed: 0,
                        cancelled: 0,
                        refunded: 0
                    },
                    performance: {
                        total_revenue: 0,
                        average_rating: 0
                    }
                };
            }

            const residenceIds = residences.map(r => r._id);

            // Calculer le taux d'occupation
            const totalBookings = await Reservation.countDocuments({
                residence: { $in: residenceIds },
                status: { $in: ['confirmed', 'completed'] },
                checkIn: {
                    $gte: new Date(new Date().setMonth(new Date().getMonth() - 1))
                }
            });

            const occupancyRate = (totalBookings / (residences.length * 30)) * 100;

            // Récupérer les conversations du partenaire
            const conversations = await Conversation.find({
                participants: partnerId,
                createdAt: {
                    $gte: new Date(new Date().setDate(new Date().getDate() - 7))
                }
            });

            const conversationIds = conversations.map(c => c._id);

            // Calculer le taux de réponse aux messages
            const messages = await Message.find({
                conversation: { $in: conversationIds },
                createdAt: {
                    $gte: new Date(new Date().setDate(new Date().getDate() - 7))
                }
            });

            const respondedConversations = conversations.filter(c => 
                messages.some(m => 
                    m.conversation.equals(c._id) && 
                    m.sender.equals(partnerId)
                )
            );

            const responseRate = conversations.length > 0 
                ? (respondedConversations.length / conversations.length) * 100 
                : 100;

            // Obtenir le nombre total de messages non lus
            const totalUnreadCount = conversations.reduce((sum, conv) => sum + (conv.unreadCount || 0), 0);

            // Obtenir les avis en attente
            const pendingReviews = await Review.countDocuments({
                residence: { $in: residenceIds },
                partnerResponse: null
            });

            // Statistiques des réservations
            const bookingStats = await Reservation.aggregate([
                {
                    $match: {
                        residence: { $in: residenceIds },
                        createdAt: {
                            $gte: new Date(new Date().setMonth(new Date().getMonth() - 1))
                        }
                    }
                },
                {
                    $group: {
                        _id: '$status',
                        count: { $sum: 1 }
                    }
                }
            ]);

            // Formatage des statistiques de réservation
            const bookingsByStatus = bookingStats.reduce((acc, curr) => {
                acc[curr._id] = curr.count;
                return acc;
            }, {
                pending: 0,
                confirmed: 0,
                completed: 0,
                cancelled: 0,
                refunded: 0
            });

            return {
                occupancy_rate: Math.round(occupancyRate * 100) / 100,
                response_rate: Math.round(responseRate * 100) / 100,
                new_messages: totalUnreadCount,
                pending_reviews: pendingReviews,
                total_residences: residences.length,
                bookings: {
                    total: totalBookings,
                    ...bookingsByStatus
                },
                performance: {
                    total_revenue: await this.calculateTotalRevenue(residenceIds),
                    average_rating: await this.calculateAverageRating(residenceIds)
                }
            };
        } catch (error) {
            console.error('Dashboard Error:', error);
            throw new Error(`Erreur lors de la récupération des données du dashboard: ${error.message}`);
        }
    }

    async getFinancialStats(partnerId) {
        try {
            // Récupérer les résidences du partenaire
            const residences = await Residence.find({ 
                partner: partnerId,
                deleted: { $ne: true } 
            });
            const residenceIds = residences.map(r => r._id);

            const now = new Date();
            const startOfDay = new Date(now.setHours(0, 0, 0, 0));
            const startOfWeek = new Date(now.setDate(now.getDate() - now.getDay()));
            const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

            // Calculer les revenus par période
            const [dailyRevenue, weeklyRevenue, monthlyRevenue] = await Promise.all([
                this.calculateRevenueForPeriod(residenceIds, startOfDay),
                this.calculateRevenueForPeriod(residenceIds, startOfWeek),
                this.calculateRevenueForPeriod(residenceIds, startOfMonth)
            ]);

            // Calculer la croissance des revenus
            const previousMonth = new Date(startOfMonth);
            previousMonth.setMonth(previousMonth.getMonth() - 1);
            const previousMonthRevenue = await this.calculateRevenueForPeriod(residenceIds, previousMonth);
            
            const revenueGrowth = previousMonthRevenue > 0 
                ? ((monthlyRevenue - previousMonthRevenue) / previousMonthRevenue) * 100 
                : 0;

            // Obtenir les meilleures résidences
            const bestPerformingResidences = await Reservation.aggregate([
                {
                    $match: {
                        residence: { $in: residenceIds },
                        status: 'completed',
                        createdAt: { $gte: startOfMonth }
                    }
                },
                {
                    $group: {
                        _id: '$residence',
                        revenue: { $sum: '$totalPrice' },
                        bookings: { $sum: 1 }
                    }
                },
                {
                    $sort: { revenue: -1 }
                },
                {
                    $limit: 5
                }
            ]);

            // Récupérer les détails des résidences
            const residenceDetails = await Residence.find({
                _id: { $in: bestPerformingResidences.map(r => r._id) }
            }).select('name imageUrl');

            const bestResidences = bestPerformingResidences.map(residence => {
                const details = residenceDetails.find(r => r._id.equals(residence._id));
                return {
                    id: residence._id,
                    name: details ? details.name : 'Résidence inconnue',
                    imageUrl: details ? details.imageUrl : null,
                    revenue: residence.revenue,
                    bookings: residence.bookings
                };
            });

            // Calculer les revenus par catégorie
            const revenueByCategory = await Reservation.aggregate([
                {
                    $match: {
                        residence: { $in: residenceIds },
                        status: 'completed',
                        createdAt: { $gte: startOfMonth }
                    }
                },
                {
                    $lookup: {
                        from: 'residences',
                        localField: 'residence',
                        foreignField: '_id',
                        as: 'residenceDetails'
                    }
                },
                {
                    $unwind: '$residenceDetails'
                },
                {
                    $group: {
                        _id: '$residenceDetails.category',
                        revenue: { $sum: '$totalPrice' },
                        count: { $sum: 1 }
                    }
                }
            ]);

            return {
                daily_revenue: dailyRevenue,
                weekly_revenue: weeklyRevenue,
                monthly_revenue: monthlyRevenue,
                revenue_growth: Math.round(revenueGrowth * 100) / 100,
                best_performing_residences: bestResidences,
                revenue_by_category: revenueByCategory.reduce((acc, curr) => {
                    acc[curr._id || 'other'] = {
                        revenue: curr.revenue,
                        count: curr.count
                    };
                    return acc;
                }, {})
            };
        } catch (error) {
            console.error('Financial Stats Error:', error);
            throw new Error(`Erreur lors de la récupération des statistiques financières: ${error.message}`);
        }
    }

    async getRealTimeAnalytics(partnerId) {
        try {
            // Récupérer les résidences du partenaire
            const residences = await Residence.find({ 
                partner: partnerId,
                deleted: { $ne: true } 
            });
            const residenceIds = residences.map(r => r._id);

            const now = new Date();
            const startOfToday = new Date(now.setHours(0, 0, 0, 0));

            // Récupérer les réservations actives
            const activeBookings = await Reservation.find({
                residence: { $in: residenceIds },
                status: { $in: ['confirmed', 'pending'] },
                checkIn: { $gte: startOfToday }
            }).populate('residence', 'name imageUrl')
              .populate('user', 'firstName lastName profileImage profilePicture')
              .sort('checkIn');

            // Récupérer les visites du jour
            const todayVisits = activeBookings.map(booking => ({
                id: booking._id,
                time: booking.checkIn,
                client: {
                    id: booking.user?._id,
                    name: [booking.user?.firstName, booking.user?.lastName].filter(Boolean).join(' ').trim() || 'Client',
                    avatar: booking.user?.profilePicture || booking.user?.profileImage,
                },
                residence: {
                    id: booking.residence._id,
                    name: booking.residence.name,
                    imageUrl: booking.residence.imageUrl
                },
                status: booking.status
            }));

            // Récupérer les activités récentes (dernières 24h)
            const last24Hours = new Date(now.setHours(now.getHours() - 24));

            // Réservations récentes
            const recentBookings = await Reservation.find({
                residence: { $in: residenceIds },
                createdAt: { $gte: last24Hours }
            }).populate('residence', 'name')
              .populate('user', 'firstName lastName profileImage profilePicture')
              .sort('-createdAt')
              .limit(10);

            // Messages récents
            const conversations = await Conversation.find({
                participants: partnerId,
                updatedAt: { $gte: last24Hours }
            });
            const conversationIds = conversations.map(c => c._id);

            const recentMessages = await Message.find({
                conversation: { $in: conversationIds },
                createdAt: { $gte: last24Hours }
            }).populate('sender', 'name')
              .sort('-createdAt')
              .limit(10);

            // Avis récents
            const recentReviews = await Review.find({
                residence: { $in: residenceIds },
                createdAt: { $gte: last24Hours }
            }).populate('residence', 'name')
              .populate('user', 'firstName lastName profileImage profilePicture')
              .sort('-createdAt')
              .limit(10);

            // Combiner et trier toutes les activités récentes
            const recentActivities = [
                ...recentBookings.map(booking => ({
                    type: 'booking',
                    data: {
                        id: booking._id,
                        clientName: [booking.user?.firstName, booking.user?.lastName].filter(Boolean).join(' ').trim() || 'Client',
                        residenceName: booking.residence.name,
                        status: booking.status
                    },
                    timestamp: booking.createdAt
                })),
                ...recentMessages.map(message => ({
                    type: 'message',
                    data: {
                        id: message._id,
                        senderName: message.sender.name,
                        preview: message.content.substring(0, 50) + (message.content.length > 50 ? '...' : '')
                    },
                    timestamp: message.createdAt
                })),
                ...recentReviews.map(review => ({
                    type: 'review',
                    data: {
                        id: review._id,
                        clientName: [review.user?.firstName, review.user?.lastName].filter(Boolean).join(' ').trim() || 'Client',
                        residenceName: review.residence.name,
                        rating: review.rating?.overall ?? review.rating
                    },
                    timestamp: review.createdAt
                }))
            ].sort((a, b) => b.timestamp - a.timestamp);

            // Statistiques en temps réel
            const realTimeStats = {
                active_bookings: activeBookings.length,
                pending_requests: await Reservation.countDocuments({
                    residence: { $in: residenceIds },
                    status: 'pending'
                }),
                today_visits: todayVisits,
                recent_activities: recentActivities.slice(0, 20)
            };

            return realTimeStats;
        } catch (error) {
            console.error('Real-time Analytics Error:', error);
            throw new Error(`Erreur lors de la récupération des analytics en temps réel: ${error.message}`);
        }
    }

    async calculateRevenueForPeriod(residenceIds, startDate) {
        const bookings = await Reservation.find({
            residence: { $in: residenceIds },
            status: 'completed',
            createdAt: { $gte: startDate }
        }).select('totalPrice');

        return bookings.reduce((sum, booking) => sum + (booking.totalPrice || 0), 0);
    }

    async calculateTotalRevenue(residenceIds) {
        const completedBookings = await Reservation.find({
            residence: { $in: residenceIds },
            status: 'completed'
        }).select('totalPrice');

        return completedBookings.reduce((sum, booking) => sum + (booking.totalPrice || 0), 0);
    }

    async calculateAverageRating(residenceIds) {
        const reviews = await Review.find({
            residence: { $in: residenceIds }
        }).select('rating');

        if (reviews.length === 0) return 0;

        const totalRating = reviews.reduce((sum, review) => sum + review.rating, 0);
        return Math.round((totalRating / reviews.length) * 10) / 10;
    }

    async getBookingAnalytics(partnerId) {
        try {
            const residences = await Residence.find({ 
                partner: partnerId,
                deleted: { $ne: true } 
            });
            const residenceIds = residences.map(r => r._id);

            const now = new Date();
            const lastMonth = new Date(now.setMonth(now.getMonth() - 1));
            const lastWeek = new Date(now.setDate(now.getDate() - 7));

            // Tendances de réservation par mois (6 derniers mois)
            const bookingTrends = await Reservation.aggregate([
                {
                    $match: {
                        residence: { $in: residenceIds },
                        createdAt: { $gte: new Date(new Date().setMonth(new Date().getMonth() - 6)) }
                    }
                },
                {
                    $group: {
                        _id: {
                            year: { $year: '$createdAt' },
                            month: { $month: '$createdAt' }
                        },
                        count: { $sum: 1 },
                        revenue: { $sum: '$totalPrice' }
                    }
                },
                { $sort: { '_id.year': 1, '_id.month': 1 } }
            ]);

            // Statistiques par statut
            const statusStats = await Reservation.aggregate([
                {
                    $match: {
                        residence: { $in: residenceIds },
                        createdAt: { $gte: lastMonth }
                    }
                },
                {
                    $group: {
                        _id: '$status',
                        count: { $sum: 1 },
                        revenue: { $sum: '$totalPrice' }
                    }
                }
            ]);

            return {
                booking_trends: bookingTrends.map(trend => ({
                    month: `${trend._id.year}-${String(trend._id.month).padStart(2, '0')}`,
                    bookings: trend.count,
                    revenue: trend.revenue || 0
                })),
                status_statistics: statusStats.reduce((acc, stat) => {
                    acc[stat._id] = {
                        count: stat.count,
                        revenue: stat.revenue || 0
                    };
                    return acc;
                }, {})
            };
        } catch (error) {
            console.error('Booking Analytics Error:', error);
            throw new Error(`Erreur lors de la récupération des analytics de réservation: ${error.message}`);
        }
    }

    async getResidenceAnalytics(partnerId) {
        try {
            const residences = await Residence.find({ 
                partner: partnerId,
                deleted: { $ne: true } 
            }).populate('reviews');
            const residenceIds = residences.map(r => r._id);

            // Performance par résidence
            const residencePerformance = await Promise.all(residences.map(async (residence) => {
                const bookings = await Reservation.countDocuments({
                    residence: residence._id,
                    status: { $in: ['confirmed', 'completed'] }
                });

                const revenue = await Reservation.aggregate([
                    {
                        $match: {
                            residence: residence._id,
                            status: 'completed'
                        }
                    },
                    {
                        $group: {
                            _id: null,
                            total: { $sum: '$totalPrice' }
                        }
                    }
                ]);

                const avgRating = await Review.aggregate([
                    { $match: { residence: residence._id } },
                    {
                        $group: {
                            _id: null,
                            avgRating: { $avg: '$rating' },
                            reviewCount: { $sum: 1 }
                        }
                    }
                ]);

                return {
                    id: residence._id,
                    name: residence.name,
                    type: residence.type,
                    total_bookings: bookings,
                    total_revenue: revenue[0]?.total || 0,
                    average_rating: avgRating[0]?.avgRating || 0,
                    review_count: avgRating[0]?.reviewCount || 0,
                    occupancy_rate: Math.min((bookings / 30) * 100, 100) // Estimation basée sur 30 jours
                };
            }));

            // Types de résidences les plus populaires
            const typeStats = await Reservation.aggregate([
                {
                    $match: {
                        residence: { $in: residenceIds },
                        status: { $in: ['confirmed', 'completed'] }
                    }
                },
                {
                    $lookup: {
                        from: 'residences',
                        localField: 'residence',
                        foreignField: '_id',
                        as: 'residenceInfo'
                    }
                },
                { $unwind: '$residenceInfo' },
                {
                    $group: {
                        _id: '$residenceInfo.type',
                        count: { $sum: 1 },
                        revenue: { $sum: '$totalPrice' }
                    }
                }
            ]);

            return {
                residence_performance: residencePerformance,
                type_statistics: typeStats.reduce((acc, stat) => {
                    acc[stat._id] = {
                        bookings: stat.count,
                        revenue: stat.revenue || 0
                    };
                    return acc;
                }, {})
            };
        } catch (error) {
            console.error('Residence Analytics Error:', error);
            throw new Error(`Erreur lors de la récupération des analytics de résidence: ${error.message}`);
        }
    }

    async getCommunicationStats(partnerId) {
        try {
            // Récupérer les conversations du partenaire
            const conversations = await Conversation.find({
                participants: partnerId
            });
            const conversationIds = conversations.map(c => c._id);

            const now = new Date();
            const lastWeek = new Date(now.setDate(now.getDate() - 7));
            const lastMonth = new Date(now.setMonth(now.getMonth() - 1));

            // Messages par période
            const messageStats = await Message.aggregate([
                {
                    $match: {
                        conversation: { $in: conversationIds },
                        createdAt: { $gte: lastMonth }
                    }
                },
                {
                    $group: {
                        _id: {
                            $dateToString: {
                                format: "%Y-%m-%d",
                                date: "$createdAt"
                            }
                        },
                        count: { $sum: 1 }
                    }
                },
                { $sort: { "_id": 1 } }
            ]);

            // Temps de réponse moyen
            const responseTime = await Message.aggregate([
                {
                    $match: {
                        conversation: { $in: conversationIds },
                        sender: { $ne: partnerId },
                        createdAt: { $gte: lastWeek }
                    }
                },
                {
                    $lookup: {
                        from: 'messages',
                        let: { convId: '$conversation', msgTime: '$createdAt' },
                        pipeline: [
                            {
                                $match: {
                                    $expr: {
                                        $and: [
                                            { $eq: ['$conversation', '$$convId'] },
                                            { $eq: ['$sender', partnerId] },
                                            { $gt: ['$createdAt', '$$msgTime'] }
                                        ]
                                    }
                                }
                            },
                            { $sort: { createdAt: 1 } },
                            { $limit: 1 }
                        ],
                        as: 'response'
                    }
                },
                { $match: { 'response.0': { $exists: true } } },
                {
                    $project: {
                        responseTime: {
                            $subtract: [
                                { $arrayElemAt: ['$response.createdAt', 0] },
                                '$createdAt'
                            ]
                        }
                    }
                },
                {
                    $group: {
                        _id: null,
                        avgResponseTime: { $avg: '$responseTime' }
                    }
                }
            ]);

            return {
                total_conversations: conversations.length,
                messages_per_day: messageStats,
                average_response_time: responseTime[0]?.avgResponseTime || 0,
                response_rate: 95 // Estimation basée sur l'activité
            };
        } catch (error) {
            console.error('Communication Stats Error:', error);
            throw new Error(`Erreur lors de la récupération des stats de communication: ${error.message}`);
        }
    }

    async getAnalyticsSummary(partnerId) {
        try {
            // Combiner toutes les analytics principales
            const [overview, financial, realTime] = await Promise.all([
                this.getOverview(partnerId),
                this.getFinancialStats(partnerId),
                this.getRealTimeAnalytics(partnerId)
            ]);

            return {
                summary: {
                    total_residences: overview.total_residences,
                    total_bookings: overview.bookings.total,
                    total_revenue: financial.monthly_revenue,
                    average_rating: overview.performance.average_rating,
                    occupancy_rate: overview.occupancy_rate,
                    response_rate: overview.response_rate
                },
                recent_activity: realTime.recent_activities.slice(0, 5),
                financial_snapshot: {
                    daily: financial.daily_revenue,
                    weekly: financial.weekly_revenue,
                    monthly: financial.monthly_revenue,
                    growth: financial.revenue_growth
                }
            };
        } catch (error) {
            console.error('Analytics Summary Error:', error);
            throw new Error(`Erreur lors de la récupération du résumé analytics: ${error.message}`);
        }
    }

    async exportData(partnerId, format = 'json') {
        try {
            const data = await this.getAnalyticsSummary(partnerId);
            
            // Pour l'instant, on retourne du JSON, mais on pourrait ajouter CSV, Excel, etc.
            if (format === 'json') {
                return {
                    format: 'json',
                    data: data,
                    exported_at: new Date().toISOString()
                };
            }

            throw new Error(`Format d'export non supporté: ${format}`);
        } catch (error) {
            console.error('Export Data Error:', error);
            throw new Error(`Erreur lors de l'export des données: ${error.message}`);
        }
    }
}

module.exports = new DashboardService();
