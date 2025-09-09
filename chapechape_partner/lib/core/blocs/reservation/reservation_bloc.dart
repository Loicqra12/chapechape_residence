import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/reservation/reservation.dart';
import '../../services/api/reservation_service.dart';

// Events
abstract class ReservationEvent {}

class LoadReservations extends ReservationEvent {}

class LoadMyReservations extends ReservationEvent {}

class LoadPartnerReservations extends ReservationEvent {}

class LoadResidenceReservations extends ReservationEvent {
  final String residenceId;

  LoadResidenceReservations(this.residenceId);
}

// Nouvel événement pour charger les détails d'une réservation spécifique
class LoadReservationDetails extends ReservationEvent {
  final String reservationId;

  LoadReservationDetails(this.reservationId);
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

// Nouvel événement pour ajouter une note à une réservation
class AddReservationNote extends ReservationEvent {
  final String reservationId;
  final String note;

  AddReservationNote(this.reservationId, this.note);
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

// Nouvel état pour les détails d'une réservation spécifique
class ReservationDetailsLoaded extends ReservationState {
  final Reservation reservation;

  ReservationDetailsLoaded(this.reservation);
}

class ReservationError extends ReservationState {
  final String message;

  ReservationError(this.message);
}

class ReservationBloc extends Bloc<ReservationEvent, ReservationState> {
  final ReservationService _reservationService;

  // ✅ AJOUT : Getter public pour accès au service depuis les écrans
  ReservationService get reservationService => _reservationService;

  ReservationBloc(this._reservationService) : super(ReservationInitial()) {
    on<LoadReservations>(_onLoadReservations);
    on<LoadMyReservations>(_onLoadMyReservations);
    on<LoadPartnerReservations>(_onLoadPartnerReservations);
    on<LoadResidenceReservations>(_onLoadResidenceReservations);
    on<UpdateReservationStatus>(_onUpdateReservationStatus);
    on<CancelReservation>(_onCancelReservation);
    // Nouveaux gestionnaires d'événements
    on<LoadReservationDetails>(_onLoadReservationDetails);
    on<AddReservationNote>(_onAddReservationNote);
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

  Future<void> _onLoadPartnerReservations(
    LoadPartnerReservations event,
    Emitter<ReservationState> emit,
  ) async {
    try {
      emit(ReservationLoading());
      
      // Utiliser d'abord la méthode directe qui utilise le nouvel endpoint
      List<Reservation> reservations = await _reservationService.getPartnerReservationsDirect();
      
      // Si ça échoue, revenir à la méthode indirecte
      if (reservations.isEmpty) {
        print("Utilisation de la méthode indirecte pour récupérer les réservations...");
        reservations = await _reservationService.getPartnerReservations();
      }
      
      print("Réservations partenaire chargées: ${reservations.length}");
      emit(ReservationLoaded(reservations));
    } catch (e) {
      print("Erreur lors du chargement des réservations partenaire: $e");
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
      
      // Recharger les détails de la réservation pour avoir l'état à jour
      // au lieu de recharger toutes les réservations
      final currentState = state;
      if (currentState is ReservationDetailsLoaded) {
        add(LoadReservationDetails(event.reservationId));
      } else {
        add(LoadMyReservations());
      }
    } catch (e) {
      // ✅ Gestion d'erreurs améliorée avec messages spécifiques
      String errorMessage = e.toString();
      
      // Nettoyer le message d'erreur pour l'affichage
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      
      // Messages d'erreur spécifiques selon le type
      if (errorMessage.contains('paiement requis')) {
        errorMessage = 'Paiement requis avant de confirmer cette réservation';
      } else if (errorMessage.contains('Transition d\'état invalide')) {
        errorMessage = 'Action impossible : l\'état de la réservation a changé';
      } else if (errorMessage.contains('pas autorisé')) {
        errorMessage = 'Vous n\'avez pas les droits pour modifier cette réservation';
      }
      
      emit(ReservationError(errorMessage));
    }
  }

  Future<void> _onCancelReservation(
    CancelReservation event,
    Emitter<ReservationState> emit,
  ) async {
    try {
      await _reservationService.cancelReservation(
        event.reservationId,
        'Annulée depuis l\'application partenaire'
      );
      
      // Recharger selon l'état actuel
      final currentState = state;
      if (currentState is ReservationDetailsLoaded) {
        add(LoadReservationDetails(event.reservationId));
      } else {
        add(LoadMyReservations());
      }
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }

  // Ajouter la nouvelle méthode pour charger les détails d'une réservation
  Future<void> _onLoadReservationDetails(
    LoadReservationDetails event,
    Emitter<ReservationState> emit,
  ) async {
    try {
      emit(ReservationLoading());
      final reservation = await _reservationService.getReservation(event.reservationId);
      
      if (reservation != null) {
        emit(ReservationDetailsLoaded(reservation));
      } else {
        emit(ReservationError('Réservation non trouvée'));
      }
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }

  // Ajouter la nouvelle méthode pour ajouter une note à une réservation
  Future<void> _onAddReservationNote(
    AddReservationNote event,
    Emitter<ReservationState> emit,
  ) async {
    try {
      emit(ReservationLoading());
      
      try {
        await _reservationService.addNote(event.reservationId, event.note);
      } catch (e) {
        print("Erreur lors de l'ajout de la note: $e");
        // Continuer même si l'ajout de note échoue
      }
      
      // Recharger la réservation pour avoir les données à jour
      final reservation = await _reservationService.getReservation(event.reservationId);
      
      if (reservation != null) {
        emit(ReservationDetailsLoaded(reservation));
      } else {
        emit(ReservationError('Impossible de recharger les détails de la réservation'));
      }
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }
}
