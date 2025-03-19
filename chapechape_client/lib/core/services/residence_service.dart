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
      
      // LOGS DE DIAGNOSTIC DÉTAILLÉS
      debugPrint('======== DONNÉES DÉTAILLÉES DE LA RÉSIDENCE ========');
      debugPrint('Structure complète: ${response.data}');
      
      // Vérifier si features existe et sa structure
      if (response.data['features'] != null) {
        debugPrint('Features trouvé: ${response.data['features']}');
        debugPrint('Chambres: ${response.data['features']['bedrooms']}');
        debugPrint('Salles de bain: ${response.data['features']['bathrooms']}');
        debugPrint('Surface: ${response.data['features']['area']}');
      } else {
        debugPrint('⚠️ ALERTE: Aucun objet features trouvé!');
      }
      
      // Vérifier si location existe et sa structure
      if (response.data['location'] != null) {
        debugPrint('Location trouvé: ${response.data['location']}');
      } else {
        debugPrint('⚠️ ALERTE: Aucun objet location trouvé!');
      }
      
      // Vérifier les images
      debugPrint('Images: ${response.data['images']}');
      debugPrint('Type des images: ${response.data['images']?.runtimeType}');
      debugPrint('================================================');
      
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
    switch (backendType.toLowerCase().trim()) {
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
      case 'grenier':
        return model.ResidenceType.grenier;

      // 🏨 Hôtels & Hébergements classiques
      case 'hôtel de passage':
      case 'hotel de passage':
      case 'hotel_de_passage':
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
      case 'hoteldeluxe':
        return model.ResidenceType.hotelDeLuxe;
      case 'auberge et maison d\'hôtes':
      case 'auberge et maison d\'hotes':
      case 'auberge_et_maison_dhotes':
      case 'aubergeetmaisondhotes':
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
      case 'chambreencolocation':
        return model.ResidenceType.chambreEnColocation;
      case 'cohabitation':
        return model.ResidenceType.cohabitation;
      case 'résidence universitaire':
      case 'residence universitaire':
      case 'residence_universitaire':
      case 'residenceuniversitaire':
        return model.ResidenceType.residenceUniversitaire;
      case 'cité dortoir':
      case 'cite dortoir':
      case 'cite_dortoir':
      case 'citedortoir':
        return model.ResidenceType.citeDortoir;

      // 🏡 Résidences longue durée
      case 'appartement non meublé':
      case 'appartement non meuble':
      case 'appartement_non_meuble':
      case 'appartementnonmeuble':
        return model.ResidenceType.appartementNonMeuble;
      case 'villa non meublée':
      case 'villa non meublee':
      case 'villa_non_meublee':
      case 'villanonmeublee':
        return model.ResidenceType.villaNonMeublee;
      case 'immeuble':
        return model.ResidenceType.immeuble;
      case 'cour commune':
      case 'cour_commune':
      case 'courcommune':
        return model.ResidenceType.courCommune;

      // ⛺ Hébergements économiques et populaires
      case 'maison d\'hôtes économique':
      case 'maison d\'hotes economique':
      case 'maison_dhotes_economique':
      case 'maisondhoteseconomique':
        return model.ResidenceType.maisonDHotesEconomique;
      case 'résidence familiale en location':
      case 'residence familiale en location':
      case 'residence_familiale_en_location':
      case 'residencefamilialeenlocation':
        return model.ResidenceType.residenceFamilialeEnLocation;
      case 'chambres de passage':
      case 'chambres_de_passage':
      case 'chambresdepassage':
        return model.ResidenceType.chambresDePassage;

      // Types génériques de base
      case 'apartment':
      case 'appartement':
        return model.ResidenceType.apartment;
      case 'studio':
        return model.ResidenceType.studio;
      case 'villa':
        return model.ResidenceType.villa;
      case 'house':
      case 'maison':
        return model.ResidenceType.house;
      case 'hotel':
      case 'hôtel':
        return model.ResidenceType.hotel;
      case 'luxury':
      case 'luxe':
        return model.ResidenceType.luxury;
        
      default:
        debugPrint('⚠️ Type de résidence non reconnu: $backendType');
        return model.ResidenceType.other;
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
    
    // Extraire les sous-objets features et location s'ils existent
    final Map<String, dynamic> features = data['features'] is Map ? Map<String, dynamic>.from(data['features']) : {};
    final Map<String, dynamic> location = data['location'] is Map ? Map<String, dynamic>.from(data['location']) : {};
    
    // Extraire et formater correctement les URLs des images
    List<String> imageUrls = _extractImages(data['images']);
    
    // Extraire les coordonnées si elles existent
    List<double> coordinates = [];
    if (location['coordinates'] is Map && location['coordinates']['coordinates'] is List) {
      final List<dynamic> coords = location['coordinates']['coordinates'];
      if (coords.length >= 2) {
        coordinates = [
          coords[0] is num ? coords[0].toDouble() : 0.0,
          coords[1] is num ? coords[1].toDouble() : 0.0,
        ];
      }
    }
    
    return Residence(
      id: id,
      name: data['title'] ?? '',
      description: data['description'] ?? '',
      price: double.tryParse(data['price']?.toString() ?? '0') ?? 0,
      address: location['address'] ?? data['address'] ?? '',
      city: location['city'] ?? data['city'] ?? '',
      country: 'Côte d\'Ivoire', // Valeur par défaut
      images: imageUrls,
      bedrooms: int.tryParse(features['bedrooms']?.toString() ?? data['bedrooms']?.toString() ?? '0') ?? 0,
      bathrooms: int.tryParse(features['bathrooms']?.toString() ?? data['bathrooms']?.toString() ?? '0') ?? 0,
      surface: double.tryParse(features['area']?.toString() ?? data['area']?.toString() ?? '0') ?? 0,
      isAvailable: data['status'] == 'available',
      location: {
        'formattedAddress': location['address'] ?? data['address'] ?? '',
        'city': location['city'] ?? data['city'] ?? '',
        'coordinates': coordinates.isEmpty ? [0.0, 0.0] : coordinates,
      },
      amenities: _extractAmenities(features, data),
      type: type,
      rating: double.tryParse(data['rating']?.toString() ?? '0') ?? 0,
      reviewCount: int.tryParse(data['reviewCount']?.toString() ?? '0') ?? 0,
      ownerId: data['partner'] is String ? data['partner'] : null,
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : null,
      updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt']) : null,
    );
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