import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
      final response = await _apiService.get('/favorites');
      
      // Log le code de statut pour le débogage
      debugPrint('Favoris - Statut: ${response.statusCode}');
      
      // Cas où la réponse est une Map avec les données attendues
      if (response.data is Map<String, dynamic>) {
        final mapData = response.data as Map<String, dynamic>;
        
        if (mapData['success'] == true && mapData['data'] is List) {
          final List favoritesList = mapData['data'] as List;
          final residences = <Residence>[];
          
          for (var item in favoritesList) {
            if (item is Map<String, dynamic> && item.containsKey('residence')) {
              try {
                // Format standard: {residence: {...}}
                final residenceData = item['residence'];
                if (residenceData is Map<String, dynamic>) {
                  residences.add(Residence.fromJson(residenceData));
                }
              } catch (e) {
                debugPrint('Erreur conversion résidence: $e');
              }
            }
          }
          
          return residences;
        }
      }
      
      // Si aucun format reconnu, retourner liste vide
      return [];
      
    } on DioException catch (e) {
      debugPrint('Erreur réseau favoris: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Exception favoris: $e');
      return [];
    }
  }
  
  // Ajouter une résidence aux favoris
  Future<bool> addToFavorites(String residenceId) async {
    try {
      final response = await _apiService.post(
        '/favorites',
        data: {'residenceId': residenceId},
      );
      
      return response.data != null && 
             response.data is Map<String, dynamic> && 
             response.data['success'] == true;
    } on DioException catch (e) {
      debugPrint('Erreur ajout favoris: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Exception ajout favoris: $e');
      return false;
    }
  }
  
  // Vérifier si une résidence est dans les favoris
  Future<bool> checkFavorite(String residenceId) async {
    try {
      final response = await _apiService.get('/favorites/check/$residenceId');
      
      return response.data != null && 
             response.data is Map<String, dynamic> &&
             response.data['isFavorite'] == true;
    } on DioException catch (e) {
      debugPrint('Erreur vérification favoris: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Exception vérification favoris: $e');
      return false;
    }
  }
  
  // Supprimer une résidence des favoris
  Future<bool> removeFromFavorites(String residenceId) async {
    try {
      final response = await _apiService.delete('/favorites/$residenceId');
      
      return response.data != null && 
             response.data is Map<String, dynamic> &&
             response.data['success'] == true;
    } on DioException catch (e) {
      debugPrint('Erreur suppression favoris: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Exception suppression favoris: $e');
      return false;
    }
  }
  
  // Obtenir les statistiques des favoris
  Future<Map<String, dynamic>> getFavoriteStats() async {
    try {
      final response = await _apiService.get('/favorites/stats');
      
      if (response.data != null && 
          response.data is Map<String, dynamic> &&
          response.data['success'] == true &&
          response.data['data'] != null &&
          response.data['data'] is Map<String, dynamic>) {
        return response.data['data'];
      }
      
      return {};
    } on DioException catch (e) {
      debugPrint('Erreur stats favoris: ${e.message}');
      return {};
    } catch (e) {
      debugPrint('Exception stats favoris: $e');
      return {};
    }
  }
}
