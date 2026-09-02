import '../models/booking/booking.dart';
import '../models/reservation/reservation.dart';
import '../models/residence/residence.dart';
import '../models/user/user.dart';

/// Adaptateur pour convertir un objet Reservation en objet Booking
class BookingAdapter {
  /// Convertit un objet Reservation en objet Booking
  static Booking fromReservation(Reservation reservation) {
    // Créer un objet Residence minimal à partir des données de la réservation
    final residence = Residence(
      id: reservation.residenceId,
      name: reservation.residenceName,
      description: 'Résidence réservée',
      images: [reservation.residenceImage],
      address: 'Adresse non disponible',
      city: 'Ville non disponible',
      price: reservation.totalAmount,
      bedrooms: 1,
      bathrooms: 1,
      surface: 0,
      hasPool: false,
      hasWifi: false,
      hasRestaurant: false,
      isVacationResidence: false,
      isSpecialResidence: false,
      isAvailable: true,
      rating: 0,
      reviewCount: 0,
      type: 'Appartement',
      category: 'Standard',
      createdAt: reservation.createdAt,
      updatedAt: DateTime.now(),
    );

    // Créer un objet User minimal à partir des données du client
    final client = User(
      id: '', // Pas d'ID client disponible dans Reservation
      email: '',
      firstName: reservation.clientName.split(' ').first,
      lastName: reservation.clientName.split(' ').length > 1 
          ? reservation.clientName.split(' ').last 
          : '',
      phoneNumber: reservation.clientPhone,
      role: 'client',
      createdAt: reservation.createdAt,
    );

    // Convertir l'enum ReservationStatus en chaîne de caractères pour Booking
    final bookingStatus = reservation.status.toBackendFormat();

    // Extraire l'heure de visite de la date checkIn
    final visitTime = '${reservation.checkIn.hour.toString().padLeft(2, '0')}:${reservation.checkIn.minute.toString().padLeft(2, '0')}';

    // Créer l'objet Booking
    return Booking(
      id: reservation.id,
      residenceId: reservation.residenceId,
      clientId: '',  // Pas d'ID client disponible dans Reservation
      partnerId: '', // Pas d'ID partenaire disponible dans Reservation
      status: bookingStatus,
      visitDate: reservation.checkIn,
      visitTime: visitTime,
      createdAt: reservation.createdAt,
      notes: reservation.notes,
      metadata: {
        'totalAmount': reservation.totalAmount,
        'checkOut': reservation.checkOut.toIso8601String(),
        'guestsCount': reservation.guestsCount,
      },
      residence: residence,
      client: client,
      partner: null,
    );
  }
}
