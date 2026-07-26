import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/reservation/reservation.dart';
import '../../services/api/reservation_service.dart';
import 'package:chapechape_partner/core/utils/app_logger.dart';

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

// Événements pour le filtrage et le tri des réservations
class FilterReservations extends ReservationEvent {
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;

  FilterReservations({this.status, this.startDate, this.endDate});
}

class SortReservations extends ReservationEvent {
  final String sortBy;
  final bool ascending;

  SortReservations(this.sortBy, {this.ascending = true});
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
    on<FilterReservations>(_onFilterReservations);
    on<SortReservations>(_onSortReservations);
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
        AppLogger.d("Utilisation de la méthode indirecte pour récupérer les réservations...");
        reservations = await _reservationService.getPartnerReservations();
      }
      
      AppLogger.d("Réservations partenaire chargées: ${reservations.length}");
      emit(ReservationLoaded(reservations));
    } catch (e) {
      AppLogger.d("Erreur lors du chargement des réservations partenaire: $e");
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
        add(LoadPartnerReservations());
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
        errorMessage =
            'Paiement requis avant de continuer cette réservation';
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
        add(LoadPartnerReservations());
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

  Future<void> _onAddReservationNote(
    AddReservationNote event,
    Emitter<ReservationState> emit,
  ) async {
    try {
      emit(ReservationLoading());

      await _reservationService.addNote(event.reservationId, event.note);

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

  Future<void> _onFilterReservations(
    FilterReservations event,
    Emitter<ReservationState> emit,
  ) async {
    try {
      emit(ReservationLoading());
      
      // Récupérer toutes les réservations
      final allReservations = await _reservationService.getPartnerReservations();
      
      // Appliquer les filtres
      List<Reservation> filteredReservations = allReservations;
      
      if (event.status != null && event.status != 'all') {
        final status = ReservationStatus.values.firstWhere(
          (s) => s.name == event.status,
          orElse: () => ReservationStatus.pending,
        );
        filteredReservations = filteredReservations
            .where((r) => r.status == status)
            .toList();
      }
      
      if (event.startDate != null) {
        filteredReservations = filteredReservations
            .where((r) => r.checkIn.isAfter(event.startDate!) || 
                         r.checkIn.isAtSameMomentAs(event.startDate!))
            .toList();
      }
      
      if (event.endDate != null) {
        filteredReservations = filteredReservations
            .where((r) => r.checkOut.isBefore(event.endDate!) || 
                         r.checkOut.isAtSameMomentAs(event.endDate!))
            .toList();
      }
      
      emit(ReservationLoaded(filteredReservations));
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }

  Future<void> _onSortReservations(
    SortReservations event,
    Emitter<ReservationState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! ReservationLoaded) {
        return;
      }
      
      List<Reservation> sortedReservations = List.from(currentState.reservations);
      
      // Appliquer le tri selon le critère sélectionné
      switch (event.sortBy) {
        case 'created':
          sortedReservations.sort((a, b) {
            final comparison = a.createdAt.compareTo(b.createdAt);
            return event.ascending ? comparison : -comparison;
          });
          break;
        case 'date':
          sortedReservations.sort((a, b) {
            final comparison = a.checkIn.compareTo(b.checkIn);
            return event.ascending ? comparison : -comparison;
          });
          break;
        case 'amount':
          sortedReservations.sort((a, b) {
            final comparison = a.totalAmount.compareTo(b.totalAmount);
            return event.ascending ? comparison : -comparison;
          });
          break;
        default:
          // Tri par défaut par date de création (plus récent)
          sortedReservations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      
      emit(ReservationLoaded(sortedReservations));
    } catch (e) {
      emit(ReservationError(e.toString()));
    }
  }
}
