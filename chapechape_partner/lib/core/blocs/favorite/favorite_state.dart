import 'package:equatable/equatable.dart';
import '../../models/favorite/favorite_model.dart';

/// États liés aux favoris
abstract class FavoriteState extends Equatable {
  const FavoriteState();
  
  @override
  List<Object?> get props => [];
}

/// État initial
class FavoriteInitial extends FavoriteState {
  const FavoriteInitial();
}

/// État de chargement des favoris
class FavoritesLoading extends FavoriteState {
  const FavoritesLoading();
}

/// État quand les favoris sont chargés
class FavoritesLoaded extends FavoriteState {
  final List<FavoriteModel> favorites;
  
  const FavoritesLoaded({required this.favorites});
  
  @override
  List<Object> get props => [favorites];
}

/// État de vérification du statut de favori
class FavoriteStatusChecked extends FavoriteState {
  final bool isFavorite;
  final String residenceId;
  
  const FavoriteStatusChecked({
    required this.isFavorite,
    required this.residenceId,
  });
  
  @override
  List<Object> get props => [isFavorite, residenceId];
}

/// État après avoir ajouté un favori
class FavoriteAdded extends FavoriteState {
  final FavoriteModel favorite;
  
  const FavoriteAdded({required this.favorite});
  
  @override
  List<Object> get props => [favorite];
}

/// État après avoir supprimé un favori
class FavoriteRemoved extends FavoriteState {
  final String favoriteId;
  
  const FavoriteRemoved({required this.favoriteId});
  
  @override
  List<Object> get props => [favoriteId];
}

/// État d'erreur
class FavoriteError extends FavoriteState {
  final String message;
  
  const FavoriteError({required this.message});
  
  @override
  List<Object> get props => [message];
}
