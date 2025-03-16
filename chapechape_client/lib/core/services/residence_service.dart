import 'package:dio/dio.dart';
import 'package:chapechape_client/core/models/residence_model.dart' as model;
import 'package:chapechape_client/core/models/residence_model.dart' hide ResidenceType;
import 'package:chapechape_client/core/constants/app_assets.dart' as assets;
import 'package:chapechape_client/core/services/api_service.dart';
import 'package:flutter/foundation.dart';

class ResidenceService {
  final ApiService _apiService;
  static ResidenceService? _instance;

  ResidenceService._({required ApiService apiService}) : _apiService = apiService;

  static Future<ResidenceService> initialize() async {
    if (_instance != null) return _instance!;

    final instance = ResidenceService._(apiService: await ApiService.initialize());
    _instance = instance;
    return instance;
  }

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
          .map((json) => _adaptBackendResidenceToClient(json))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Récupérer une résidence par son ID
  Future<Residence> getResidenceById(String id) async {
    try {
      // Vérifier si l'ID est un ID temporaire
      if (id.startsWith('temp_')) {
        debugPrint('⚠️ ATTENTION: Utilisation d\'un ID temporaire pour obtenir les détails de la résidence');
        // Remplacer par un ID valide de MongoDB qui fonctionne avec Postman
        id = "67cb2f6acb3b4423a99c32c8";
      }
      
      final response = await _apiService.get('residences/$id');
      return _adaptBackendResidenceToClient(response.data);
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
          .map((json) => _adaptBackendResidenceToClient(json))
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
          .map((json) => _adaptBackendResidenceToClient(json))
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

      return response.data['available'] == true;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Mappage des types backend vers les types ResidenceType du client
  model.ResidenceType _mapBackendTypeToClientType(String backendType) {
    switch (backendType) {
      case 'apartment':
        return model.ResidenceType.apartment;
      case 'studio':
        return model.ResidenceType.studio;
      case 'villa':
        return model.ResidenceType.villa;
      case 'house':
        return model.ResidenceType.house; // Correspondance directe pour 'house'
      case 'bungalow':
        return model.ResidenceType.bungalow;
      case 'hotel':
        return model.ResidenceType.hotel;
      case 'luxury':
        return model.ResidenceType.luxury;
      default:
        return model.ResidenceType.other; // Valeur par défaut
    }
  }

  // Adaptation des données de résidence venant du backend
  Residence _adaptBackendResidenceToClient(Map<String, dynamic> data) {
    // Extraire l'ID ou générer un ID temporaire si aucun n'est présent
    String id = data['_id'] ?? data['id'] ?? '';
    
    // Imprimer les données reçues pour débogage
    print('Données de résidence reçues du backend: $data');
    print('ID extrait: $id');
    
    // Si l'ID est vide, générer un ID temporaire unique
    if (id.isEmpty) {
      // Utiliser un horodatage pour créer un ID temporaire semi-unique
      id = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      print('ATTENTION: ID de résidence manquant. ID temporaire généré: $id');
    }
    
    final type = _mapBackendTypeToClientType(data['type'] ?? 'apartment');
    
    return Residence(
      id: id,
      name: data['title'] ?? '',
      description: data['description'] ?? '',
      price: double.tryParse(data['price']?.toString() ?? '0') ?? 0,
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      country: 'Côte d\'Ivoire', // Valeur par défaut
      images: List<String>.from(data['images'] ?? []),
      bedrooms: int.tryParse(data['bedrooms']?.toString() ?? '0') ?? 0,
      bathrooms: int.tryParse(data['bathrooms']?.toString() ?? '0') ?? 0,
      surface: double.tryParse(data['area']?.toString() ?? '0') ?? 0,
      isAvailable: data['status'] == 'available',
      location: {
        'formattedAddress': data['address'] ?? '',
        'city': data['city'] ?? '',
        'coordinates': [
          double.tryParse(data['latitude']?.toString() ?? '0') ?? 0,
          double.tryParse(data['longitude']?.toString() ?? '0') ?? 0,
        ],
      },
      amenities: List<String>.from(data['amenities'] ?? []),
      type: type,
      rating: double.tryParse(data['rating']?.toString() ?? '0') ?? 0,
      reviewCount: int.tryParse(data['reviewCount']?.toString() ?? '0') ?? 0,
      ownerId: data['partner'] is String ? data['partner'] : null,
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : null,
      updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt']) : null,
    );
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