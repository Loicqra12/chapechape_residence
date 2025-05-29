import 'package:equatable/equatable.dart';
import '../../models/promotion/promotion_model.dart';

/// Événements liés aux promotions
abstract class PromotionEvent extends Equatable {
  const PromotionEvent();

  @override
  List<Object?> get props => [];
}

/// Événement pour charger toutes les promotions
class LoadPromotions extends PromotionEvent {
  final PromotionType? type;
  final bool? exclusive;
  final String? residenceId;
  final bool? active;

  const LoadPromotions({
    this.type,
    this.exclusive,
    this.residenceId,
    this.active,
  });

  @override
  List<Object?> get props => [type, exclusive, residenceId, active];
}

/// Événement pour charger les promotions actives
class LoadActivePromotions extends PromotionEvent {
  const LoadActivePromotions();
}

/// Événement pour charger les promotions exclusives
class LoadExclusivePromotions extends PromotionEvent {
  const LoadExclusivePromotions();
}

/// Événement pour charger les promotions d'une résidence spécifique
class LoadResidencePromotions extends PromotionEvent {
  final String residenceId;

  const LoadResidencePromotions(this.residenceId);

  @override
  List<Object> get props => [residenceId];
}

/// Événement pour charger une promotion spécifique
class LoadPromotionDetails extends PromotionEvent {
  final String promotionId;

  const LoadPromotionDetails(this.promotionId);

  @override
  List<Object> get props => [promotionId];
}

/// Événement pour créer une nouvelle promotion
class CreatePromotion extends PromotionEvent {
  final PromotionModel promotion;

  const CreatePromotion(this.promotion);

  @override
  List<Object> get props => [promotion];
}

/// Événement pour mettre à jour une promotion existante
class UpdatePromotion extends PromotionEvent {
  final String promotionId;
  final PromotionModel promotion;

  const UpdatePromotion({
    required this.promotionId,
    required this.promotion,
  });

  @override
  List<Object> get props => [promotionId, promotion];
}

/// Événement pour supprimer une promotion
class DeletePromotion extends PromotionEvent {
  final String promotionId;

  const DeletePromotion(this.promotionId);

  @override
  List<Object> get props => [promotionId];
}

/// Événement pour rafraîchir les promotions
class RefreshPromotions extends PromotionEvent {
  const RefreshPromotions();
}
