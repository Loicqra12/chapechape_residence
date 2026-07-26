import 'package:flutter/foundation.dart';
import '../models/residence_model.dart';
import '../services/favorite_service.dart';
import '../services/residence_service.dart';

class FavoriteRepository {
  final FavoriteService _favoriteService;
  final ResidenceService _residenceService;

  // Getter pour rendre le service accessible publiquement
  FavoriteService get favoriteService => _favoriteService;

  FavoriteRepository({
    required FavoriteService favoriteService,
    required ResidenceService residenceService,
  }) : _favoriteService = favoriteService,
       _residenceService = residenceService {
    // Initialisation si nécessaire
  }

  // Méthode d'initialisation statique similaire aux autres services
  static Future<FavoriteRepository> initialize() async {
    final favoriteService = await FavoriteService.initialize();
    final residenceService = await ResidenceService.initialize();
    return FavoriteRepository(
      favoriteService: favoriteService,
      residenceService: residenceService,
    );
  }

  Future<List<String>> getFavoriteIds() async {
    return await _favoriteService.getFavorites();
  }

  Future<List<Residence>> getFavorites() async {
    final List<String> favorites = await _favoriteService.getFavorites();
    return await _convertIdsToResidences(favorites);
  }

  Future<bool> addToFavorites(String residenceId) async {
    return await _favoriteService.addToFavorites(residenceId);
  }

  Future<bool> removeFromFavorites(String residenceId) async {
    return await _favoriteService.removeFromFavorites(residenceId);
  }

  Future<bool> checkFavorite(String residenceId) async {
    return await _favoriteService.checkFavorite(residenceId);
  }

  Future<Map<String, dynamic>> getStats() async {
    final favorites = await _favoriteService.getFavorites();
    return {
      'count': favorites.length,
      'ids': favorites,
    };
  }

  // Méthode privée pour convertir des IDs en objets Residence
  Future<List<Residence>> _convertIdsToResidences(List<String> ids) async {
    if (ids.isEmpty) return [];

    final results = await Future.wait(
      ids.map((id) async {
        try {
          return await _residenceService.getResidenceById(id);
        } catch (e) {
          debugPrint(
              'Erreur lors de la récupération de la résidence favorite $id: $e');
          return null;
        }
      }),
    );

    final residences = <Residence>[];
    for (final residence in results.whereType<Residence>()) {
      final updatedPriceDetails =
          Map<String, dynamic>.from(residence.priceDetails ?? {});
      updatedPriceDetails['isFavorite'] = true;
      residences.add(residence.copyWith(priceDetails: updatedPriceDetails));
    }

    return residences;
  }
}
