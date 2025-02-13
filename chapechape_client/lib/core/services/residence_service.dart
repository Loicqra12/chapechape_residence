import 'package:dio/dio.dart';
import 'package:chapechape_client/core/models/residence_model.dart';
import 'package:chapechape_client/core/services/api_service.dart';

class ResidenceService {
  final ApiService _apiService = ApiService();

  // Récupérer toutes les résidences
  Future<List<Residence>> getAllResidences({
    Map<String, dynamic>? filters,
    int? page,
    int? limit,
  }) async {
    try {
      final response = await _apiService.get(
        '/residences',
        queryParameters: {
          if (filters != null) ...filters,
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
        },
      );

      return (response.data['data'] as List)
          .map((json) => Residence.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Récupérer une résidence par son ID
  Future<Residence> getResidenceById(String id) async {
    try {
      final response = await _apiService.get('/residences/$id');
      return Residence.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Rechercher des résidences
  Future<List<Residence>> searchResidences({
    String? query,
    String? city,
    double? minPrice,
    double? maxPrice,
    int? bedrooms,
    int? bathrooms,
    List<String>? amenities,
    DateTime? checkIn,
    DateTime? checkOut,
  }) async {
    try {
      final response = await _apiService.get(
        '/residences/search',
        queryParameters: {
          if (query != null) 'query': query,
          if (city != null) 'city': city,
          if (minPrice != null) 'minPrice': minPrice,
          if (maxPrice != null) 'maxPrice': maxPrice,
          if (bedrooms != null) 'bedrooms': bedrooms,
          if (bathrooms != null) 'bathrooms': bathrooms,
          if (amenities != null) 'amenities': amenities.join(','),
          if (checkIn != null) 'checkIn': checkIn.toIso8601String(),
          if (checkOut != null) 'checkOut': checkOut.toIso8601String(),
        },
      );

      return (response.data['data'] as List)
          .map((json) => Residence.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Récupérer les résidences favorites d'un utilisateur
  Future<List<Residence>> getFavoriteResidences() async {
    try {
      final response = await _apiService.get('/residences/favorites');
      return (response.data['data'] as List)
          .map((json) => Residence.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Ajouter une résidence aux favoris
  Future<void> addToFavorites(String residenceId) async {
    try {
      await _apiService.post('/residences/favorites/$residenceId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Retirer une résidence des favoris
  Future<void> removeFromFavorites(String residenceId) async {
    try {
      await _apiService.delete('/residences/favorites/$residenceId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Vérifier la disponibilité d'une résidence
  Future<bool> checkAvailability({
    required String residenceId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      final response = await _apiService.get(
        '/residences/$residenceId/availability',
        queryParameters: {
          'checkIn': checkIn.toIso8601String(),
          'checkOut': checkOut.toIso8601String(),
        },
      );
      return response.data['available'] as bool;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Gérer les erreurs Dio
  Exception _handleDioError(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        return Exception(e.response?.data['message'] ?? 'Requête invalide');
      case 401:
        return Exception('Non autorisé');
      case 404:
        return Exception('Résidence non trouvée');
      case 500:
        return Exception('Erreur serveur');
      default:
        return Exception('Une erreur est survenue');
    }
  }
}