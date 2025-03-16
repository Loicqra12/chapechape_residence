const Residence = require('../models/residence.model');
const Booking = require('../models/booking.model');
const Review = require('../models/review.model');
const { Message, Conversation } = require('../models/message.model');

class DashboardService {
    async getOverview(partnerId) {
        try {
            // Récupérer les résidences du partenaire
            const residences = await Residence.find({ partner: partnerId });
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
            const totalBookings = await Booking.countDocuments({
                residence: { $in: residenceIds },
                status: { $in: ['confirmed', 'completed'] },
                visitDate: {
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
            const bookingStats = await Booking.aggregate([
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
            const residences = await Residence.find({ partner: partnerId });
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
            const bestPerformingResidences = await Booking.aggregate([
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
                        revenue: { $sum: '$totalAmount' },
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
            const revenueByCategory = await Booking.aggregate([
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
                        revenue: { $sum: '$totalAmount' },
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
            const residences = await Residence.find({ partner: partnerId });
            const residenceIds = residences.map(r => r._id);

            const now = new Date();
            const startOfToday = new Date(now.setHours(0, 0, 0, 0));

            // Récupérer les réservations actives
            const activeBookings = await Booking.find({
                residence: { $in: residenceIds },
                status: { $in: ['confirmed', 'pending'] },
                visitDate: { $gte: startOfToday }
            }).populate('residence', 'name imageUrl')
              .populate('client', 'name avatar')
              .sort('visitDate visitTime');

            // Récupérer les visites du jour
            const todayVisits = activeBookings.map(booking => ({
                id: booking._id,
                time: booking.visitTime,
                client: {
                    id: booking.client._id,
                    name: booking.client.name,
                    avatar: booking.client.avatar
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
            const recentBookings = await Booking.find({
                residence: { $in: residenceIds },
                createdAt: { $gte: last24Hours }
            }).populate('residence', 'name')
              .populate('client', 'name')
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
              .populate('client', 'name')
              .sort('-createdAt')
              .limit(10);

            // Combiner et trier toutes les activités récentes
            const recentActivities = [
                ...recentBookings.map(booking => ({
                    type: 'booking',
                    data: {
                        id: booking._id,
                        clientName: booking.client.name,
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
                        clientName: review.client.name,
                        residenceName: review.residence.name,
                        rating: review.rating
                    },
                    timestamp: review.createdAt
                }))
            ].sort((a, b) => b.timestamp - a.timestamp);

            // Statistiques en temps réel
            const realTimeStats = {
                active_bookings: activeBookings.length,
                pending_requests: await Booking.countDocuments({
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
        const bookings = await Booking.find({
            residence: { $in: residenceIds },
            status: 'completed',
            createdAt: { $gte: startDate }
        }).select('totalAmount');

        return bookings.reduce((sum, booking) => sum + (booking.totalAmount || 0), 0);
    }

    async calculateTotalRevenue(residenceIds) {
        const completedBookings = await Booking.find({
            residence: { $in: residenceIds },
            status: 'completed'
        }).select('totalAmount');

        return completedBookings.reduce((sum, booking) => sum + (booking.totalAmount || 0), 0);
    }

    async calculateAverageRating(residenceIds) {
        const reviews = await Review.find({
            residence: { $in: residenceIds }
        }).select('rating');

        if (reviews.length === 0) return 0;

        const totalRating = reviews.reduce((sum, review) => sum + review.rating, 0);
        return Math.round((totalRating / reviews.length) * 10) / 10;
    }
}

module.exports = new DashboardService();
