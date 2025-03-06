import axios from 'axios';
import { API_URL } from '../config';

class BookingService {
  getAuthHeader() {
    const token = localStorage.getItem('token');
    return {
      headers: {
        Authorization: `Bearer ${token}`
      }
    };
  }

  async getBookings({ page = 1, limit = 10, sort, filters }) {
    try {
      const response = await axios.get(`${API_URL}/bookings/all`, {
        ...this.getAuthHeader(),
        params: {
          page,
          limit,
          sort: sort ? `${sort.field}:${sort.direction}` : undefined,
          status: filters?.status,
          search: filters?.searchQuery,
          startDate: filters?.startDate,
          endDate: filters?.endDate,
          residence: filters?.residence,
          partner: filters?.partner
        }
      });

      const { data, pagination } = response.data;
      return {
        bookings: data.map(booking => ({
          _id: booking._id,
          visitDate: booking.visitDate,
          visitTime: booking.visitTime,
          status: booking.status,
          residence: booking.residence ? {
            _id: booking.residence._id,
            ...booking.residenceProperties,
            location: booking.locationDisplay
          } : null,
          client: booking.client ? {
            _id: booking.client._id,
            name: `${booking.client.firstName} ${booking.client.lastName}`,
            email: booking.client.email
          } : null,
          partner: booking.partner ? {
            _id: booking.partner._id,
            name: booking.partner.name,
            email: booking.partner.email
          } : null,
          notes: booking.notes,
          feedback: booking.feedback,
          cancellation: booking.cancellationReason ? {
            reason: booking.cancellationReason,
            date: booking.cancelledAt,
            by: booking.cancelledBy
          } : null,
          createdAt: booking.createdAt,
          updatedAt: booking.updatedAt
        })),
        total: pagination.total,
        pages: pagination.pages,
        page: pagination.page,
        limit: pagination.limit
      };
    } catch (error) {
      if (error.response?.status === 401) {
        window.location.href = '/login';
        throw new Error("Session expirée, veuillez vous reconnecter");
      }
      console.error('Erreur lors du chargement des réservations:', error);
      throw new Error("Erreur lors du chargement des réservations");
    }
  }

  async getBookingById(id) {
    try {
      const response = await axios.get(`${API_URL}/bookings/${id}`, this.getAuthHeader());
      const booking = response.data.data;
      return {
        _id: booking._id,
        visitDate: booking.visitDate,
        visitTime: booking.visitTime,
        status: booking.status,
        residence: booking.residence ? {
          _id: booking.residence._id,
          ...booking.residenceProperties,
          location: booking.locationDisplay
        } : null,
        client: booking.client ? {
          _id: booking.client._id,
          name: `${booking.client.firstName} ${booking.client.lastName}`,
          email: booking.client.email
        } : null,
        partner: booking.partner ? {
          _id: booking.partner._id,
          name: booking.partner.name,
          email: booking.partner.email
        } : null,
        notes: booking.notes,
        feedback: booking.feedback,
        cancellation: booking.cancellationReason ? {
          reason: booking.cancellationReason,
          date: booking.cancelledAt,
          by: booking.cancelledBy
        } : null,
        createdAt: booking.createdAt,
        updatedAt: booking.updatedAt
      };
    } catch (error) {
      if (error.response?.status === 401) {
        window.location.href = '/login';
        throw new Error("Session expirée, veuillez vous reconnecter");
      }
      console.error('Erreur lors du chargement de la réservation:', error);
      throw new Error("Erreur lors du chargement de la réservation");
    }
  }

  async confirmBooking(id) {
    try {
      const response = await axios.post(
        `${API_URL}/bookings/${id}/confirm`,
        {},
        this.getAuthHeader()
      );
      return this._transformBooking(response.data.data);
    } catch (error) {
      if (error.response?.status === 401) {
        window.location.href = '/login';
        throw new Error("Session expirée, veuillez vous reconnecter");
      }
      console.error('Erreur lors de la confirmation de la réservation:', error);
      throw new Error("Erreur lors de la confirmation de la réservation");
    }
  }

  async cancelBooking(id, reason) {
    try {
      const response = await axios.post(
        `${API_URL}/bookings/${id}/cancel`,
        { reason },
        this.getAuthHeader()
      );
      return this._transformBooking(response.data.data);
    } catch (error) {
      if (error.response?.status === 401) {
        window.location.href = '/login';
        throw new Error("Session expirée, veuillez vous reconnecter");
      }
      console.error('Erreur lors de l\'annulation de la réservation:', error);
      throw new Error("Erreur lors de l'annulation de la réservation");
    }
  }

  async completeBooking(id, feedback) {
    try {
      const response = await axios.post(
        `${API_URL}/bookings/${id}/complete`,
        feedback,
        this.getAuthHeader()
      );
      return this._transformBooking(response.data.data);
    } catch (error) {
      if (error.response?.status === 401) {
        window.location.href = '/login';
        throw new Error("Session expirée, veuillez vous reconnecter");
      }
      console.error('Erreur lors du marquage de la réservation comme terminée:', error);
      throw new Error("Erreur lors du marquage de la réservation comme terminée");
    }
  }

  async bulkUpdateStatus(ids, status) {
    try {
      const promises = ids.map(id => 
        axios.post(
          `${API_URL}/bookings/${id}/${status}`,
          {},
          this.getAuthHeader()
        )
      );
      await Promise.all(promises);
      return { success: true };
    } catch (error) {
      if (error.response?.status === 401) {
        window.location.href = '/login';
        throw new Error("Session expirée, veuillez vous reconnecter");
      }
      console.error('Erreur lors de la mise à jour groupée des réservations:', error);
      throw new Error("Erreur lors de la mise à jour groupée des réservations");
    }
  }

  _transformBooking(booking) {
    return {
      _id: booking._id,
      visitDate: booking.visitDate,
      visitTime: booking.visitTime,
      status: booking.status,
      residence: booking.residence ? {
        _id: booking.residence._id,
        ...booking.residenceProperties,
        location: booking.locationDisplay
      } : null,
      client: booking.client ? {
        _id: booking.client._id,
        name: `${booking.client.firstName} ${booking.client.lastName}`,
        email: booking.client.email
      } : null,
      partner: booking.partner ? {
        _id: booking.partner._id,
        name: booking.partner.name,
        email: booking.partner.email
      } : null,
      notes: booking.notes,
      feedback: booking.feedback,
      cancellation: booking.cancellationReason ? {
        reason: booking.cancellationReason,
        date: booking.cancelledAt,
        by: booking.cancelledBy
      } : null,
      createdAt: booking.createdAt,
      updatedAt: booking.updatedAt
    };
  }
}

export const bookingService = new BookingService();
