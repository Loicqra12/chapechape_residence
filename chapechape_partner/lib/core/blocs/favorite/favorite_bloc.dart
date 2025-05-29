import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/favorite_service.dart';
import 'favorite_event.dart';
import 'favorite_state.dart';

/// BLoC pour gérer les opérations et l'état des favoris
class FavoriteBloc extends Bloc<FavoriteEvent, FavoriteState> {
  final FavoriteService _favoriteService;
  
  FavoriteBloc({required FavoriteService favoriteService}) 
      : _favoriteService = favoriteService,
        super(const FavoriteInitial()) {
    on<LoadFavorites>(_onLoadFavorites);
    on<AddToFavorites>(_onAddToFavorites);
    on<RemoveFromFavorites>(_onRemoveFromFavorites);
    on<CheckFavoriteStatus>(_onCheckFavoriteStatus);
    on<RefreshFavorites>(_onRefreshFavorites);
  }
  
  /// Gère l'événement de chargement des favoris
  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<FavoriteState> emit,
  ) async {
    emit(const FavoritesLoading());
    try {
      final favorites = await _favoriteService.getFavorites();
      emit(FavoritesLoaded(favorites: favorites));
    } catch (e) {
      emit(FavoriteError(message: 'Impossible de charger les favoris: $e'));
    }
  }
  
  /// Gère l'événement d'ajout d'une résidence aux favoris
  Future<void> _onAddToFavorites(
    AddToFavorites event,
    Emitter<FavoriteState> emit,
  ) async {
    try {
      final favorite = await _favoriteService.addFavorite(event.residenceId);
      emit(FavoriteAdded(favorite: favorite));
      
      // Recharger la liste des favoris
      add(const LoadFavorites());
    } catch (e) {
      emit(FavoriteError(message: 'Impossible d\'ajouter aux favoris: $e'));
    }
  }
  
  /// Gère l'événement de suppression d'une résidence des favoris
  Future<void> _onRemoveFromFavorites(
    RemoveFromFavorites event,
    Emitter<FavoriteState> emit,
  ) async {
    try {
      await _favoriteService.removeFavorite(event.favoriteId);
      emit(FavoriteRemoved(favoriteId: event.favoriteId));
      
      // Recharger la liste des favoris
      add(const LoadFavorites());
    } catch (e) {
      emit(FavoriteError(message: 'Impossible de supprimer des favoris: $e'));
    }
  }
  
  /// Gère l'événement de vérification du statut d'une résidence (si elle est en favoris)
  Future<void> _onCheckFavoriteStatus(
    CheckFavoriteStatus event,
    Emitter<FavoriteState> emit,
  ) async {
    try {
      final isFavorite = await _favoriteService.isFavorite(event.residenceId);
      emit(FavoriteStatusChecked(
        isFavorite: isFavorite,
        residenceId: event.residenceId,
      ));
    } catch (e) {
      emit(FavoriteError(message: 'Impossible de vérifier le statut du favori: $e'));
    }
  }
  
  /// Gère l'événement de rafraîchissement des favoris
  Future<void> _onRefreshFavorites(
    RefreshFavorites event,
    Emitter<FavoriteState> emit,
  ) async {
    add(const LoadFavorites());
  }
}
