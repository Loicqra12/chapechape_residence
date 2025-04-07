import 'package:dio/dio.dart';
import 'package:chapechape_client/core/models/residence_model.dart' as model;
import 'package:chapechape_client/core/models/residence_model.dart' hide ResidenceType;
import 'package:chapechape_client/core/constants/app_assets.dart' as assets;
import 'package:chapechape_client/core/services/api_service.dart';
import 'package:chapechape_client/core/services/cache_service.dart';
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

    final instance = ResidenceService._(
      apiService: await ApiService.initialize(),
      cacheService: await CacheService.initialize(),
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
    
    return _cacheService.get<List<Residence>>(
      cacheKey,
      () async {
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
      },
      forceRefresh: forceRefresh,
      // Plus longue durée de cache pour les résidences (30 minutes)
      duration: const Duration(minutes: 30),
    );
  }

  // Récupérer une résidence par son ID avec cache
  Future<Residence> getResidenceById(String id, {bool forceRefresh = false}) async {
    final cacheKey = 'residence_$id';
    
    return _cacheService.get<Residence>(
      cacheKey,
      () async {
        try {
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
          
          return _adaptBackendResidenceToClient(response.data);
        } on DioException catch (e) {
          debugPrint('❌ Erreur lors de la récupération de la résidence: ${e.message}');
          throw _handleDioError(e);
        }
      },
      forceRefresh: forceRefresh,
      duration: const Duration(hours: 1),
    );
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
    
    return _cacheService.get<List<Residence>>(
      cacheKey,
      () async {
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
      },
      forceRefresh: forceRefresh,
      // Durée de cache plus courte pour les recherches (15 minutes)
      duration: const Duration(minutes: 15),
    );
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
      await _cacheService.invalidateByPrefix('residence_$residenceId');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Retirer une résidence des favoris
  Future<void> removeFromFavorites(String residenceId) async {
    try {
      await _apiService.delete('/residences/favorites/$residenceId');
      // Invalider le cache des favoris
      await _cacheService.invalidateByPrefix('residence_$residenceId');
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

  // Mappage des types backend vers les types ResidenceType du client
  model.ResidenceType _mapBackendTypeToClientType(String backendType) {
    switch (backendType.toLowerCase().trim()) {
      // Mappings des types de base du backend vers les types spécifiques du client
      case 'studio':
        return model.ResidenceType.studioMeuble;
      case 'apartment':
        return model.ResidenceType.appartementMeuble;
      case 'villa':
        return model.ResidenceType.villaMeublee;
      case 'house':
        return model.ResidenceType.house;
      case 'hotel':
        return model.ResidenceType.hotel;
        
      // 🏠 Résidences meublées
      case 'studio meublé':
      case 'studio_meuble':
      case 'studiomeuble':
        return model.ResidenceType.studioMeuble;
      case 'appartement meublé':
      case 'appartement_meuble':
      case 'appartementmeuble':
        return model.ResidenceType.appartementMeuble;
      case 'villa meublée':
      case 'villa_meublee':
      case 'villameublee':
        return model.ResidenceType.villaMeublee;
      case 'penthouse':
        return model.ResidenceType.penthouse;
      case 'loft':
        return model.ResidenceType.appartementMeuble; // Loft -> Appartement meublé
      case 'grenier':
      case 'grenier aménagé':
      case 'grenier_amenage':
        return model.ResidenceType.grenier;

      // 🏨 Hôtels & Hébergements classiques
      case 'hôtel de passage':
      case 'hotel de passage':
      case 'hotel_de_passage':
      case 'hotel_passage':
      case 'hoteldepassage':
        return model.ResidenceType.hotelDePassage;
      case 'motel':
        return model.ResidenceType.motel;
      case 'boutique-hôtel':
      case 'boutique-hotel':
      case 'boutique_hotel':
      case 'boutiquehotel':
        return model.ResidenceType.boutiqueHotel;
      case 'hôtel de luxe':
      case 'hotel de luxe':
      case 'hotel_de_luxe':
      case 'hotel_luxe':
      case 'hoteldeluxe':
        return model.ResidenceType.hotelDeLuxe;
      case 'auberge et maison d\'hôtes':
      case 'auberge et maison d\'hotes':
      case 'auberge_et_maison_dhotes':
      case 'aubergeetmaisondhotes':
      case 'maison_hotes':
      case 'guest_house':
        return model.ResidenceType.aubergeEtMaisonDHotes;
      case 'résidence hôtelière':
      case 'residence hoteliere':
      case 'residence_hoteliere':
      case 'residencehoteliere':
        return model.ResidenceType.residenceHoteliere;

      // 🌍 Hébergements insolites & nature
      case 'bungalow':
        return model.ResidenceType.bungalow;
      case 'lodge & écolodge':
      case 'lodge & ecolodge':
      case 'lodge_et_ecolodge':
      case 'lodge':
      case 'lodgetecolodge':
        return model.ResidenceType.lodgeEtEcolodge;
      case 'case traditionnelle':
      case 'case_traditionnelle':
      case 'casetraditionnelle':
        return model.ResidenceType.caseTraditionnelle;
      case 'maison flottante':
      case 'maison_flottante':
      case 'maisonflottante':
        return model.ResidenceType.maisonFlottante;
      case 'campement touristique':
      case 'campement_touristique':
      case 'campementtouristique':
        return model.ResidenceType.campementTouristique;

      // 🏘️ Colocation & résidences partagées
      case 'chambre en colocation':
      case 'chambre_en_colocation':
      case 'chambre_colocation':
      case 'chambrecolocation':
        return model.ResidenceType.chambreEnColocation;
      case 'coliving':
      case 'cohabitation':
        return model.ResidenceType.cohabitation;
      case 'résidence universitaire':
      case 'residence universitaire':
      case 'residence_universitaire':
        return model.ResidenceType.residenceUniversitaire;
      case 'cité & dortoir':
      case 'cite & dortoir':
      case 'cité dortoir':
      case 'cite dortoir':
      case 'cite_dortoir':
        return model.ResidenceType.citeDortoir;

      // 🏡 Résidences longue durée
      case 'appartement non meublé':
      case 'appartement_vide':
      case 'appartement_non_meuble':
        return model.ResidenceType.appartementNonMeuble;
      case 'villa non meublée':
      case 'villa_vide':
      case 'villa_non_meublee':
        return model.ResidenceType.villaNonMeublee;
      case 'immeuble':
        return model.ResidenceType.immeuble;
      case 'cour commune':
      case 'cour_commune':
        return model.ResidenceType.courCommune;
        
      // ⛺ Hébergements économiques et populaires
      case 'maison d\'hôtes économique':
      case 'maison d\'hotes economique':
      case 'maison_hotes_economique':
        return model.ResidenceType.maisonDHotesEconomique;
      case 'résidence familiale en location':
      case 'residence familiale en location':
      case 'residence_familiale':
      case 'residence_familiale_en_location':
        return model.ResidenceType.residenceFamilialeEnLocation;
      case 'chambres de passage':
      case 'chambres_passage':
      case 'chambres_de_passage':
        return model.ResidenceType.chambresDePassage;

      default:
        debugPrint('⚠️ Type de résidence non reconnu: $backendType, utilisation du type par défaut');
        // Si on ne reconnaît pas, on retourne un type par défaut selon la première lettre
        if (backendType.toLowerCase().startsWith('s')) {
          return model.ResidenceType.studioMeuble;
        } else if (backendType.toLowerCase().startsWith('v')) {
          return model.ResidenceType.villaMeublee;
        } else if (backendType.toLowerCase().startsWith('h') || backendType.toLowerCase().startsWith('ho')) {
          return model.ResidenceType.hotel;
        } else if (backendType.toLowerCase().startsWith('b')) {
          return model.ResidenceType.bungalow;
        } else if (backendType.toLowerCase().startsWith('c')) {
          return model.ResidenceType.chambreEnColocation;
        } else {
          return model.ResidenceType.appartementMeuble;
        }
    }
  }

  // Adapter les données du backend au format du client
  Residence _adaptBackendResidenceToClient(Map<String, dynamic> json) {
    debugPrint('Adaptation des données backend: $json');
    
    try {
      // Extraire l'objet data
      final data = json['data'] as Map<String, dynamic>? ?? json;
      debugPrint('Données à adapter: $data');
      
      // Extraire le nom depuis title
      final name = data['title']?.toString() ?? 'Résidence sans nom';
      debugPrint('📝 Nom extrait: $name');
      
      // Extraire la surface depuis area
      final surface = data['area'] != null ? (data['area'] as num).toDouble() : 0.0;
      debugPrint('📏 Surface extraite: $surface');
      
      // Extraire les autres champs avec gestion des valeurs nulles
      final String id = data['_id']?.toString() ?? data['id']?.toString() ?? 'unknown_id';
      final String description = data['description']?.toString() ?? '';
      final double price = data['price'] != null ? (data['price'] as num).toDouble() : 0.0;
      
      // Gestion de l'adresse et de la ville
      final location = data['location'] as Map<String, dynamic>? ?? {};
      String address = data['address']?.toString() ?? '';
      String city = data['city']?.toString() ?? '';
      
      // Si l'adresse est vide mais que nous avons la ville, l'inclure dans l'adresse
      if (address.isEmpty && city.isNotEmpty) {
        address = city;
      } else if (address.isNotEmpty && city.isNotEmpty && !address.contains(city)) {
        address = '$address, $city';
      }
      
      // Si l'adresse est toujours vide, utiliser "Adresse non disponible"
      if (address.isEmpty) {
        address = 'Adresse non disponible';
      }
      
      final String country = location['country']?.toString() ?? data['country']?.toString() ?? 'Côte d\'Ivoire';
      
      // Gestion des images avec une image par défaut cohérente
      List<String> images = _extractImages(data['images']);
      if (images.isEmpty) {
        images = [''];  // Image par défaut vide pour le moment
      }
      
      // Extraire les caractéristiques
      final features = data['features'] as Map<String, dynamic>? ?? {};
      final int bedrooms = data['bedrooms'] as int? ?? features['bedrooms'] as int? ?? 0;
      final int bathrooms = data['bathrooms'] as int? ?? features['bathrooms'] as int? ?? 0;
      
      // Gestion du statut de disponibilité
      final bool isAvailable = data['status'] == 'available';
      
      // Gestion des équipements
      List<String> amenities = [];
      if (data['amenities'] != null && data['amenities'] is List) {
        amenities = (data['amenities'] as List).map((e) => e.toString()).toList();
      }
      
      // Type de résidence - utiliser le type correct pour les studios
      String backendType = data['type']?.toString() ?? '';
      if (bedrooms == 0) {
        backendType = 'studio_meuble';
      }
      final type = _mapBackendTypeToClientType(backendType);
      
      final residence = Residence(
        id: id,
        name: name,
        description: description,
        price: price,
        address: address,
        city: city,
        country: country,
        images: images,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        surface: surface,
        isAvailable: isAvailable,
        location: location,
        amenities: amenities,
        type: type,
        pricePeriod: data['pricePeriod']?.toString() ?? 'month',
        hourlyRate: data['hourlyRate'] != null ? (data['hourlyRate'] as num).toDouble() : 0.0,
        halfDayRate: data['halfDayRate'] != null ? (data['halfDayRate'] as num).toDouble() : 0.0,
        fullDayRate: data['fullDayRate'] != null ? (data['fullDayRate'] as num).toDouble() : 0.0,
        weekendRate: data['weekendRate'] != null ? (data['weekendRate'] as num).toDouble() : 0.0,
        rating: data['rating'] != null ? (data['rating'] as num).toDouble() : 0.0,
        reviewCount: data['reviewCount'] != null ? (data['reviewCount'] as num).toInt() : 0,
        createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt'].toString()) : DateTime.now(),
        updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt'].toString()) : DateTime.now(),
      );
      
      debugPrint('✅ Résidence adaptée avec succès: ${residence.name} (${residence.id})');
      return residence;
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de l\'adaptation des données: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('JSON reçu: $json');
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
}