import axios from 'axios';
import { API_URL } from '../config';

class AnalyticsService {
  _authHeaders() {
    const token = localStorage.getItem('token');
    return token ? { Authorization: `Bearer ${token}` } : {};
  }

  async getCommunicationStats() {
    try {
      const res = await axios.get(`${API_URL}/dashboard/communication-stats`, {
        headers: this._authHeaders()
      });
      return res.data?.success ? res.data : { success: false, error: 'Réponse inattendue' };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des statistiques de communication'
      };
    }
  }

  async getResidenceStats(filters = {}) {
    try {
      const { timeframe = 'month', startDate, endDate } = filters;
      const res = await axios.get(`${API_URL}/dashboard/residence-stats`, {
        params: { timeframe, startDate, endDate },
        headers: this._authHeaders()
      });
      return res.data?.success ? res.data : { success: false, error: 'Réponse inattendue' };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des statistiques des résidences'
      };
    }
  }

  async getPerformanceMetrics(filters = {}) {
    try {
      const { timeframe = 'month', startDate, endDate } = filters;
      const res = await axios.get(`${API_URL}/dashboard/performance-metrics`, {
        params: { timeframe, startDate, endDate },
        headers: this._authHeaders()
      });
      return res.data?.success ? res.data : { success: false, error: 'Réponse inattendue' };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des métriques de performance'
      };
    }
  }

  async getRevenueAnalytics({ timeframe = 'month', startDate, endDate } = {}) {
    try {
      const res = await axios.get(`${API_URL}/dashboard/revenue-analytics`, {
        params: { timeframe, startDate, endDate },
        headers: this._authHeaders()
      });
      return res.data?.success ? res.data : { success: false, error: 'Réponse inattendue' };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la récupération des analyses de revenus'
      };
    }
  }

  async getReports(type, filters = {}) {
    try {
      const { startDate, endDate } = filters;
      const res = await axios.get(`${API_URL}/dashboard/reports`, {
        params: { type, startDate, endDate },
        headers: this._authHeaders()
      });
      return res.data?.success ? res.data : { success: false, error: 'Réponse inattendue' };
    } catch (error) {
      return {
        success: false,
        error: error.response?.data?.message || 'Erreur lors de la génération du rapport'
      };
    }
  }
}

export const analyticsService = new AnalyticsService();
