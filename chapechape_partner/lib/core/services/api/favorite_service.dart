import 'package:dio/dio.dart';
import '../../models/favorite/favorite_model.dart';
import '../../models/residence/residence.dart';
import 'api_service.dart';

/// Service pour la gestion des résidences favorites
class FavoriteService {
  final ApiService _apiService;
  final Dio _dio;
  
  FavoriteService(Dio dio) 
      : _dio = dio,
        _apiService = ApiService(authBloc: null);
  
  // Alternative constructor
  FavoriteService.withApiService({required ApiService apiService}) 
      : _apiService = apiService,
        _dio = apiService.dio;
  
  /// Récupère les résidences favorites du partenaire
  /// 
  /// Retourne une liste de [FavoriteModel]
  Future<List<FavoriteModel>> getFavorites() async {
    try {
      final response = await _apiService.get('/api/favorites');
      
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => FavoriteModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Impossible de récupérer les favoris: $e');
    }
  }
  
  /// Ajoute une résidence aux favoris
  /// 
  /// [residenceId] : ID de la résidence à ajouter aux favoris
  Future<FavoriteModel> addFavorite(String residenceId) async {
    try {
      final response = await _apiService.post(
        '/api/favorites',
        data: {
          'residenceId': residenceId,
        },
      );
      
      return FavoriteModel.fromJson(response.data['favorite']);
    } catch (e) {
      throw Exception('Impossible d\'ajouter aux favoris: $e');
    }
  }
  
  /// Supprime une résidence des favoris
  /// 
  /// [favoriteId] : ID du favori à supprimer
  Future<void> removeFavorite(String favoriteId) async {
    try {
      await _apiService.delete('/api/favorites/$favoriteId');
    } catch (e) {
      throw Exception('Impossible de supprimer des favoris: $e');
    }
  }
  
  /// Vérifie si une résidence est dans les favoris
  /// 
  /// [residenceId] : ID de la résidence à vérifier
  Future<bool> isFavorite(String residenceId) async {
    try {
      final response = await _apiService.get(
        '/api/favorites/check/$residenceId',
      );
      
      return response.data['isFavorite'] ?? false;
    } catch (e) {
      return false; // En cas d'erreur, on suppose que ce n'est pas un favori
    }
  }
}
