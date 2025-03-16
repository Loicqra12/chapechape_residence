import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chapechape_client/core/services/booking_service.dart';
import 'package:chapechape_client/core/models/booking_model.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingService _bookingService;

  BookingBloc({required BookingService bookingService})
      : _bookingService = bookingService,
        super(const BookingInitial()) {
    on<LoadUserBookings>(_onLoadUserBookings);
    on<LoadBookingDetails>(_onLoadBookingDetails);
    on<CreateBooking>(_onCreateBooking);
    on<CancelBooking>(_onCancelBooking);
    on<UpdateBooking>(_onUpdateBooking);
    on<CheckResidenceAvailability>(_onCheckResidenceAvailability);
    on<UpdateBookingStatus>(_onUpdateBookingStatus);
  }

  // Charger toutes les réservations de l'utilisateur
  Future<void> _onLoadUserBookings(
    LoadUserBookings event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(const BookingLoading());
      final bookings = await _bookingService.getUserBookings(
        status: event.status,
      );
      emit(UserBookingsLoaded(bookings));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  // Charger les détails d'une réservation spécifique
  Future<void> _onLoadBookingDetails(
    LoadBookingDetails event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(const BookingLoading());
      final booking = await _bookingService.getBookingById(event.bookingId);
      
      // Vérification pour éviter les erreurs de type
      if (booking != null) {
        emit(BookingDetailsLoaded(booking));
      } else {
        emit(const BookingError("Impossible de charger les détails de la réservation: réponse invalide"));
      }
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  // Créer une nouvelle réservation
  Future<void> _onCreateBooking(
    CreateBooking event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(const BookingLoading());
      final booking = await _bookingService.createBooking(
        residenceId: event.residenceId,
        checkIn: event.checkIn,
        checkOut: event.checkOut,
        numberOfGuests: event.numberOfGuests,
        specialRequests: event.specialRequests,
      );
      
      // Gestion défensive pour éviter les erreurs de type
      if (booking != null) {
        emit(BookingCreated(booking));
      } else {
        emit(const BookingError("Impossible de créer la réservation: réponse invalide"));
      }
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  // Annuler une réservation
  Future<void> _onCancelBooking(
    CancelBooking event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(const BookingLoading());
      await _bookingService.cancelBooking(
        id: event.bookingId,
        reason: event.reason,
      );
      emit(BookingCancelled(event.bookingId));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  // Mettre à jour une réservation
  Future<void> _onUpdateBooking(
    UpdateBooking event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(const BookingLoading());
      final booking = await _bookingService.updateBooking(
        id: event.bookingId,
        checkIn: event.checkIn,
        checkOut: event.checkOut,
        numberOfGuests: event.numberOfGuests,
      );
      emit(BookingUpdated(booking));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  // Vérifier la disponibilité d'une résidence
  Future<void> _onCheckResidenceAvailability(
    CheckResidenceAvailability event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(const BookingLoading());
      
      // Implémentez cette méthode dans le service
      final result = await _bookingService.checkAvailability(
        residenceId: event.residenceId,
        checkIn: event.checkIn,
        checkOut: event.checkOut,
      );
      
      emit(ResidenceAvailabilityChecked(
        isAvailable: result['isAvailable'] as bool,
        price: result['price'] as double?,
        availabilityInfo: result,
      ));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  // Mettre à jour le statut d'une réservation
  Future<void> _onUpdateBookingStatus(
    UpdateBookingStatus event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(const BookingLoading());
      
      // Cette méthode doit être implémentée dans le service
      await _bookingService.updateBookingStatus(
        id: event.bookingId,
        status: event.status,
        paymentId: event.paymentId,
      );
      
      emit(BookingStatusUpdated(
        bookingId: event.bookingId,
        status: event.status,
      ));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }
}

