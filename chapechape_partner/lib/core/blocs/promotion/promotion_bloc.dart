import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/promotion_service.dart';
import 'promotion_event.dart';
import 'promotion_state.dart';

/// BLoC pour gérer les opérations et l'état des promotions
class PromotionBloc extends Bloc<PromotionEvent, PromotionState> {
  final PromotionService _promotionService;
  
  PromotionBloc({required PromotionService promotionService}) 
      : _promotionService = promotionService,
        super(const PromotionInitial()) {
    on<LoadPromotions>(_onLoadPromotions);
    on<LoadActivePromotions>(_onLoadActivePromotions);
    on<LoadExclusivePromotions>(_onLoadExclusivePromotions);
    on<LoadResidencePromotions>(_onLoadResidencePromotions);
    on<LoadPromotionDetails>(_onLoadPromotionDetails);
    on<CreatePromotion>(_onCreatePromotion);
    on<UpdatePromotion>(_onUpdatePromotion);
    on<DeletePromotion>(_onDeletePromotion);
    on<RefreshPromotions>(_onRefreshPromotions);
  }
  
  /// Gère l'événement de chargement des promotions avec filtres optionnels
  Future<void> _onLoadPromotions(
    LoadPromotions event,
    Emitter<PromotionState> emit,
  ) async {
    emit(const PromotionsLoading());
    try {
      final promotions = await _promotionService.getPromotions(
        type: event.type,
        exclusive: event.exclusive,
        residenceId: event.residenceId,
        active: event.active,
      );
      emit(PromotionsLoaded(
        promotions: promotions,
        isActive: event.active,
        isExclusive: event.exclusive,
        residenceId: event.residenceId,
        type: event.type,
      ));
    } catch (e) {
      emit(PromotionError(message: 'Impossible de charger les promotions: $e'));
    }
  }
  
  /// Gère l'événement de chargement des promotions actives
  Future<void> _onLoadActivePromotions(
    LoadActivePromotions event,
    Emitter<PromotionState> emit,
  ) async {
    emit(const PromotionsLoading());
    try {
      final promotions = await _promotionService.getActivePromotions();
      emit(PromotionsLoaded(
        promotions: promotions,
        isActive: true,
      ));
    } catch (e) {
      emit(PromotionError(message: 'Impossible de charger les promotions actives: $e'));
    }
  }
  
  /// Gère l'événement de chargement des promotions exclusives
  Future<void> _onLoadExclusivePromotions(
    LoadExclusivePromotions event,
    Emitter<PromotionState> emit,
  ) async {
    emit(const PromotionsLoading());
    try {
      final promotions = await _promotionService.getExclusivePromotions();
      emit(PromotionsLoaded(
        promotions: promotions,
        isExclusive: true,
      ));
    } catch (e) {
      emit(PromotionError(message: 'Impossible de charger les promotions exclusives: $e'));
    }
  }
  
  /// Gère l'événement de chargement des promotions pour une résidence spécifique
  Future<void> _onLoadResidencePromotions(
    LoadResidencePromotions event,
    Emitter<PromotionState> emit,
  ) async {
    emit(const PromotionsLoading());
    try {
      final promotions = await _promotionService.getResidencePromotions(event.residenceId);
      emit(PromotionsLoaded(
        promotions: promotions,
        residenceId: event.residenceId,
      ));
    } catch (e) {
      emit(PromotionError(message: 'Impossible de charger les promotions pour cette résidence: $e'));
    }
  }
  
  /// Gère l'événement de chargement d'une promotion spécifique par son ID
  Future<void> _onLoadPromotionDetails(
    LoadPromotionDetails event,
    Emitter<PromotionState> emit,
  ) async {
    emit(const PromotionsLoading());
    try {
      final promotion = await _promotionService.getPromotion(event.promotionId);
      emit(PromotionDetailsLoaded(promotion: promotion));
    } catch (e) {
      emit(PromotionError(message: 'Impossible de charger cette promotion: $e'));
    }
  }
  
  /// Gère l'événement de création d'une nouvelle promotion
  Future<void> _onCreatePromotion(
    CreatePromotion event,
    Emitter<PromotionState> emit,
  ) async {
    emit(const PromotionsLoading());
    try {
      final createdPromotion = await _promotionService.createPromotion(event.promotion);
      emit(PromotionCreated(promotion: createdPromotion));
      
      // Recharger la liste des promotions après création
      add(const RefreshPromotions());
    } catch (e) {
      emit(PromotionError(message: 'Impossible de créer la promotion: $e'));
    }
  }
  
  /// Gère l'événement de mise à jour d'une promotion existante
  Future<void> _onUpdatePromotion(
    UpdatePromotion event,
    Emitter<PromotionState> emit,
  ) async {
    emit(const PromotionsLoading());
    try {
      final updatedPromotion = await _promotionService.updatePromotion(
        event.promotionId,
        event.promotion,
      );
      emit(PromotionUpdated(promotion: updatedPromotion));
      
      // Recharger la liste des promotions après mise à jour
      add(const RefreshPromotions());
    } catch (e) {
      emit(PromotionError(message: 'Impossible de mettre à jour la promotion: $e'));
    }
  }
  
  /// Gère l'événement de suppression d'une promotion
  Future<void> _onDeletePromotion(
    DeletePromotion event,
    Emitter<PromotionState> emit,
  ) async {
    try {
      await _promotionService.deletePromotion(event.promotionId);
      emit(PromotionDeleted(promotionId: event.promotionId));
      
      // Recharger la liste des promotions après suppression
      add(const RefreshPromotions());
    } catch (e) {
      emit(PromotionError(message: 'Impossible de supprimer la promotion: $e'));
    }
  }
  
  /// Gère l'événement de rafraîchissement des promotions
  Future<void> _onRefreshPromotions(
    RefreshPromotions event,
    Emitter<PromotionState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is PromotionsLoaded) {
      // Recharger avec les mêmes filtres
      add(LoadPromotions(
        type: currentState.type,
        exclusive: currentState.isExclusive,
        residenceId: currentState.residenceId,
        active: currentState.isActive,
      ));
    } else {
      // Si aucun filtre spécifique, charger toutes les promotions
      add(const LoadPromotions());
    }
  }
}
