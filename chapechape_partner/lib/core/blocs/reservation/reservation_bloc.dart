import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/reservation/reservation.dart';
import '../../services/api/reservation_service.dart';

// Events
abstract class ReservationEvent {}

class LoadReservations extends ReservationEvent {}

class LoadMyReservations extends ReservationEvent {}

class LoadResidenceReservations extends ReservationEvent {
  final String residenceId;

  LoadResidenceReservations(this.residenceId);
}

class UpdateReservationStatus extends ReservationEvent {
  final String reservationId;
  final ReservationStatus newStatus;

  UpdateReservationStatus(this.reservationId, this.newStatus);
}

class CancelReservation extends ReservationEvent {
  final String reservationId;

  CancelReservation(this.reservationId);
}

// States
abstract class ReservationState {}

class ReservationInitial extends ReservationState {}

class ReservationLoading extends ReservationState {}

class ReservationLoaded extends ReservationState {
  final List<Reservation> reservations;
  final Map<String, List<Reservation>> groupedReservations;

  ReservationLoaded(this.reservations)
      : groupedReservations = _groupReservations(reservations);

  static Map<String, List<Reservation>> _groupReservations(
      List<Reservation> reservations) {
    final grouped = <String, List<Reservation>>{};
    
    // Grouper par statut
    for (final status in ReservationStatus.values) {
      grouped[status.name] = reservations
          .where((r) => r.status == status)
          .toList()
        ..sort((a, b) => b.checkIn.compareTo(a.checkIn));
    }

    return grouped;
  }
}

class ReservationError extends ReservationState {
  final String message;

  ReservationError(this.message);
}

class ReservationBloc extends Bloc<ReservationEvent, ReservationState> {
  final ReservationService _reservationService;

  ReservationBloc(this._reservationService) : super(ReservationInitial()) {
    on<LoadReservations>(_onLoadReservations);
    on<LoadMyReservations>(_onLoadMyReservations);
    on<LoadResidenceReservations>(_onLoadResidenceReservations);
    on<UpdateReservationStatus>(_onUpdateReservationStatus);
    on<CancelReservation>(_onCancelReservation);
  }

  Future<void> _onLoadReservations(
    LoadReservations event,
    Emitter<ReservationState> emit,
  ) async {
    try {
      emit(ReservationLoading());
      final reservations = await _reservationService.getReservations();
      emit(ReservationLoaded(reservations));
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }

  Future<void> _onLoadMyReservations(
    LoadMyReservations event,
    Emitter<ReservationState> emit,
  ) async {
    try {
      emit(ReservationLoading());
      final reservations = await _reservationService.getMyReservations();
      emit(ReservationLoaded(reservations));
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }

  Future<void> _onLoadResidenceReservations(
    LoadResidenceReservations event,
    Emitter<ReservationState> emit,
  ) async {
    try {
      emit(ReservationLoading());
      final reservations = await _reservationService.getResidenceReservations(
        event.residenceId,
      );
      emit(ReservationLoaded(reservations));
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }

  Future<void> _onUpdateReservationStatus(
    UpdateReservationStatus event,
    Emitter<ReservationState> emit,
  ) async {
    try {
      await _reservationService.updateReservationStatus(
        event.reservationId,
        event.newStatus,
      );
      
      // Recharger les réservations pour avoir l'état à jour
      add(LoadReservations());
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }

  Future<void> _onCancelReservation(
    CancelReservation event,
    Emitter<ReservationState> emit,
  ) async {
    try {
      await _reservationService.cancelReservation(event.reservationId);
      
      // Recharger les réservations pour avoir l'état à jour
      add(LoadReservations());
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }
}
