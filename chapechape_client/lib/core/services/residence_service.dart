import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:chapechape_client/core/models/residence_model.dart';
import 'package:chapechape_client/core/models/residence_type_enum.dart'; // Ajout de l'import manquant
import 'package:chapechape_client/core/services/api_service.dart';
import 'package:chapechape_client/core/services/cache_service.dart';
import 'package:chapechape_client/core/models/api/api_error.dart';
import 'package:flutter/foundation.dart';

class ResidenceService {
  final ApiService _apiService;
  final CacheService _cacheService;
  static ResidenceService? _instance;

  ResidenceService._({
    required ApiService apiService,
    required CacheService cacheService,
  }) : 
    _apiService = apiService,
    _cacheService = cacheService;

  static Future<ResidenceService> initialize() async {
    if (_instance != null) return _instance!;

    // Initialiser les services requis
    final apiService = await ApiService.initialize();
    final cacheService = CacheService.getInstance();
    
    // S'assurer que CacheService est initialisé
    await cacheService.ensureInitialized();

    final instance = ResidenceService._(
      apiService: apiService,
      cacheService: cacheService,
    );
    _instance = instance;
    return instance;
  }

  // Récupérer toutes les résidences avec cache
  Future<List<Residence>> getAllResidences({
    Map<String, dynamic>? filters,
    int? page,
    int? limit,
    bool forceRefresh = false,
  }) async {
    // Construire une clé de cache basée sur les paramètres
    final cacheKey = 'residences_all_${filters ?? ''}_page${page ?? 1}_limit${limit ?? 10}';
    
    try {
      // Vérifier si on a des données en cache
      final cachedData = _cacheService.get(cacheKey);
      if (cachedData != null && !forceRefresh) {
        return (cachedData as List).cast<Residence>();
      }
      
      // Sinon, récupérer les données
      final response = await _apiService.get(
        '/residences',
        queryParameters: {
          if (filters != null) ...filters,
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
        },
      );

      final residences = (response.data['data'] as List)
          .map((json) => _adaptBackendResidenceToClient(json))
          .toList();
          
      // Mettre en cache pour 30 minutes
      await _cacheService.put(cacheKey, residences, expiryInMinutes: 30);
      
      return residences;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Récupérer une résidence par son ID avec cache
  // Retourne Residence? pour indiquer que la résidence peut être null si non trouvée
  Future<Residence?> getResidenceById(String id, {bool forceRefresh = false}) async {
    final cacheKey = 'residence_$id';
    
    try {
      // Vérifier si on a des données en cache
      final cachedData = _cacheService.get(cacheKey);
      if (cachedData != null && !forceRefresh) {
        return cachedData as Residence;
      }
      
      // Sinon, récupérer les données
      debugPrint('🔍 Récupération des détails de la résidence: $id');
      final response = await _apiService.get('residences/$id');
      
      // LOGS DE DIAGNOSTIC DÉTAILLÉS
      debugPrint('======== DONNÉES DÉTAILLÉES DE LA RÉSIDENCE ========');
      debugPrint('Structure complète: ${response.data}');
      
      // Vérifier si features existe et sa structure
      if (response.data['features'] != null) {
        debugPrint('Features trouvé: ${response.data['features']}');
      }
      
      // Vérifier si location existe et sa structure
      if (response.data['location'] != null) {
        debugPrint('Location trouvé: ${response.data['location']}');
      }
      
      // Vérifier les images
      debugPrint('Images: ${response.data['images']}');
      debugPrint('================================================');
      
      final residence = _adaptBackendResidenceToClient(response.data);
      
      // Mettre en cache pour 1 heure
      await _cacheService.put(cacheKey, residence, expiryInMinutes: 60);
      
      return residence;
    } on DioException catch (e) {
      debugPrint('❌ Erreur lors de la récupération de la résidence: ${e.message}');
      throw _handleDioError(e);
    }
  }

  // Rechercher des résidences avec cache
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
    bool forceRefresh = false,
  }) async {
    // Construire une clé de cache basée sur les critères de recherche
    final cacheKey = 'search_${query ?? ''}_city${city ?? ''}_price${minPrice ?? 0}-${maxPrice ?? 0}_bed${bedrooms ?? 0}_bath${bathrooms ?? 0}_am${amenities?.join('-') ?? ''}_dates${checkIn?.day ?? ''}-${checkOut?.day ?? ''}';
    
    try {
      // Vérifier si on a des données en cache
      final cachedData = _cacheService.get(cacheKey);
      if (cachedData != null && !forceRefresh) {
        return (cachedData as List).cast<Residence>();
      }
      
      // Sinon, récupérer les données
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

      final residences = (response.data['data'] as List)
          .map((json) => _adaptBackendResidenceToClient(json))
          .toList();
          
      // Mettre en cache pour 15 minutes
      await _cacheService.put(cacheKey, residences, expiryInMinutes: 15);
      
      return residences;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Récupérer les résidences favorites d'un utilisateur (sans cache car dynamique)
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
      // Invalider le cache des favoris
      await _cacheService.remove('residence_$residenceId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Retirer une résidence des favoris
  Future<void> removeFromFavorites(String residenceId) async {
    try {
      await _apiService.delete('/residences/favorites/$residenceId');
      // Invalider le cache des favoris
      await _cacheService.remove('residence_$residenceId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Vérifier la disponibilité d'une résidence (pas de cache car temporel)
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

  // Méthode pour mapper le type du backend au type du client
  ResidenceType _mapBackendTypeToClientType(String backendType) {
    try {
      // Conversion manuelle en utilisant un switch
      switch (backendType.toLowerCase()) {
        case 'apartment': return ResidenceType.apartment;
        case 'house': return ResidenceType.house;
        case 'villa': return ResidenceType.villa;
        case 'studio': return ResidenceType.studio;
        case 'room': return ResidenceType.room;
        case 'hotel': return ResidenceType.hotel;
        case 'resort': return ResidenceType.resort;
        case 'motel': return ResidenceType.motel;
        case 'guesthouse': return ResidenceType.guesthouse;
        case 'cottage': return ResidenceType.cottage;
        case 'cabin': return ResidenceType.cabin;
        case 'chalet': return ResidenceType.chalet;
        case 'bungalow': return ResidenceType.bungalow;
        case 'hostel': return ResidenceType.hostel;
        default: return ResidenceType.other;
      }
    } catch (e) {
      // En cas d'erreur, retourner un type par défaut
      debugPrint('⚠️ Erreur de conversion du type: $e. Type reçu: $backendType');
      return ResidenceType.other;
    }
  }

  // Adapter les données du backend au format du client
  Residence _adaptBackendResidenceToClient(Map<String, dynamic> data) {
    try {
      final String id = data['_id'] ?? data['id'] ?? '';
      final String name = data['title'] ?? data['name'] ?? 'Sans titre';
      final String description = data['description'] ?? 'Aucune description';
      final double price = data['price'] != null ? double.parse(data['price'].toString()) : 0.0;
      final String address = data['address'] ?? '';
      final String city = data['city'] ?? '';
      final String country = data['country'] ?? '';
      
      // Images et vérification du format
      final List<String> images = _extractImages(data['images']);
      
      // Propriétés numériques
      final int bedrooms = data['bedrooms'] != null ? int.parse(data['bedrooms'].toString()) : 0;
      final int bathrooms = data['bathrooms'] != null ? int.parse(data['bathrooms'].toString()) : 0;
      final double surface = data['surface'] != null 
        ? double.parse(data['surface'].toString()) 
        : data['area'] != null 
          ? double.parse(data['area'].toString()) 
          : data['squareMeters'] != null 
            ? double.parse(data['squareMeters'].toString()) 
            : 0.0;
      
      // État de disponibilité
      final bool isAvailable = data['status'] == 'available' || data['isAvailable'] == true;
      
      // Récupération de la localisation
      Map<String, dynamic> location = {
        'address': address,
        'city': city,
        'country': country,
      };
      
      if (data['location'] is Map<String, dynamic>) {
        location = {...location, ...data['location'] as Map<String, dynamic>};
      }
      
      if (data['coordinates'] is List) {
        location['coordinates'] = data['coordinates'];
      } else if (data['latitude'] != null && data['longitude'] != null) {
        location['coordinates'] = [data['latitude'], data['longitude']];
      }
      
      // Récupération des équipements
      List<String> amenities = [];
      if (data['features'] is Map<String, dynamic>) {
        amenities = _extractAmenities(data['features'] as Map<String, dynamic>, data);
      } else if (data['amenities'] is List) {
        amenities = (data['amenities'] as List).map((e) => e.toString()).toList();
      }
      
      // Type de résidence - utiliser le type correct pour les studios
      String backendType = data['type']?.toString() ?? '';
      if (bedrooms == 0) {
        backendType = 'studio_meuble';
      }
      final residenceType = _mapBackendTypeToClientType(backendType);
      
      // Regrouper les détails de prix pour les remises
      Map<String, dynamic>? priceDetails;
      if (data['discountPrice'] != null) {
        priceDetails = {
          'discountPrice': double.tryParse(data['discountPrice'].toString()) ?? 0.0,
          'originalPrice': price,
        };
      }
      
      final residence = Residence(
        id: id,
        title: name,
        description: description,
        shortDescription: data['shortDescription'] ?? '',
        images: images,
        price: price,
        location: location,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        squareMeters: surface,
        amenities: amenities,
        hasPool: data['hasPool'] == true || amenities.contains('pool'),
        hasWifi: data['hasWifi'] == true || amenities.contains('wifi'),
        isVacationResidence: data['isVacationResidence'] == true,
        isSpecialResidence: data['isSpecialResidence'] == true,
        isAvailable: isAvailable,
        isFeatured: data['isFeatured'] == true,
        isPopular: data['isPopular'] == true,
        isVerified: data['isVerified'] == true,
        isNew: data['isNew'] == true,
        rating: data['rating'] != null ? double.parse(data['rating'].toString()) : 0.0,
        reviewCount: data['reviewCount'] != null ? int.parse(data['reviewCount'].toString()) : 0,
        currency: data['currency']?.toString() ?? 'XOF',
        type: residenceType,
        maxOccupancy: data['maxOccupancy'] != null ? int.parse(data['maxOccupancy'].toString()) : bedrooms * 2,
        owner: data['owner'] ?? data['ownerId'] ?? '',
        createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt'].toString()) : null,
        updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt'].toString()) : null,
        allowsPets: data['allowsPets'] == true,
        allowsSmoking: data['allowsSmoking'] == true,
        allowsParties: data['allowsParties'] == true,
        priceDetails: priceDetails,
        pricePeriod: data['pricePeriod']?.toString() ?? 'month',
        hourlyRate: data['hourlyRate'] != null ? double.parse(data['hourlyRate'].toString()) : 
                   data['hourlyRates'] != null && data['hourlyRates']['oneHour'] != null ? 
                   double.parse(data['hourlyRates']['oneHour'].toString()) : 0.0,
        halfDayRate: data['halfDayRate'] != null ? double.parse(data['halfDayRate'].toString()) : 
                    data['dailyRates'] != null && data['dailyRates']['halfDay'] != null ? 
                    double.parse(data['dailyRates']['halfDay'].toString()) : 0.0,
        fullDayRate: data['fullDayRate'] != null ? double.parse(data['fullDayRate'].toString()) : 
                    data['dailyRates'] != null && data['dailyRates']['fullDay'] != null ? 
                    double.parse(data['dailyRates']['fullDay'].toString()) : 0.0,
        weekendRate: data['weekendRate'] != null ? double.parse(data['weekendRate'].toString()) : 
                    data['dailyRates'] != null && data['dailyRates']['weekend'] != null ? 
                    double.parse(data['dailyRates']['weekend'].toString()) : 0.0,
      );
      
      debugPrint('✅ Résidence adaptée avec succès: ${residence.title} (${residence.id})');
      return residence;
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de l\'adaptation des données: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('JSON reçu: $data');
      throw Exception('Erreur lors de l\'adaptation des données de la résidence');
    }
  }
  
  // Méthode pour extraire les équipements des features
  List<String> _extractAmenities(Map<String, dynamic> features, Map<String, dynamic> data) {
    List<String> amenities = [];
    
    // Si amenities est déjà une liste dans les données principales, l'utiliser
    if (data['amenities'] is List) {
      return List<String>.from(data['amenities']);
    }
    
    // Sinon, extraire les équipements des features booléens
    if (features['furnished'] == true) amenities.add('Meublé');
    if (features['parking'] == true) amenities.add('Parking');
    if (features['airConditioned'] == true) amenities.add('Climatisation');
    if (features['pool'] == true) amenities.add('Piscine');
    if (features['garden'] == true) amenities.add('Jardin');
    if (features['security'] == true) amenities.add('Sécurité');
    
    return amenities;
  }

  // Fonction pour extraire et formater correctement les URLs des images
  List<String> _extractImages(dynamic imagesData) {
    if (imagesData == null) return [];
    
    List<String> imageUrls = [];
    String baseUrl = _apiService.baseUrl;
    
    // S'assurer que l'URL de base se termine sans slash
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    
    print("Base URL utilisée pour les images: $baseUrl");
    print("Images data brut: $imagesData");
    
    if (imagesData is List) {
      for (var img in imagesData) {
        String imageUrl = '';
        
        if (img is String) {
          imageUrl = img;
        } else if (img is Map) {
          if (img['url'] != null) {
            imageUrl = img['url'].toString();
          } else if (img['path'] != null) {
            imageUrl = img['path'].toString();
          }
        }
        
        // Ajouter le domaine si c'est un chemin relatif
        if (imageUrl.isNotEmpty) {
          if (!imageUrl.startsWith('http')) {
            // Différents cas de chemins relatifs
            if (imageUrl.startsWith('/uploads/')) {
              imageUrl = '$baseUrl$imageUrl';
            } else if (imageUrl.startsWith('uploads/')) {
              imageUrl = '$baseUrl/$imageUrl';
            } else if (imageUrl.startsWith('/')) {
              imageUrl = '$baseUrl$imageUrl';
            } else {
              // Fallback pour tout autre cas
              imageUrl = '$baseUrl/uploads/$imageUrl';
            }
          }
          print("URL d'image extraite dans le client: $imageUrl");
          imageUrls.add(imageUrl);
        }
      }
    }
    
    // Si aucune image trouvée, ajouter une image par défaut
    if (imageUrls.isEmpty) {
      imageUrls.add('https://via.placeholder.com/300x200?text=No+Image');
    }
    
    return imageUrls;
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
  
  // Méthodes pour récupérer des résidences par type
  Future<List<Residence>> getResidencesByType(String type) async {
    try {
      return await getAllResidences(
        filters: {'type': type},
        forceRefresh: false,
      );
    } on DioException catch (e) {
      debugPrint('Erreur lors de la récupération des résidences par type: $e');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des résidences par type: $e');
      return [];
    }
  }
  
  // Récupère les résidences mises en avant
  Future<List<Residence>> getFeaturedResidences() async {
    try {
      return await getAllResidences(
        filters: {'featured': true},
        limit: 10,
      );
    } on DioException catch (e) {
      debugPrint('Erreur lors de la récupération des résidences en vedette: $e');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des résidences en vedette: $e');
      return [];
    }
  }
  
  // Récupère les résidences spéciales
  Future<List<Residence>> getSpecialResidences() async {
    try {
      return await getAllResidences(
        filters: {'special': true},
        limit: 10,
      );
    } on DioException catch (e) {
      debugPrint('Erreur lors de la récupération des résidences spéciales: $e');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des résidences spéciales: $e');
      return [];
    }
  }
  
  // Récupère les résidences populaires
  Future<List<Residence>> getPopularResidences() async {
    try {
      return await getAllResidences(
        filters: {'popular': true, 'sort': 'rating'}, 
        limit: 10,
      );
    } on DioException catch (e) {
      debugPrint('Erreur lors de la récupération des résidences populaires: $e');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des résidences populaires: $e');
      return [];
    }
  }
}