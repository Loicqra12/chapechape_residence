import 'package:equatable/equatable.dart';

/// Événements liés aux favoris
abstract class FavoriteEvent extends Equatable {
  const FavoriteEvent();

  @override
  List<Object> get props => [];
}

/// Événement pour charger tous les favoris du partenaire
class LoadFavorites extends FavoriteEvent {
  const LoadFavorites();
}

/// Événement pour ajouter une résidence aux favoris
class AddToFavorites extends FavoriteEvent {
  final String residenceId;

  const AddToFavorites({required this.residenceId});

  @override
  List<Object> get props => [residenceId];
}

/// Événement pour supprimer une résidence des favoris
class RemoveFromFavorites extends FavoriteEvent {
  final String favoriteId;

  const RemoveFromFavorites({required this.favoriteId});

  @override
  List<Object> get props => [favoriteId];
}

/// Événement pour vérifier si une résidence est en favoris
class CheckFavoriteStatus extends FavoriteEvent {
  final String residenceId;

  const CheckFavoriteStatus({required this.residenceId});

  @override
  List<Object> get props => [residenceId];
}

/// Événement pour rafraîchir la liste des favoris
class RefreshFavorites extends FavoriteEvent {
  const RefreshFavorites();
}
