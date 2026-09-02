import * as XLSX from 'xlsx';
import React from 'react';
import { pdf, Document, Page, Text, View, StyleSheet } from '@react-pdf/renderer';
import { opsService, mapOpsReservation } from './opsService';

class BookingService {
  async getBookings({ page = 1, limit = 10, sort, filters = {} }) {
    return opsService.listReservations({ page, limit, sort, filters });
  }

  async getBookingById(id) {
    return opsService.getReservation(id);
  }

  async confirmBooking() {
    throw new Error("La confirmation libre n'est plus disponible. Utilisez les actions Ops du Backend.");
  }

  async cancelBooking(id, reason) {
    return opsService.cancelReservation(id, reason || 'Annulation Ops Dashboard');
  }

  async completeBooking(id) {
    return opsService.checkoutReservation(id, 'Check-out Ops Dashboard');
  }

  async checkInReservation(id) {
    return opsService.checkinReservation(id, 'Check-in Ops Dashboard');
  }

  async bulkUpdateStatus() {
    throw new Error('Les mises à jour groupées de statut sont désactivées. Utilisez une action Ops par réservation.');
  }

  _transformReservation(reservation) {
    return mapOpsReservation(reservation);
  }

  async exportBookingsExcel(filters = {}) {
    const { bookings } = await this.getBookings({ page: 1, limit: 100, filters });

    const rows = bookings.map((b) => ({
      'Date': b.checkIn ? new Date(b.checkIn).toISOString().slice(0, 10) : '',
      'Statut': b.status || '',
      'Paiement': b.paymentStatus || '',
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
    const { bookings } = await this.getBookings({ page: 1, limit: 100, filters });

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
                <Text style={styles.cell}>{b.checkIn ? new Date(b.checkIn).toISOString().slice(0, 10) : ''}</Text>
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
}

export const bookingService = new BookingService();
