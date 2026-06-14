import axios from 'axios';
import { API_URL } from '../config';

const authHeaders = () => ({
  Authorization: `Bearer ${localStorage.getItem('token')}`,
});

class FinanceService {
  getPaymentStatuses() {
    return {
      pending: { label: 'En attente', color: 'warning' },
      paid: { label: 'Payé', color: 'success' },
      completed: { label: 'Payé', color: 'success' },
      failed: { label: 'Échoué', color: 'error' },
      cancelled: { label: 'Annulé', color: 'default' },
      refunded: { label: 'Remboursé', color: 'default' },
      expired: { label: 'Expiré', color: 'default' },
    };
  }

  getPaymentMethods() {
    return [
      { id: 'card', name: 'Carte bancaire' },
      { id: 'orange_money', name: 'Orange Money' },
      { id: 'mtn_money', name: 'MTN Money' },
      { id: 'moov_money', name: 'Moov Money' },
      { id: 'wave', name: 'Wave' },
      { id: 'mobile_money', name: 'Mobile Money' },
    ];
  }

  /**
   * Liste des paiements depuis la collection Payment (admin).
   */
  async getPayments({ page = 1, limit = 20, filters = {}, search = '' }) {
    try {
      const response = await axios.get(`${API_URL}/admin/payments`, {
        headers: authHeaders(),
        params: {
          page,
          limit,
          status: filters?.status || undefined,
          paymentMethod: filters?.paymentMethod || undefined,
        },
      });

      let payments = response.data?.data || [];

      const searchQuery = String(search || '').trim().toLowerCase();
      if (searchQuery) {
        payments = payments.filter((p) => {
          const ref = p.paymentDetails?.reference || p.transactionId || '';
          const phone = p.phoneNumber || p.reservation?.user?.phone || '';
          const haystack = `${ref} ${phone} ${p._id}`.toLowerCase();
          return haystack.includes(searchQuery);
        });
      }

      const startDate = filters?.startDate ? new Date(filters.startDate) : null;
      const endDate = filters?.endDate ? new Date(filters.endDate) : null;
      if (startDate || endDate) {
        payments = payments.filter((p) => {
          const created = p.createdAt ? new Date(p.createdAt) : null;
          if (!created) return true;
          if (startDate && created < startDate) return false;
          if (endDate) {
            const endInclusive = new Date(endDate.getTime() + 86400000 - 1);
            if (created > endInclusive) return false;
          }
          return true;
        });
      }

      return {
        success: true,
        data: payments.map((p) => this._normalizePayment(p)),
      };
    } catch (error) {
      console.error('Erreur lors de la récupération des paiements:', error);
      return {
        success: false,
        data: [],
        error: error.response?.data?.message || 'Erreur lors de la récupération des paiements',
      };
    }
  }

  _normalizePayment(p) {
    const uiStatus = p.status === 'paid' ? 'completed' : p.status;
    return {
      ...p,
      status: uiStatus,
      paymentDetails: {
        reference: p.transactionId || p._id,
        ...(p.paymentDetails || {}),
      },
      phoneNumber:
        p.phoneNumber ||
        p.reservation?.user?.phone ||
        p.reservation?.user?.phoneNumber,
    };
  }

  /**
   * Confirmation manuelle interdite — le statut vient du PSP via webhook.
   */
  async confirmPayment(paymentId, _otp) {
    return {
      success: false,
      error:
        'La confirmation manuelle est désactivée. Le paiement est validé uniquement via Wave/CinetPay (webhook).',
    };
  }

  async createPayment() {
    return {
      success: false,
      error:
        'La création manuelle de paiement est désactivée pour des raisons de sécurité.',
    };
  }

  async getFinancialStats() {
    try {
      const response = await this.getPayments({ page: 1, limit: 500, filters: {}, search: '' });
      if (!response.success) {
        throw new Error(response.error);
      }

      const payments = response.data;
      const now = new Date();
      const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());

      const paid = payments.filter((p) => p.status === 'completed' || p.status === 'paid');
      const today = payments.filter((p) => new Date(p.createdAt) >= todayStart);
      const refunded = payments.filter((p) => p.status === 'refunded');

      return {
        success: true,
        data: {
          totalVolume: paid.reduce((sum, p) => sum + (p.amount || 0), 0),
          todayTransactions: today.length,
          successRate:
            payments.length > 0 ? Math.round((paid.length / payments.length) * 100) : 0,
          refundAmount: refunded.reduce((sum, p) => sum + (p.amount || 0), 0),
        },
      };
    } catch (error) {
      return {
        success: false,
        data: null,
        error: error.message || 'Erreur lors de la récupération des statistiques',
      };
    }
  }
}

export const financeService = new FinanceService();
