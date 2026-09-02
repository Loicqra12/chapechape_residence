import axios from 'axios';
import { API_URL } from '../config';
import { normalizeReservationStatus } from '../constants/reservationStatus';

function authConfig() {
  const token = localStorage.getItem('token');
  return token ? { headers: { Authorization: `Bearer ${token}` } } : {};
}

function handleAuthError(error) {
  if (error.response?.status === 401) {
    window.location.href = '/login';
    throw new Error('Session expirée, veuillez vous reconnecter');
  }
  const message = error.response?.data?.message || error.message || 'Erreur Ops';
  throw new Error(message);
}

export function mapOpsReservation(reservation) {
  if (!reservation) return null;
  const checkIn = reservation.checkIn || reservation.visitDate;
  return {
    ...reservation,
    _id: reservation._id,
    status: normalizeReservationStatus(reservation.status) || reservation.status,
    visitDate: checkIn,
    visitTime: checkIn ? new Date(checkIn).toISOString().slice(11, 16) : '',
    allowedActions: reservation.allowedActions || [],
    client: reservation.client || null,
    partner: reservation.partner || null,
    residence: reservation.residence || null,
  };
}

class OpsService {
  async listReservations({ page = 1, limit = 20, filters = {}, sort } = {}) {
    try {
      const params = {
        page,
        limit,
        status: Array.isArray(filters.status) ? filters.status.join(',') : (filters.status || undefined),
        paymentStatus: filters.paymentStatus || undefined,
        residenceId: filters.residence || filters.residenceId || undefined,
        partnerId: filters.partner || filters.partnerId || undefined,
        clientId: filters.clientId || undefined,
        search: filters.searchQuery || filters.search || undefined,
        startDate: filters.startDate || undefined,
        endDate: filters.endDate || undefined,
      };
      const response = await axios.get(`${API_URL}/admin/ops/reservations`, {
        ...authConfig(),
        params,
      });
      const rows = (response.data.data || []).map(mapOpsReservation);
      return {
        bookings: rows,
        data: rows,
        total: response.data.pagination?.total || rows.length,
        pages: response.data.pagination?.pages || 1,
        page: response.data.pagination?.page || page,
        limit: response.data.pagination?.limit || limit,
        pagination: response.data.pagination,
      };
    } catch (error) {
      handleAuthError(error);
    }
  }

  async getReservation(id) {
    try {
      const response = await axios.get(`${API_URL}/admin/ops/reservations/${id}`, authConfig());
      return mapOpsReservation(response.data.data);
    } catch (error) {
      handleAuthError(error);
    }
  }

  async cancelReservation(id, reason) {
    try {
      const response = await axios.post(
        `${API_URL}/admin/ops/reservations/${id}/cancel`,
        { reason },
        authConfig()
      );
      return mapOpsReservation(response.data.data);
    } catch (error) {
      handleAuthError(error);
    }
  }

  async checkinReservation(id, reason = 'Check-in Ops') {
    try {
      const response = await axios.post(
        `${API_URL}/admin/ops/reservations/${id}/checkin`,
        { reason },
        authConfig()
      );
      return mapOpsReservation(response.data.data);
    } catch (error) {
      handleAuthError(error);
    }
  }

  async checkoutReservation(id, reason = 'Check-out Ops') {
    try {
      const response = await axios.post(
        `${API_URL}/admin/ops/reservations/${id}/checkout`,
        { reason },
        authConfig()
      );
      return mapOpsReservation(response.data.data);
    } catch (error) {
      handleAuthError(error);
    }
  }

  async listRefunds({ page = 1, limit = 20, bucket = 'ops_required' } = {}) {
    try {
      const response = await axios.get(`${API_URL}/admin/ops/refunds`, {
        ...authConfig(),
        params: { page, limit, bucket },
      });
      return {
        data: response.data.data || [],
        counts: response.data.counts || {},
        pagination: response.data.pagination,
      };
    } catch (error) {
      handleAuthError(error);
    }
  }

  async confirmRefund(id, { note, externalReference }) {
    try {
      const response = await axios.post(
        `${API_URL}/admin/ops/refunds/${id}/confirm`,
        { note, externalReference },
        authConfig()
      );
      return response.data.data;
    } catch (error) {
      handleAuthError(error);
    }
  }

  async listAnomalies() {
    try {
      const response = await axios.get(`${API_URL}/admin/ops/anomalies`, authConfig());
      return response.data.data;
    } catch (error) {
      handleAuthError(error);
    }
  }

  async getInventoryCalendar(residenceId, startDate, endDate) {
    try {
      const response = await axios.get(`${API_URL}/admin/ops/inventory/${residenceId}`, {
        ...authConfig(),
        params: { startDate, endDate },
      });
      return response.data.data;
    } catch (error) {
      handleAuthError(error);
    }
  }

  async listAudit({ page = 1, limit = 20, entityId } = {}) {
    try {
      const response = await axios.get(`${API_URL}/admin/ops/audit`, {
        ...authConfig(),
        params: { page, limit, entityId },
      });
      return response.data;
    } catch (error) {
      handleAuthError(error);
    }
  }
}

export const opsService = new OpsService();
