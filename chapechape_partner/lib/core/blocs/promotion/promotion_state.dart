import 'package:equatable/equatable.dart';
import '../../models/promotion/promotion_model.dart';

/// États liés aux promotions
abstract class PromotionState extends Equatable {
  const PromotionState();
  
  @override
  List<Object?> get props => [];
}

/// État initial
class PromotionInitial extends PromotionState {
  const PromotionInitial();
}

/// État de chargement des promotions
class PromotionsLoading extends PromotionState {
  const PromotionsLoading();
}

/// État quand les promotions sont chargées
class PromotionsLoaded extends PromotionState {
  final List<PromotionModel> promotions;
  final bool? isActive;
  final bool? isExclusive;
  final String? residenceId;
  final PromotionType? type;
  
  const PromotionsLoaded({
    required this.promotions,
    this.isActive,
    this.isExclusive,
    this.residenceId,
    this.type,
  });
  
  @override
  List<Object?> get props => [promotions, isActive, isExclusive, residenceId, type];
}

/// État quand une promotion spécifique est chargée
class PromotionDetailsLoaded extends PromotionState {
  final PromotionModel promotion;
  
  const PromotionDetailsLoaded({required this.promotion});
  
  @override
  List<Object> get props => [promotion];
}

/// État après la création d'une promotion
class PromotionCreated extends PromotionState {
  final PromotionModel promotion;
  
  const PromotionCreated({required this.promotion});
  
  @override
  List<Object> get props => [promotion];
}

/// État après la mise à jour d'une promotion
class PromotionUpdated extends PromotionState {
  final PromotionModel promotion;
  
  const PromotionUpdated({required this.promotion});
  
  @override
  List<Object> get props => [promotion];
}

/// État après la suppression d'une promotion
class PromotionDeleted extends PromotionState {
  final String promotionId;
  
  const PromotionDeleted({required this.promotionId});
  
  @override
  List<Object> get props => [promotionId];
}

/// État d'erreur
class PromotionError extends PromotionState {
  final String message;
  
  const PromotionError({required this.message});
  
  @override
  List<Object> get props => [message];
}
