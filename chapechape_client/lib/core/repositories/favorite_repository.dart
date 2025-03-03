import '../models/residence_model.dart';
import '../services/favorite_service.dart';

class FavoriteRepository {
  final FavoriteService _favoriteService;

  FavoriteRepository._({
    required FavoriteService favoriteService,
  }) : _favoriteService = favoriteService;

  static Future<FavoriteRepository> initialize() async {
    final favoriteService = await FavoriteService.initialize();
    return FavoriteRepository._(favoriteService: favoriteService);
  }
  
  // Getter pour le service
  FavoriteService get favoriteService => _favoriteService;

  // Récupérer les résidences favorites
  Future<List<Residence>> getFavorites() async {
    return await _favoriteService.getFavorites();
  }
  
  // Méthode pour récupérer les résidences favorites
  Future<List<Residence>> getFavoriteResidences() async {
    return await _favoriteService.getFavorites();
  }
  
  // Ajouter une résidence aux favoris
  Future<bool> addToFavorites(String residenceId) async {
    return await _favoriteService.addToFavorites(residenceId);
  }
  
  // Vérifier si une résidence est dans les favoris
  Future<bool> checkFavorite(String residenceId) async {
    return await _favoriteService.checkFavorite(residenceId);
  }
  
  // Supprimer une résidence des favoris
  Future<bool> removeFromFavorites(String residenceId) async {
    return await _favoriteService.removeFromFavorites(residenceId);
  }
  
  // Obtenir les statistiques des favoris
  Future<Map<String, dynamic>> getFavoriteStats() async {
    return await _favoriteService.getFavoriteStats();
  }
}
