import axios from 'axios';
import { API_URL } from '../config';

class AnalyticsService {
  async getCommunicationStats() {
    try {
      // Mock data pour la communication
      const mockData = {
        messages: {
          total: 150,
          unread: 25,
          responseRate: 85,
          byDay: Array(7).fill(null).map((_, i) => ({
            date: new Date(Date.now() - i * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
            total: Math.floor(Math.random() * 20),
            unread: Math.floor(Math.random() * 10),
            responded: Math.floor(Math.random() * 15)
          }))
        },
        tickets: {
          total: 75,
          open: 15,
          resolved: 55,
          pending: 5,
          averageResolutionTime: 24,
          byType: [
            { type: 'Support', total: 30, resolved: 25, pending: 5 },
            { type: 'Technique', total: 25, resolved: 20, pending: 5 },
            { type: 'Commercial', total: 20, resolved: 10, pending: 10 }
          ]
        }
      };

      return {
        success: true,
        data: mockData
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des statistiques de communication'
      };
    }
  }

  async getResidenceStats() {
    try {
      // Mock data pour les résidences
      const mockResidences = [
        {
          _id: '1',
          name: 'Villa Bord de Mer',
          images: ['villa1.jpg'],
          isAvailable: true,
          amenities: ['pool', 'wifi', 'parking'],
          type: 'vacation',
          isSpecial: false,
          location: { city: 'Cannes', country: 'France' }
        },
        {
          _id: '2',
          name: 'Appartement Centre-Ville',
          images: ['apt1.jpg'],
          isAvailable: true,
          amenities: ['wifi', 'parking'],
          type: 'standard',
          isSpecial: false,
          location: { city: 'Paris', country: 'France' }
        },
        {
          _id: '3',
          name: 'Chalet de Luxe',
          images: ['chalet1.jpg'],
          isAvailable: false,
          amenities: ['pool', 'wifi', 'parking', 'spa'],
          type: 'vacation',
          isSpecial: true,
          location: { city: 'Megève', country: 'France' }
        }
      ];

      const mockBookings = [
        {
          _id: 'b1',
          residence: '1',
          status: 'completed',
          visitDate: '2025-03-01',
          duration: 7
        },
        {
          _id: 'b2',
          residence: '1',
          status: 'confirmed',
          visitDate: '2025-03-15',
          duration: 5
        },
        {
          _id: 'b3',
          residence: '2',
          status: 'pending',
          visitDate: '2025-03-20',
          duration: 3
        }
      ];

      // Calculer les statistiques des résidences
      const total = mockResidences.length;
      const available = mockResidences.filter(r => r.isAvailable).length;
      const withPool = mockResidences.filter(r => r.amenities?.includes('pool')).length;
      const vacation = mockResidences.filter(r => r.type === 'vacation').length;
      const special = mockResidences.filter(r => r.isSpecial).length;

      // Calculer le taux d'occupation par résidence
      const residenceOccupancy = mockResidences.map(residence => {
        const residenceBookings = mockBookings.filter(b => b.residence === residence._id);
        const completedBookings = residenceBookings.filter(b => b.status === 'completed').length;
        const occupancyRate = residenceBookings.length > 0
          ? (completedBookings / residenceBookings.length) * 100
          : 0;

        return {
          _id: residence._id,
          title: residence.name,
          imageUrl: residence.images?.[0] || '',
          displayAddress: `${residence.location.city}, ${residence.location.country}`,
          status: residence.isAvailable ? 'available' : 'unavailable',
          hasPool: residence.amenities?.includes('pool'),
          isVacationResidence: residence.type === 'vacation',
          isSpecialResidence: residence.isSpecial,
          occupancyRate,
          totalBookings: residenceBookings.length,
          completedBookings,
        };
      });

      // Trier par taux d'occupation
      const mostBooked = residenceOccupancy
        .sort((a, b) => b.occupancyRate - a.occupancyRate)
        .slice(0, 5);

      // Calculer le taux d'occupation global
      const occupancy_rate = residenceOccupancy.reduce((sum, r) => sum + r.occupancyRate, 0) / total;

      return {
        success: true,
        data: {
          total,
          available,
          withPool,
          vacation,
          special,
          occupancy_rate,
          most_booked: mostBooked,
        }
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des statistiques des résidences'
      };
    }
  }

  async getPerformanceMetrics(filters = {}) {
    try {
      // Mock data pour les réservations
      const mockBookings = [
        { status: 'pending', totalAmount: 1200, visitDate: '2025-03-01', duration: 5 },
        { status: 'confirmed', totalAmount: 2500, visitDate: '2025-03-05', duration: 7 },
        { status: 'completed', totalAmount: 1800, visitDate: '2025-02-28', duration: 4 },
        { status: 'cancelled', totalAmount: 0, visitDate: '2025-03-10', duration: 3 },
        { status: 'refunded', totalAmount: 0, visitDate: '2025-03-15', duration: 6 },
        { status: 'completed', totalAmount: 3000, visitDate: '2025-03-02', duration: 8 },
        { status: 'confirmed', totalAmount: 2200, visitDate: '2025-03-20', duration: 5 }
      ];

      // Calculer les métriques
      const totalBookings = mockBookings.length;
      const pendingBookings = mockBookings.filter(b => b.status === 'pending').length;
      const confirmedBookings = mockBookings.filter(b => b.status === 'confirmed').length;
      const completedBookings = mockBookings.filter(b => b.status === 'completed').length;
      const cancelledBookings = mockBookings.filter(b => b.status === 'cancelled').length;
      const refundedBookings = mockBookings.filter(b => b.status === 'refunded').length;

      const conversionRate = totalBookings > 0 
        ? ((confirmedBookings + completedBookings) / totalBookings) * 100 
        : 0;

      const cancellationRate = totalBookings > 0 
        ? ((cancelledBookings + refundedBookings) / totalBookings) * 100 
        : 0;

      const completedWithDates = mockBookings.filter(b => 
        b.status === 'completed' && b.visitDate
      );

      const averageDuration = completedWithDates.length > 0
        ? `${Math.round(completedWithDates.reduce((sum, b) => sum + (b.duration || 1), 0) / completedWithDates.length)}j`
        : '0j';

      return {
        success: true,
        data: {
          totalBookings,
          pendingBookings,
          confirmedBookings,
          completedBookings,
          cancelledBookings,
          refundedBookings,
          conversionRate,
          cancellationRate,
          averageDuration
        }
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des métriques de performance'
      };
    }
  }

  async getRevenueAnalytics() {
    try {
      // Mock data pour les revenus
      const mockBookings = [
        { 
          status: 'completed', 
          totalAmount: 2500,
          createdAt: '2025-03-01',
          residence: { 
            type: 'vacation',
            isSpecial: false,
            amenities: ['pool']
          }
        },
        { 
          status: 'confirmed', 
          totalAmount: 1800,
          createdAt: '2025-02-15',
          residence: { 
            type: 'standard',
            isSpecial: false,
            amenities: []
          }
        },
        { 
          status: 'completed', 
          totalAmount: 3500,
          createdAt: '2025-01-20',
          residence: { 
            type: 'vacation',
            isSpecial: true,
            amenities: ['pool']
          }
        }
      ];

      // Calculer les revenus totaux
      const totalRevenue = mockBookings.reduce((sum, booking) => {
        if (booking.status === 'completed' || booking.status === 'confirmed') {
          return sum + (booking.totalAmount || 0);
        }
        return sum;
      }, 0);

      // Revenus par période (6 derniers mois)
      const revenueByPeriod = Array(6).fill(null).map((_, index) => {
        const date = new Date();
        date.setMonth(date.getMonth() - index);
        const month = date.toLocaleString('fr-FR', { month: 'short' });
        const year = date.getFullYear();
        const period = `${month} ${year}`;

        const monthBookings = mockBookings.filter(b => {
          const bookingDate = new Date(b.createdAt);
          return bookingDate.getMonth() === date.getMonth() && 
                 bookingDate.getFullYear() === date.getFullYear();
        });

        return {
          period,
          revenue: monthBookings.reduce((sum, b) => sum + (b.totalAmount || 0), 0),
          bookings: monthBookings.length
        };
      }).reverse();

      // Revenus par type de résidence
      const revenueByResidenceType = [
        { type: 'Standard', revenue: 0, bookings: 0, hasPool: 0 },
        { type: 'Vacances', revenue: 0, bookings: 0, hasPool: 0 },
        { type: 'Spécial', revenue: 0, bookings: 0, hasPool: 0 }
      ];

      mockBookings.forEach(booking => {
        if (booking.residence) {
          const index = booking.residence.isSpecial ? 2 : 
                       booking.residence.type === 'vacation' ? 1 : 0;
          
          revenueByResidenceType[index].revenue += booking.totalAmount || 0;
          revenueByResidenceType[index].bookings += 1;
          if (booking.residence.amenities?.includes('pool')) {
            revenueByResidenceType[index].hasPool += 1;
          }
        }
      });

      return {
        success: true,
        data: {
          totalRevenue,
          revenueByPeriod,
          revenueByResidenceType
        }
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des analyses de revenus'
      };
    }
  }

  async getReports(type, filters = {}) {
    try {
      // Mock data pour les réservations
      const mockBookings = [
        { status: 'pending', totalAmount: 1200, visitDate: '2025-03-01', duration: 5 },
        { status: 'confirmed', totalAmount: 2500, visitDate: '2025-03-05', duration: 7 },
        { status: 'completed', totalAmount: 1800, visitDate: '2025-02-28', duration: 4 },
        { status: 'cancelled', totalAmount: 0, visitDate: '2025-03-10', duration: 3 },
        { status: 'refunded', totalAmount: 0, visitDate: '2025-03-15', duration: 6 },
        { status: 'completed', totalAmount: 3000, visitDate: '2025-03-02', duration: 8 },
        { status: 'confirmed', totalAmount: 2200, visitDate: '2025-03-20', duration: 5 }
      ];

      let reportData;

      switch (type) {
        case 'occupancy':
          reportData = this.generateOccupancyReport(mockBookings);
          break;

        case 'revenue':
          reportData = this.generateRevenueReport(mockBookings);
          break;

        case 'performance':
          reportData = this.generatePerformanceReport(mockBookings);
          break;

        default:
          throw new Error('Type de rapport non supporté');
      }

      return {
        success: true,
        data: reportData
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la génération du rapport'
      };
    }
  }

  generateOccupancyReport(bookings) {
    // Calculer les taux d'occupation par résidence
    const occupancyByResidence = bookings.reduce((acc, booking) => {
      const residence = booking.residence;
      if (!residence) return acc;

      const residenceId = residence._id;
      if (!acc[residenceId]) {
        acc[residenceId] = {
          residenceId,
          residenceName: residence.name || 'Inconnu',
          displayAddress: `${residence.location.city}, ${residence.location.country}`,
          hasPool: residence.amenities?.includes('pool'),
          isVacationResidence: residence.type === 'vacation',
          isSpecialResidence: residence.isSpecial,
          totalBookings: 0,
          completedBookings: 0,
          occupancyRate: 0
        };
      }

      acc[residenceId].totalBookings += 1;
      if (booking.status === 'completed') {
        acc[residenceId].completedBookings += 1;
      }

      return acc;
    }, {});

    // Calculer les taux d'occupation
    Object.values(occupancyByResidence).forEach(residence => {
      residence.occupancyRate = residence.totalBookings > 0
        ? (residence.completedBookings / residence.totalBookings) * 100
        : 0;
    });

    return {
      occupancyByResidence: Object.values(occupancyByResidence),
      totalResidences: Object.keys(occupancyByResidence).length,
      averageOccupancyRate: Object.values(occupancyByResidence).reduce((sum, r) => sum + r.occupancyRate, 0) / Object.keys(occupancyByResidence).length
    };
  }

  generateRevenueReport(bookings) {
    const completedBookings = bookings.filter(b => b.status === 'completed');
    
    // Revenus totaux
    const totalRevenue = completedBookings.reduce((sum, b) => sum + (b.totalAmount || 0), 0);
    
    // Revenus par statut
    const revenueByStatus = bookings.reduce((acc, booking) => {
      const status = booking.status;
      if (!acc[status]) {
        acc[status] = {
          status,
          revenue: 0,
          count: 0
        };
      }
      acc[status].revenue += booking.totalAmount || 0;
      acc[status].count += 1;
      return acc;
    }, {});

    return {
      totalRevenue,
      revenueByStatus: Object.values(revenueByStatus),
      averageBookingValue: completedBookings.length > 0 ? totalRevenue / completedBookings.length : 0,
      totalCompletedBookings: completedBookings.length
    };
  }

  generatePerformanceReport(bookings) {
    const totalBookings = bookings.length;
    const statusCounts = bookings.reduce((acc, booking) => {
      const status = booking.status;
      acc[status] = (acc[status] || 0) + 1;
      return acc;
    }, {});

    const conversionRate = totalBookings > 0
      ? ((statusCounts.confirmed || 0) + (statusCounts.completed || 0)) / totalBookings * 100
      : 0;

    const cancellationRate = totalBookings > 0
      ? ((statusCounts.cancelled || 0) + (statusCounts.refunded || 0)) / totalBookings * 100
      : 0;

    return {
      totalBookings,
      statusDistribution: Object.entries(statusCounts).map(([status, count]) => ({
        status,
        count,
        percentage: (count / totalBookings) * 100
      })),
      conversionRate,
      cancellationRate
    };
  }
}

export const analyticsService = new AnalyticsService();
