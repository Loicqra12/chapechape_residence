import 'package:equatable/equatable.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

// Événement pour charger toutes les réservations de l'utilisateur
class LoadUserBookings extends BookingEvent {
  final String? status; // Optional filter for booking status

  const LoadUserBookings({this.status});

  @override
  List<Object?> get props => [status];
}

// Événement pour charger les détails d'une réservation spécifique
class LoadBookingDetails extends BookingEvent {
  final String bookingId;

  const LoadBookingDetails({required this.bookingId});

  @override
  List<Object?> get props => [bookingId];
}

// Événement pour créer une nouvelle réservation
class CreateBooking extends BookingEvent {
  final String residenceId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int numberOfGuests;
  final double totalPrice;
  final String? specialRequests;

  const CreateBooking({
    required this.residenceId,
    required this.checkIn,
    required this.checkOut,
    required this.numberOfGuests,
    required this.totalPrice,
    this.specialRequests,
  });

  @override
  List<Object?> get props => [residenceId, checkIn, checkOut, numberOfGuests, totalPrice, specialRequests];
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
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? numberOfGuests;

  const UpdateBooking({
    required this.bookingId,
    this.checkIn,
    this.checkOut,
    this.numberOfGuests,
  });

  @override
  List<Object?> get props => [bookingId, checkIn, checkOut, numberOfGuests];
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
