import axios from 'axios';
import { API_URL } from '../config';
import * as XLSX from 'xlsx';
import React from 'react';
import { pdf, Document, Page, Text, View, StyleSheet } from '@react-pdf/renderer';

class BookingService {
  getAuthHeader() {
    const token = localStorage.getItem('token');
    return {
      headers: {
        Authorization: `Bearer ${token}`
      }
    };
  }

  async getBookings({ page = 1, limit = 10, sort, filters = {} }) {
    try {
      // Pour le moment, utiliser my-reservations
      // TODO: Implémenter une route admin spécifique pour toutes les réservations
      const response = await axios.get(`${API_URL}/reservations/my-reservations`, {
        ...this.getAuthHeader()
      });

      // Réponse directe depuis reservations endpoint
      const reservations = response.data.data || response.data || [];
      
      const mappedBookings = reservations.map(reservation => ({
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
      }));

      // Filtrage côté client (le backend renvoie déjà selon le rôle, mais pas selon filters)
      const normalizedStatusFilter = filters?.status;
      const shouldFilterByStatus = normalizedStatusFilter && normalizedStatusFilter !== '';
      const statusSet = Array.isArray(normalizedStatusFilter)
        ? new Set(normalizedStatusFilter)
        : shouldFilterByStatus
          ? new Set([normalizedStatusFilter])
          : null;

      const startDate = filters?.startDate ? new Date(filters.startDate) : null;
      const endDate = filters?.endDate ? new Date(filters.endDate) : null;
      const endDateInclusive = endDate ? new Date(endDate.getTime() + 24 * 60 * 60 * 1000 - 1) : null;

      const searchQuery = String(filters?.searchQuery || '').trim().toLowerCase();

      const filteredBookings = mappedBookings.filter((b) => {
        const visitDt = b.visitDate ? new Date(b.visitDate) : null;
        if (shouldFilterByStatus && statusSet && visitDt && !statusSet.has(b.status)) {
          return false;
        }

        if (startDate && visitDt && visitDt < startDate) {
          return false;
        }
        if (endDateInclusive && visitDt && visitDt > endDateInclusive) {
          return false;
        }

        if (searchQuery) {
          const residenceTitle = (b.residence?.title || '').toLowerCase();
          const clientName = (b.client?.name || '').toLowerCase();
          if (!residenceTitle.includes(searchQuery) && !clientName.includes(searchQuery)) {
            return false;
          }
        }

        return true;
      });

      return {
        bookings: filteredBookings.slice(0, limit),
        // Pagination simple pour le fallback
        total: filteredBookings.length,
        pages: 1,
        page: 1,
        limit: filteredBookings.length
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
      // Statut via le routeur dédié (/status)
      const response = await axios.patch(
        `${API_URL}/reservations/${id}/status`,
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
      // Utilise l'endpoint /cancel (le backend attend { reason })
      const response = await axios.patch(
        `${API_URL}/reservations/${id}/cancel`,
        { reason },
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
      // Checkout pour marquer completed + set actualCheckOut côté backend
      const response = await axios.patch(
        `${API_URL}/reservations/${id}/checkout`,
        {},
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
      const promises = ids.map(async (id) => {
        if (status === 'confirmed') return this.confirmBooking(id);
        if (status === 'cancelled') return this.cancelBooking(id, 'Bulk cancel');
        if (status === 'completed') return this.completeBooking(id);
        return null;
      });
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

  async exportBookingsExcel(filters = {}) {
    const { bookings } = await this.getBookings({ page: 1, limit: 1000, filters });

    const rows = bookings.map((b) => ({
      'Date': b.visitDate ? new Date(b.visitDate).toISOString().slice(0, 10) : '',
      'Heure': b.visitTime || '',
      'Statut': b.status || '',
      'Résidence': b.residence?.title || '',
      'Client': b.client?.name || '',
      'Email': b.client?.email || '',
      'Partenaire': b.partner?.name || ''
    }));

    const ws = XLSX.utils.json_to_sheet(rows);
    const wb = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(wb, ws, 'Réservations');

    const arrayBuffer = XLSX.write(wb, { bookType: 'xlsx', type: 'array' });
    return new Blob([arrayBuffer], {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    });
  }

  async exportBookingsPDF(filters = {}) {
    const { bookings } = await this.getBookings({ page: 1, limit: 1000, filters });

    const styles = StyleSheet.create({
      page: { padding: 24 },
      title: { fontSize: 18, marginBottom: 16 },
      section: { marginBottom: 10 },
      row: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 6 },
      cell: { fontSize: 10, flexGrow: 1 }
    });

    const PDFDocument = ({ data }) => (
      <Document>
        <Page size="A4" style={styles.page}>
          <Text style={styles.title}>Réservations</Text>
          {data.map((b, idx) => (
            <View key={b._id || idx} style={styles.section}>
              <View style={styles.row}>
                <Text style={styles.cell}>{b.visitDate ? new Date(b.visitDate).toISOString().slice(0, 10) : ''}</Text>
                <Text style={styles.cell}>{b.visitTime || ''}</Text>
                <Text style={styles.cell}>{b.status || ''}</Text>
              </View>
              <View style={styles.row}>
                <Text style={styles.cell}>Residence: {b.residence?.title || '-'}</Text>
              </View>
              <View style={styles.row}>
                <Text style={styles.cell}>Client: {b.client?.name || '-'}</Text>
              </View>
            </View>
          ))}
        </Page>
      </Document>
    );

    const blob = await pdf(<PDFDocument data={bookings} />).toBlob();
    return blob;
  }

  async checkInReservation(id) {
    try {
      const response = await axios.patch(
        `${API_URL}/reservations/${id}/checkin`,
        {},
        this.getAuthHeader()
      );
      return this._transformReservation(response.data.data || response.data);
    } catch (error) {
      if (error.response?.status === 401) {
        window.location.href = '/login';
        throw new Error("Session expirée, veuillez vous reconnecter");
      }
      console.error('Erreur lors du check-in:', error);
      throw new Error("Erreur lors du check-in");
    }
  }
}

export const bookingService = new BookingService();
