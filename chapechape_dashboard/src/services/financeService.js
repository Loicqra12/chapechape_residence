import axios from 'axios';
import { API_URL } from '../config';

class FinanceService {
  getPaymentStatuses() {
    return {
      pending: {
        label: 'En attente',
        color: 'warning'
      },
      processing: {
        label: 'En cours',
        color: 'info'
      },
      completed: {
        label: 'Complété',
        color: 'success'
      },
      failed: {
        label: 'Échoué',
        color: 'error'
      },
      refunded: {
        label: 'Remboursé',
        color: 'default'
      }
    };
  }

  getPaymentMethods() {
    return [
      { id: 'card', name: 'Carte bancaire' },
      { id: 'orange_money', name: 'Orange Money' },
      { id: 'mtn_money', name: 'MTN Money' },
      { id: 'moov_money', name: 'Moov Money' },
      { id: 'wave', name: 'Wave' },
      { id: 'djamo', name: 'Djamo' }
    ];
  }

  async getPayments({ page = 1, limit = 10, filters = {} }) {
    try {
      // Récupérer les réservations avec leurs paiements
      const response = await axios.get(`${API_URL}/bookings/all`, {
        params: {
          page,
          limit,
          ...filters
        }
      });

      // Transformer les réservations en paiements
      const payments = response.data.data.map(booking => ({
        _id: booking._id,
        amount: booking.totalPrice,
        status: booking.paymentStatus === 'paid' ? 'completed' : 'pending',
        paymentMethod: booking.paymentMethod || 'card',
        createdAt: booking.createdAt,
        paymentDetails: {
          reference: booking._id,
          bookingId: booking._id
        },
        phoneNumber: booking.client?.phoneNumber
      }));

      return {
        success: true,
        data: payments
      };
    } catch (error) {
      console.error('Erreur lors de la récupération des paiements:', error);
      return {
        success: false,
        data: [],
        error: error.response?.data?.message || 'Erreur lors de la récupération des paiements'
      };
    }
  }

  async createPayment(data) {
    try {
      const response = await axios.post(`${API_URL}/bookings/${data.bookingId}/confirm`, {
        paymentMethod: data.paymentMethod,
        phoneNumber: data.phoneNumber
      });

      return {
        success: true,
        data: {
          _id: response.data.data._id,
          status: 'completed',
          ...data
        }
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la création du paiement'
      };
    }
  }

  async confirmPayment(bookingId) {
    try {
      const response = await axios.post(`${API_URL}/bookings/${bookingId}/confirm`);
      return {
        success: true,
        data: response.data.data
      };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la confirmation du paiement'
      };
    }
  }

  async getFinancialStats() {
    try {
      // Récupérer toutes les réservations pour calculer les statistiques
      const response = await this.getPayments({ limit: 1000 });
      if (!response.success) {
        throw new Error(response.error);
      }

      const bookings = response.data;
      const now = new Date();
      const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());

      // Calculer les statistiques
      const stats = {
        totalVolume: 0,
        todayTransactions: 0,
        successRate: 0,
        refundAmount: 0
      };

      const completedBookings = bookings.filter(b => b.status === 'completed');
      const todayBookings = bookings.filter(b => new Date(b.createdAt) >= todayStart);
      const refundedBookings = bookings.filter(b => b.status === 'refunded');

      stats.totalVolume = completedBookings.reduce((sum, b) => sum + b.amount, 0);
      stats.todayTransactions = todayBookings.length;
      stats.successRate = bookings.length > 0 
        ? Math.round((completedBookings.length / bookings.length) * 100)
        : 0;
      stats.refundAmount = refundedBookings.reduce((sum, b) => sum + b.amount, 0);

      return {
        success: true,
        data: stats
      };
    } catch (error) {
      console.error('Erreur lors de la récupération des statistiques:', error);
      return {
        success: false,
        data: null,
        error: error.message || 'Erreur lors de la récupération des statistiques'
      };
    }
  }
}

export const financeService = new FinanceService();
