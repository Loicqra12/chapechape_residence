import 'package:equatable/equatable.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

// Événement pour charger toutes les réservations de l'utilisateur
class LoadUserBookings extends BookingEvent {}

// Événement pour charger les détails d'une réservation spécifique
class LoadBookingDetails extends BookingEvent {
  final String bookingId;

  const LoadBookingDetails({required this.bookingId});

  @override
  List<Object?> get props => [bookingId];
}

// Événement pour créer une nouvelle réservation
class CreateBooking extends BookingEvent {
  final Map<String, dynamic> bookingData;

  const CreateBooking({required this.bookingData});

  @override
  List<Object?> get props => [bookingData];
}

// Événement pour annuler une réservation
class CancelBooking extends BookingEvent {
  final String bookingId;
  final String? reason;

  const CancelBooking({
    required this.bookingId,
    this.reason,
  });

  @override
  List<Object?> get props => [bookingId, reason];
}

// Événement pour mettre à jour une réservation existante
class UpdateBooking extends BookingEvent {
  final String bookingId;
  final Map<String, dynamic> updates;

  const UpdateBooking({
    required this.bookingId,
    required this.updates,
  });

  @override
  List<Object?> get props => [bookingId, updates];
}

// Événement pour vérifier la disponibilité d'une résidence pour une période donnée
class CheckResidenceAvailability extends BookingEvent {
  final String residenceId;
  final DateTime checkIn;
  final DateTime checkOut;

  const CheckResidenceAvailability({
    required this.residenceId,
    required this.checkIn,
    required this.checkOut,
  });

  @override
  List<Object?> get props => [residenceId, checkIn, checkOut];
}

// Événement pour mettre à jour le statut d'une réservation après paiement
class UpdateBookingStatus extends BookingEvent {
  final String bookingId;
  final String status;
  final String? paymentId;

  const UpdateBookingStatus({
    required this.bookingId,
    required this.status,
    this.paymentId,
  });

  @override
  List<Object?> get props => [bookingId, status, paymentId];
}

// Événement pour calculer les frais de modification
class CalculateModificationFees extends BookingEvent {
  final String bookingId;
  final DateTime? newCheckIn;
  final DateTime? newCheckOut;
  final int? newNumberOfGuests;

  const CalculateModificationFees({
    required this.bookingId,
    this.newCheckIn,
    this.newCheckOut,
    this.newNumberOfGuests,
  });

  @override
  List<Object?> get props => [bookingId, newCheckIn, newCheckOut, newNumberOfGuests];
}

// Événement pour mettre à jour une réservation avec les frais
class UpdateBookingWithFees extends BookingEvent {
  final String bookingId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int numberOfGuests;
  final double modificationFee;

  const UpdateBookingWithFees({
    required this.bookingId,
    required this.checkIn,
    required this.checkOut,
    required this.numberOfGuests,
    required this.modificationFee,
  });

  @override
  List<Object?> get props => [bookingId, checkIn, checkOut, numberOfGuests, modificationFee];
}
