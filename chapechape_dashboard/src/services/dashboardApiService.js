import axios from 'axios';
import { API_URL } from '../config';

class DashboardApiService {
  constructor() {
    this.baseURL = API_URL;
    this.api = axios.create({ baseURL: this.baseURL });
    this.setupAxiosInterceptors();
  }

  setupAxiosInterceptors() {
    // Intercepteur pour ajouter le token d'authentification
    axios.interceptors.request.use(
      (config) => {
        const token = localStorage.getItem('token');
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => {
        return Promise.reject(error);
      }
    );

    // Intercepteur pour gérer les erreurs de réponse
    axios.interceptors.response.use(
      (response) => response,
      (error) => {
        if (error.response?.status === 401) {
          // Token expiré ou invalide
          localStorage.removeItem('token');
          window.location.href = '/auth/login';
        }
        return Promise.reject(error);
      }
    );
  }

  // ============ DASHBOARD OVERVIEW ============
  async getDashboardOverview() {
    try {
      const response = await axios.get(`${this.baseURL}/dashboard/overview`);

      if (response.data?.success) {
        return {
          success: true,
          data: this.formatOverviewData(response.data.data)
        };
      }

      throw new Error(response.data?.message || 'Erreur lors de la récupération des données');
    } catch (error) {
      console.error('Dashboard Overview Error:', error);
      return {
        success: false,
        error: error.response?.data?.message || error.message || 'Erreur de connexion au serveur'
      };
    }
  }

  formatOverviewData(data) {
    return {
      bookingStats: {
        totalBookings: data.bookings?.total || 0,
        confirmedBookings: data.bookings?.confirmed || 0,
        pendingBookings: data.bookings?.pending || 0,
        completedBookings: data.bookings?.completed || 0,
        cancelledBookings: data.bookings?.cancelled || 0,
        refundedBookings: data.bookings?.refunded || 0,
        conversionRate: data.occupancy_rate || 0,
        averageDuration: '4.2j', // À calculer depuis le backend
        monthlyBookings: this.generateMonthlyData(data.bookings?.total || 0)
      },
      revenueData: {
        totalRevenue: data.performance?.total_revenue || 0,
        monthlyData: this.generateMonthlyRevenue(data.performance?.total_revenue || 0)
      },
      residenceStats: {
        totalResidences: data.total_residences || 0,
        available: Math.floor((data.total_residences || 0) * 0.7),
        occupied: Math.floor((data.total_residences || 0) * 0.3),
        occupancyRate: data.occupancy_rate || 0,
        averageRating: data.performance?.average_rating || 0,
        averagePrice: 87500 // À récupérer depuis le backend
      },
      communicationStats: {
        totalMessages: data.new_messages || 0,
        averageResponseTime: '2.4h',
        satisfactionRate: data.response_rate || 0,
        activeSupport: 12,
        messages: {
          unread: data.new_messages || 0,
          total: data.new_messages * 4 || 0
        }
      }
    };
  }

  // ============ FINANCIAL STATS ============
  async getFinancialStats() {
    try {
      const response = await axios.get(`${this.baseURL}/dashboard/financial-stats`);

      if (response.data?.success) {
        return {
          success: true,
          data: response.data.data
        };
      }

      throw new Error(response.data?.message || 'Erreur lors de la récupération des statistiques financières');
    } catch (error) {
      console.error('Financial Stats Error:', error);
      return {
        success: false,
        error: error.response?.data?.message || error.message || 'Erreur de connexion au serveur'
      };
    }
  }

  // ============ BOOKING ANALYTICS ============
  async getBookingAnalytics(timeRange = '30d') {
    try {
      // Utilise l'endpoint reservations analytics au lieu de bookings
      const response = await axios.get(`${this.baseURL}/reservations/analytics`, {
        params: { timeRange }
      });

      if (response.data?.success) {
        return {
          success: true,
          data: response.data.data
        };
      }

      throw new Error(response.data?.message || 'Erreur lors de la récupération des analytics de réservation');
    } catch (error) {
      console.error('Booking Analytics Error:', error);
      return {
        success: false,
        error: error.response?.data?.message || error.message || 'Erreur de connexion au serveur'
      };
    }
  }

  // ============ RESIDENCE ANALYTICS ============
  async getResidenceAnalytics(timeRange = '30d') {
    try {
      const response = await axios.get(`${this.baseURL}/residences/analytics`, {
        params: { timeRange }
      });

      if (response.data?.success) {
        return {
          success: true,
          data: response.data.data
        };
      }

      throw new Error(response.data?.message || 'Erreur lors de la récupération des analytics de résidences');
    } catch (error) {
      console.error('Residence Analytics Error:', error);
      return {
        success: false,
        error: error.response?.data?.message || error.message || 'Erreur de connexion au serveur'
      };
    }
  }

  // ============ COMMUNICATION ANALYTICS ============
  async getCommunicationAnalytics(timeRange = '30d') {
    try {
      const response = await axios.get(`${this.baseURL}/messages/analytics`, {
        params: { timeRange }
      });

      if (response.data?.success) {
        return {
          success: true,
          data: response.data.data
        };
      }

      throw new Error(response.data?.message || 'Erreur lors de la récupération des analytics de communication');
    } catch (error) {
      console.error('Communication Analytics Error:', error);
      return {
        success: false,
        error: error.response?.data?.message || error.message || 'Erreur de connexion au serveur'
      };
    }
  }

  // ============ UTILITY METHODS ============
  generateMonthlyData(total) {
    // Génère des données mensuelles basées sur le total
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return months.map((month, index) => {
      const variation = 0.8 + (Math.random() * 0.4); // Variation de ±20%
      return Math.floor((total / 12) * variation);
    });
  }

  generateMonthlyRevenue(total) {
    // Génère des revenus mensuels basés sur le total
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return months.map((month, index) => {
      const variation = 0.7 + (Math.random() * 0.6); // Variation de ±30%
      return Math.floor((total / 12) * variation);
    });
  }

  // ============ CACHE MANAGEMENT ============
  async refreshDashboardData() {
    try {
      const [overview, financial, bookings, residences, communication] = await Promise.all([
        this.getDashboardOverview(),
        this.getFinancialStats(),
        this.getBookingAnalytics(),
        this.getResidenceAnalytics(),
        this.getCommunicationAnalytics()
      ]);

      return {
        success: true,
        data: {
          overview: overview.data,
          financial: financial.data,
          bookings: bookings.data,
          residences: residences.data,
          communication: communication.data
        }
      };
    } catch (error) {
      console.error('Dashboard Refresh Error:', error);
      return {
        success: false,
        error: 'Erreur lors de l\'actualisation des données du dashboard'
      };
    }
  }

  // ============ REAL-TIME UPDATES ============
  async getRealtimeStats() {
    try {
      const response = await axios.get(`${this.baseURL}/dashboard/realtime`);

      if (response.data?.success) {
        return {
          success: true,
          data: response.data.data
        };
      }

      throw new Error(response.data?.message || 'Erreur lors de la récupération des statistiques temps réel');
    } catch (error) {
      console.error('Realtime Stats Error:', error);
      return {
        success: false,
        error: error.response?.data?.message || error.message || 'Erreur de connexion au serveur'
      };
    }
  }

  // ============ ERROR HANDLING ============
  handleApiError(error) {
    if (error.response) {
      // Erreur de réponse du serveur
      const status = error.response.status;
      const message = error.response.data?.message || 'Erreur serveur';

      switch (status) {
        case 400:
          return { success: false, error: `Requête invalide: ${message}` };
        case 401:
          return { success: false, error: 'Non autorisé. Veuillez vous reconnecter.' };
        case 403:
          return { success: false, error: 'Accès refusé. Permissions insuffisantes.' };
        case 404:
          return { success: false, error: 'Ressource non trouvée.' };
        case 500:
          return { success: false, error: 'Erreur interne du serveur.' };
        default:
          return { success: false, error: `Erreur ${status}: ${message}` };
      }
    } else if (error.request) {
      // Erreur de réseau
      return { success: false, error: 'Erreur de connexion. Vérifiez votre connexion internet.' };
    } else {
      // Autre erreur
      return { success: false, error: error.message || 'Une erreur inattendue s\'est produite.' };
    }
  }
}

export const dashboardApiService = new DashboardApiService();
