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
      // Pour le moment, utiliser my-reservations
      // TODO: Implémenter une route admin spécifique pour toutes les réservations
      const response = await axios.get(`${API_URL}/reservations/my-reservations`, {
        ...this.getAuthHeader()
      });

      // Réponse directe depuis reservations endpoint  
      const reservations = response.data.data || response.data || [];
      
      return {
        bookings: reservations.map(reservation => ({
          _id: reservation._id,
          visitDate: reservation.visitDate || reservation.createdAt,
          visitTime: reservation.visitTime || '09:00',
          status: reservation.status || 'confirmed',
          residence: reservation.residence ? {
            _id: reservation.residence._id,
            title: reservation.residence.title,
            location: reservation.residence.location,
            address: reservation.residence.address,
            city: reservation.residence.city
          } : null,
          client: reservation.user ? {
            _id: reservation.user._id,
            name: `${reservation.user.firstName || ''} ${reservation.user.lastName || ''}`.trim(),
            email: reservation.user.email
          } : null,
          partner: reservation.partner ? {
            _id: reservation.partner._id,
            name: reservation.partner.name,
            email: reservation.partner.email
          } : null,
          notes: reservation.notes,
          feedback: reservation.feedback,
          cancellation: reservation.cancellationReason ? {
            reason: reservation.cancellationReason,
            date: reservation.cancelledAt,
            by: reservation.cancelledBy
          } : null,
          createdAt: reservation.createdAt,
          updatedAt: reservation.updatedAt
        })),
        // Pagination simple pour le fallback
        total: reservations.length,
        pages: 1,
        page: 1,
        limit: reservations.length
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
      // Utilise l'endpoint reservations au lieu de bookings
      const response = await axios.get(`${API_URL}/reservations/${id}`, this.getAuthHeader());
      const reservation = response.data.data || response.data;
      return {
        _id: reservation._id,
        visitDate: reservation.visitDate || reservation.createdAt,
        visitTime: reservation.visitTime || '09:00',
        status: reservation.status || 'confirmed',
        residence: reservation.residence ? {
          _id: reservation.residence._id,
          title: reservation.residence.title,
          location: reservation.residence.location,
          address: reservation.residence.address,
          city: reservation.residence.city
        } : null,
        client: reservation.user ? {
          _id: reservation.user._id,
          name: `${reservation.user.firstName || ''} ${reservation.user.lastName || ''}`.trim(),
          email: reservation.user.email
        } : null,
        partner: reservation.partner ? {
          _id: reservation.partner._id,
          name: reservation.partner.name,
          email: reservation.partner.email
        } : null,
        notes: reservation.notes,
        feedback: reservation.feedback,
        cancellation: reservation.cancellationReason ? {
          reason: reservation.cancellationReason,
          date: reservation.cancelledAt,
          by: reservation.cancelledBy
        } : null,
        createdAt: reservation.createdAt,
        updatedAt: reservation.updatedAt
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
      // Utilise l'endpoint reservations pour confirmer
      const response = await axios.patch(
        `${API_URL}/reservations/${id}`,
        { status: 'confirmed' },
        this.getAuthHeader()
      );
      return this._transformReservation(response.data.data || response.data);
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
      // Utilise l'endpoint reservations pour annuler
      const response = await axios.patch(
        `${API_URL}/reservations/${id}`,
        { 
          status: 'cancelled',
          cancellationReason: reason,
          cancelledAt: new Date().toISOString()
        },
        this.getAuthHeader()
      );
      return this._transformReservation(response.data.data || response.data);
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
      // Utilise l'endpoint reservations pour marquer comme terminé
      const response = await axios.patch(
        `${API_URL}/reservations/${id}`,
        { 
          status: 'completed',
          feedback: feedback,
          completedAt: new Date().toISOString()
        },
        this.getAuthHeader()
      );
      return this._transformReservation(response.data.data || response.data);
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
      // Utilise l'endpoint reservations pour les mises à jour groupées
      const promises = ids.map(id => 
        axios.patch(
          `${API_URL}/reservations/${id}`,
          { status: status },
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

  _transformReservation(reservation) {
    return {
      _id: reservation._id,
      visitDate: reservation.visitDate || reservation.createdAt,
      visitTime: reservation.visitTime || '09:00',
      status: reservation.status || 'confirmed',
      residence: reservation.residence ? {
        _id: reservation.residence._id,
        title: reservation.residence.title,
        location: reservation.residence.location,
        address: reservation.residence.address,
        city: reservation.residence.city
      } : null,
      client: reservation.user ? {
        _id: reservation.user._id,
        name: `${reservation.user.firstName || ''} ${reservation.user.lastName || ''}`.trim(),
        email: reservation.user.email
      } : null,
      partner: reservation.partner ? {
        _id: reservation.partner._id,
        name: reservation.partner.name,
        email: reservation.partner.email
      } : null,
      notes: reservation.notes,
      feedback: reservation.feedback,
      cancellation: reservation.cancellationReason ? {
        reason: reservation.cancellationReason,
        date: reservation.cancelledAt,
        by: reservation.cancelledBy
      } : null,
      createdAt: reservation.createdAt,
      updatedAt: reservation.updatedAt
    };
  }
}

export const bookingService = new BookingService();
