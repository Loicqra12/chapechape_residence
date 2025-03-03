import 'package:flutter_bloc/flutter_bloc.dart';
import 'favorite_event.dart';
import 'favorite_state.dart';
import '../../models/residence_model.dart';
import '../../repositories/favorite_repository.dart';

class FavoriteBloc extends Bloc<FavoriteEvent, FavoriteState> {
  final FavoriteRepository _favoriteRepository;

  FavoriteBloc({
    required FavoriteRepository favoriteRepository,
  })  : _favoriteRepository = favoriteRepository,
        super(FavoriteInitial()) {
    on<LoadFavorites>(_onLoadFavorites);
    on<AddToFavorites>(_onAddToFavorite);
    on<RemoveFromFavorites>(_onRemoveFromFavorite);
    on<CheckFavorite>(_onCheckFavorite);
  }

  // Getter pour accéder au repository
  FavoriteRepository get favoriteRepository => _favoriteRepository;

  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<FavoriteState> emit,
  ) async {
    emit(const FavoriteLoading());
    
    try {
      final favorites = await _favoriteRepository.getFavorites();
      emit(FavoriteLoaded(favorites));
    } catch (e) {
      emit(FavoriteError('Erreur lors du chargement des favoris: $e'));
    }
  }

  Future<void> _onAddToFavorite(
    AddToFavorites event,
    Emitter<FavoriteState> emit,
  ) async {
    try {
      final success = await _favoriteRepository.addToFavorites(event.residenceId);
      
      if (success) {
        // Recharger les favoris pour avoir la liste à jour
        add(const LoadFavorites());
      } else {
        emit(FavoriteError('Impossible d\'ajouter aux favoris'));
      }
    } catch (e) {
      emit(FavoriteError('Erreur lors de l\'ajout aux favoris: $e'));
    }
  }

  Future<void> _onRemoveFromFavorite(
    RemoveFromFavorites event,
    Emitter<FavoriteState> emit,
  ) async {
    try {
      final success = await _favoriteRepository.removeFromFavorites(event.residenceId);
      
      if (success) {
        if (state is FavoriteLoaded) {
          final currentFavorites = (state as FavoriteLoaded).favorites;
          final updatedFavorites = currentFavorites
              .where((residence) => residence.id != event.residenceId)
              .toList();
          
          emit(FavoriteLoaded(updatedFavorites));
        }
      } else {
        emit(FavoriteError('Impossible de supprimer des favoris'));
      }
    } catch (e) {
      emit(FavoriteError('Erreur lors de la suppression des favoris: $e'));
    }
  }

  Future<void> _onCheckFavorite(
    CheckFavorite event,
    Emitter<FavoriteState> emit,
  ) async {
    try {
      final isFavorite = await _favoriteRepository.checkFavorite(event.residenceId);
      emit(FavoriteChecked(event.residenceId, isFavorite));
    } catch (e) {
      emit(FavoriteError('Erreur lors de la vérification des favoris: $e'));
    }
  }
}
