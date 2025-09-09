import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chapechape_client/core/services/booking_service.dart';
import 'package:chapechape_client/core/services/socket_service.dart';
import 'package:chapechape_client/core/models/booking_model.dart';
import 'package:chapechape_client/core/models/modification_fees_model.dart';
import 'package:chapechape_client/core/models/residence_model.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingService _bookingService;
  final SocketService _socketService = SocketService();

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
    on<CalculateModificationFees>(_onCalculateModificationFees);
    on<UpdateBookingWithFees>(_onUpdateBookingWithFees);
    
    // Event handlers WebSocket pour transitions temps réel
    on<BookingExpiredEvent>(_onBookingExpired);
    on<BookingApprovedEvent>(_onBookingApproved);
    on<BookingRejectedEvent>(_onBookingRejected);
    
    // Configurer les callbacks WebSocket pour les transitions temps réel
    _setupWebSocketCallbacks();
  }

  // Charger toutes les réservations de l'utilisateur
  Future<void> _onLoadUserBookings(
    LoadUserBookings event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(const BookingLoading());
      final bookings = await _bookingService.getUserBookings();
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
      final booking = await _bookingService.getBookingDetails(event.bookingId);
      final policy = await _bookingService.getCancellationPolicy(booking.cancellationPolicyId);
      emit(BookingDetailsLoaded(booking, policy));
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
        residenceId: event.bookingData['residence'] ?? event.bookingData['residenceId'],
        checkIn: event.bookingData['checkIn'],
        checkOut: event.bookingData['checkOut'],
        numberOfGuests: event.bookingData['numberOfGuests'],
        specialRequests: event.bookingData['specialRequests'],
      );
      emit(BookingCreated(booking));
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
      final booking = await _bookingService.getBookingDetails(event.bookingId);
      emit(BookingCancelled(booking));
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
        checkIn: event.updates['checkIn'],
        checkOut: event.updates['checkOut'],
        numberOfGuests: event.updates['numberOfGuests'],
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

  // Calculer les frais de modification
  Future<void> _onCalculateModificationFees(
    CalculateModificationFees event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(const BookingLoading());
      final fees = await _bookingService.calculateModificationFees(
        bookingId: event.bookingId,
        newCheckIn: event.newCheckIn,
        newCheckOut: event.newCheckOut,
        newNumberOfGuests: event.newNumberOfGuests,
      );
      emit(ModificationFeesCalculated(fees));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  // Mettre à jour une réservation avec les frais
  Future<void> _onUpdateBookingWithFees(
    UpdateBookingWithFees event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(const BookingLoading());
      final booking = await _bookingService.updateBookingWithFees(
        id: event.bookingId,
        checkIn: event.checkIn,
        checkOut: event.checkOut,
        numberOfGuests: event.numberOfGuests,
        modificationFee: event.modificationFee,
      );

      // Recalculer les frais pour l'affichage final
      final fees = await _bookingService.calculateModificationFees(
        bookingId: event.bookingId,
        newCheckIn: event.checkIn,
        newCheckOut: event.checkOut,
        newNumberOfGuests: event.numberOfGuests,
      );

      emit(BookingUpdatedWithFees(
        booking: booking,
        fees: fees,
      ));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  /// Configure les callbacks WebSocket pour les transitions temps réel
  void _setupWebSocketCallbacks() {
    _socketService.setBookingCallbacks(
      onStatusUpdated: (data) {
        // Recharger les réservations quand un statut change
        add(LoadUserBookings());
      },
      onExpired: (data) {
        // Gérer l'expiration d'une réservation
        final bookingId = data['bookingId'] as String?;
        if (bookingId != null) {
          add(LoadUserBookings());
          // Dispatch event spécifique pour l'expiration
          add(BookingExpiredEvent(bookingId));
        }
      },
      onApproved: (data) {
        // Gérer l'approbation d'une réservation
        final bookingId = data['bookingId'] as String?;
        if (bookingId != null) {
          add(LoadUserBookings());
          // Dispatch event spécifique pour l'approbation
          add(BookingApprovedEvent(bookingId));
        }
      },
      onRejected: (data) {
        // Gérer le rejet d'une réservation
        final bookingId = data['bookingId'] as String?;
        if (bookingId != null) {
          add(LoadUserBookings());
          // Dispatch event spécifique pour le rejet
          add(BookingRejectedEvent(bookingId));
        }
      },
    );
  }

  /// Rejoindre la salle WebSocket pour une réservation spécifique
  void joinBookingRoom(String bookingId) {
    _socketService.joinBookingRoom(bookingId);
  }

  /// Quitter la salle WebSocket pour une réservation
  void leaveBookingRoom(String bookingId) {
    _socketService.leaveBookingRoom(bookingId);
  }

  // Event handlers WebSocket pour transitions temps réel
  
  /// Gérer l'expiration d'une réservation (timer SLA ou paiement)
  Future<void> _onBookingExpired(
    BookingExpiredEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(BookingExpired(event.bookingId));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  /// Gérer l'approbation d'une réservation par l'hôte
  Future<void> _onBookingApproved(
    BookingApprovedEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(BookingApproved(event.bookingId));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  /// Gérer le rejet d'une réservation par l'hôte
  Future<void> _onBookingRejected(
    BookingRejectedEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(BookingRejected(event.bookingId));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _socketService.clearBookingCallbacks();
    return super.close();
  }
}
