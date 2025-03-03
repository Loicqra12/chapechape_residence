import 'package:dio/dio.dart';
import '../models/residence_model.dart';
import 'api_service.dart';

class FavoriteService {
  final ApiService _apiService;

  FavoriteService._({
    required ApiService apiService,
  }) : _apiService = apiService;

  static Future<FavoriteService> initialize() async {
    final apiService = await ApiService.initialize();
    return FavoriteService._(apiService: apiService);
  }

  // Récupérer les résidences favorites de l'utilisateur
  Future<List<Residence>> getFavorites() async {
    try {
      final response = await _apiService.get('/api/favorites');
      
      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> favoritesData = response.data['data'];
        return favoritesData
            .map((json) => Residence.fromJson(json['residence']))
            .toList();
      }
      
      return [];
    } on DioException catch (e) {
      print('Erreur lors de la récupération des favoris: ${e.message}');
      return [];
    }
  }
  
  // Ajouter une résidence aux favoris
  Future<bool> addToFavorites(String residenceId) async {
    try {
      final response = await _apiService.post(
        '/api/favorites',
        data: {'residenceId': residenceId},
      );
      return response.data['success'] == true;
    } on DioException catch (e) {
      print('Erreur lors de l\'ajout aux favoris: ${e.message}');
      return false;
    }
  }
  
  // Vérifier si une résidence est dans les favoris
  Future<bool> checkFavorite(String residenceId) async {
    try {
      final response = await _apiService.get('/api/favorites/check/$residenceId');
      return response.data['isFavorite'] == true;
    } on DioException catch (e) {
      print('Erreur lors de la vérification des favoris: ${e.message}');
      return false;
    }
  }
  
  // Supprimer une résidence des favoris
  Future<bool> removeFromFavorites(String residenceId) async {
    try {
      final response = await _apiService.delete('/api/favorites/$residenceId');
      return response.data['success'] == true;
    } on DioException catch (e) {
      print('Erreur lors de la suppression des favoris: ${e.message}');
      return false;
    }
  }
  
  // Obtenir les statistiques des favoris
  Future<Map<String, dynamic>> getFavoriteStats() async {
    try {
      final response = await _apiService.get('/api/favorites/stats');
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return {};
    } on DioException catch (e) {
      print('Erreur lors de la récupération des statistiques: ${e.message}');
      return {};
    }
  }
}
