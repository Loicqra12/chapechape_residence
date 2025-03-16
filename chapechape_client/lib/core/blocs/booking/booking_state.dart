import 'package:equatable/equatable.dart';
import 'package:chapechape_client/core/models/booking_model.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

// État initial
class BookingInitial extends BookingState {
  const BookingInitial();
}

// État de chargement
class BookingLoading extends BookingState {
  const BookingLoading();
}

// État lorsque les réservations de l'utilisateur sont chargées
class UserBookingsLoaded extends BookingState {
  final List<Booking> bookings;

  const UserBookingsLoaded(this.bookings);

  @override
  List<Object?> get props => [bookings];
}

// État lorsque les détails d'une réservation sont chargés
class BookingDetailsLoaded extends BookingState {
  final Booking booking;

  const BookingDetailsLoaded(this.booking);

  @override
  List<Object?> get props => [booking];
}

// État lorsqu'une réservation est créée avec succès
class BookingCreated extends BookingState {
  final Booking booking;

  const BookingCreated(this.booking);

  @override
  List<Object?> get props => [booking];
}

// État lorsqu'une réservation est annulée avec succès
class BookingCancelled extends BookingState {
  final String bookingId;

  const BookingCancelled(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

// État lorsqu'une réservation est mise à jour avec succès
class BookingUpdated extends BookingState {
  final Booking booking;

  const BookingUpdated(this.booking);

  @override
  List<Object?> get props => [booking];
}

// État lorsque la disponibilité d'une résidence est vérifiée
class ResidenceAvailabilityChecked extends BookingState {
  final bool isAvailable;
  final double? price;
  final Map<String, dynamic>? availabilityInfo;

  const ResidenceAvailabilityChecked({
    required this.isAvailable,
    this.price,
    this.availabilityInfo,
  });

  @override
  List<Object?> get props => [isAvailable, price, availabilityInfo];
}

// État de mise à jour du statut de réservation
class BookingStatusUpdated extends BookingState {
  final String bookingId;
  final String status;

  const BookingStatusUpdated({
    required this.bookingId,
    required this.status,
  });

  @override
  List<Object?> get props => [bookingId, status];
}

// État d'erreur
class BookingError extends BookingState {
  final String message;

  const BookingError(this.message);

  @override
  List<Object?> get props => [message];
}

