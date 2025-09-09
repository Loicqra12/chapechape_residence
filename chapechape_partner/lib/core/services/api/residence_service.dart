import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import '../../config/api_config.dart';
import '../../config/feature_flags.dart';
import '../../models/residence/residence.dart';
import '../../models/residence/residence_image.dart';
import '../../models/residence/nearby_place.dart';
import '../../models/residence/faq.dart';
import '../../exceptions/api_exception.dart';
import '../media/media_service.dart';
import '../media/cloudinary_service.dart';
import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:chapechape_partner/core/services/event_bus/residence_event_bus.dart';
import '../../models/pricing/pricing_model.dart';
import 'pricing_service.dart';

class ResidenceService {
  final String baseUrl;
  final http.Client client;
  final FlutterSecureStorage storage;
  final ResidenceEventBus _eventBus = ResidenceEventBus();
  late Dio _dio;
  late PricingService _pricingService;

  ResidenceService({
    required this.baseUrl,
    http.Client? client,
    FlutterSecureStorage? storage,
  }) : client = client ?? http.Client(),
       storage = storage ?? const FlutterSecureStorage() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30), // Augmenté de 5 à 30 secondes
        receiveTimeout: const Duration(seconds: 30), // Augmenté de 3 à 30 secondes
        sendTimeout: const Duration(seconds: 30),    // Ajouté explicitement
      ),
    );

    // Interceptor pour ajouter le token aux requêtes
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await this.storage.read(key: 'token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
    
    // Initialiser le service de pricing
    _pricingService = PricingService();
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await storage.read(key: 'token');
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  // Méthode utilitaire pour gérer les réponses HTTP et les erreurs
  T _handleResponse<T>(http.Response response, T Function(Map<String, dynamic> data) onSuccess) {
    try {
      final Map<String, dynamic> responseData = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseData['success'] == true) {
          return onSuccess(responseData);
        }
      }
      
      // Traiter les différents codes d'erreur
      switch (response.statusCode) {
        case 400:
          throw ApiException(
            'Requête invalide: ${responseData['message'] ?? 'Données incorrectes'}',
            response.statusCode,
            responseData
          );
        case 401:
          throw ApiException(
            'Non autorisé: Votre session a expiré, veuillez vous reconnecter',
            response.statusCode,
            responseData
          );
        case 403:
          throw ApiException(
            'Accès refusé: Vous n\'avez pas les permissions nécessaires',
            response.statusCode,
            responseData
          );
        case 404:
          throw ApiException(
            'Ressource non trouvée: ${responseData['message'] ?? 'La résidence demandée n\'existe pas'}',
            response.statusCode,
            responseData
          );
        case 500:
        case 502:
        case 503:
          throw ApiException(
            'Erreur serveur: Veuillez réessayer plus tard',
            response.statusCode,
            responseData
          );
        default:
          throw ApiException(
            responseData['message'] ?? 'Une erreur s\'est produite',
            response.statusCode,
            responseData
          );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      
      if (e is FormatException) {
        throw ApiException(
          'Erreur de format de réponse: Le serveur a renvoyé une réponse invalide',
          response.statusCode,
          {'rawResponse': response.body}
        );
      }
      
      throw ApiException(
        'Erreur inattendue: $e',
        response.statusCode,
        {'error': e.toString()}
      );
    }
  }

  Future<List<Residence>> getResidences() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await client.get(
        Uri.parse('$baseUrl/residences/my-residences'),
        headers: headers,
      );

      return _handleResponse<List<Residence>>(
        response,
        (data) {
          if (data.containsKey('data')) {
            var dataList = data['data'];
            if (dataList is List) {
              List<Residence> result = [];
              for (var item in dataList) {
                if (item is Map<String, dynamic>) {
                  result.add(_adaptBackendResidenceToFrontend(item));
                }
              }
              return result;
            }
          }
          throw ApiException(
            'Format de données inattendu pour les résidences',
            500,
            {'error': 'unexpected_data_format'}
          );
        }
      );
    } on SocketException {
      throw ApiException(
        'Pas de connexion Internet. Veuillez vérifier votre connexion et réessayer.',
        0,
        {'error': 'network_error'}
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      
      throw ApiException(
        'Échec du chargement des résidences: $e',
        500,
        {'error': e.toString()}
      );
    }
  }

  Future<List<Residence>> filterResidences(Map<String, dynamic> filters) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await client.get(
        Uri.parse('$baseUrl/residences/my-residences').replace(queryParameters: filters),
        headers: headers,
      );

      return _handleResponse<List<Residence>>(
        response,
        (data) {
          if (data.containsKey('data')) {
            var dataList = data['data'];
            if (dataList is List) {
              List<Residence> result = [];
              for (var item in dataList) {
                if (item is Map<String, dynamic>) {
                  result.add(_adaptBackendResidenceToFrontend(item));
                }
              }
              return result;
            }
          }
          throw ApiException(
            'Format de données inattendu pour les résidences filtrées',
            500,
            {'error': 'unexpected_data_format'}
          );
        }
      );
    } on SocketException {
      throw ApiException(
        'Pas de connexion Internet. Veuillez vérifier votre connexion et réessayer.',
        0,
        {'error': 'network_error'}
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      
      throw ApiException(
        'Échec du filtrage des résidences: $e',
        500,
        {'error': e.toString()}
      );
    }
  }

  Future<List<Residence>> sortResidences(String sortBy, bool ascending) async {
    try {
      final List<Residence> residences = await getResidences();
      
      residences.sort((a, b) {
        dynamic valueA;
        dynamic valueB;
        
        // Déterminer les valeurs à comparer en fonction du champ de tri
        switch (sortBy) {
          case 'name':
            valueA = a.name;
            valueB = b.name;
            break;
          case 'price':
            valueA = a.price;
            valueB = b.price;
            break;
          case 'bedrooms':
            valueA = a.bedrooms;
            valueB = b.bedrooms;
            break;
          case 'bathrooms':
            valueA = a.bathrooms;
            valueB = b.bathrooms;
            break;
          case 'surface':
            valueA = a.surface;
            valueB = b.surface;
            break;
          default:
            valueA = a.name;
            valueB = b.name;
        }
        
        // Tri ascendant ou descendant
        int compareResult;
        if (valueA is String && valueB is String) {
          compareResult = valueA.compareTo(valueB);
        } else if (valueA is num && valueB is num) {
          compareResult = valueA.compareTo(valueB);
        } else {
          compareResult = 0;
        }
        
        return ascending ? compareResult : -compareResult;
      });
      
      return residences;
    } catch (e) {
      if (e is ApiException) rethrow;
      
      throw ApiException(
        'Échec du tri des résidences: $e',
        500,
        {'error': e.toString()}
      );
    }
  }

  // Liste complète des équipements connus pour chaque résidence
  // Cette map persiste en mémoire tant que l'application est ouverte
  final Map<String, List<dynamic>> _residenceAmenities = {};
  
  // Méthode pour conserver les équipements d'une résidence
  void saveResidenceAmenities(String residenceId, List<dynamic> amenities) {
    _residenceAmenities[residenceId] = List.from(amenities);
    print('✅ Équipements sauvegardés pour la résidence $residenceId: $amenities');
  }
  
  Future<Residence> getResidenceById(String id) async {
    try {
      final headers = await _getAuthHeaders();
      // Ajouter des en-têtes pour désactiver le cache
      headers['Cache-Control'] = 'no-cache, no-store, must-revalidate';
      headers['Pragma'] = 'no-cache';
      headers['Expires'] = '0';
      
      // Ajouter un paramètre timestamp pour éviter le cache côté serveur
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final response = await client.get(
        Uri.parse('$baseUrl/residences/$id?_t=$timestamp'),
        headers: headers,
      );

      return _handleResponse<Residence>(
        response,
        (data) {
          if (data is Map<String, dynamic> && data.containsKey('data')) {
            var residenceData = data['data'];
            if (residenceData is Map<String, dynamic>) {
              // Vérifier si nous avons des équipements sauvegardés pour cette résidence
              if (_residenceAmenities.containsKey(id) && 
                  (_residenceAmenities[id]?.isNotEmpty ?? false) &&
                  residenceData.containsKey('amenities')) {
                
                // Récupérer les équipements actuels du backend
                final backendAmenities = residenceData['amenities'];
                // Récupérer nos équipements sauvegardés
                final savedAmenities = _residenceAmenities[id];
                
                // Si le backend renvoie moins d'équipements que ce que nous avons sauvegardé
                if (backendAmenities is List && 
                    savedAmenities != null && 
                    backendAmenities.length < savedAmenities.length) {
                  
                  print('❗ Incohérence détectée dans les équipements de la résidence $id');
                  print('ℹ️ Backend: $backendAmenities');
                  print('ℹ️ Sauvegardés: $savedAmenities');
                  
                  // Remplacer les équipements du backend par nos équipements sauvegardés
                  residenceData['amenities'] = savedAmenities;
                  print('✅ Équipements restaurés pour la résidence $id');
                }
              }
              
              return _adaptBackendResidenceToFrontend(residenceData);
            }
          }
          throw ApiException(
            'Format de données inattendu pour la résidence',
            500,
            {'error': 'unexpected_data_format'}
          );
        }
      );
    } on SocketException {
      throw ApiException(
        'Pas de connexion Internet. Veuillez vérifier votre connexion et réessayer.',
        0,
        {'error': 'network_error'}
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      
      throw ApiException(
        'Échec du chargement de la résidence: $e',
        500,
        {'error': e.toString()}
      );
    }
  }

  // Méthode utilitaire pour adapter les données de résidence du backend au frontend
  Residence _adaptBackendResidenceToFrontend(Map<String, dynamic> json) {
    try {
      print('Données adaptées: $json');
      // Résidence de base à retourner en cas d'erreur
      final defaultResidence = Residence(
        id: '',
        name: '',
        description: '',
        type: 'studio_meuble',
        price: 0,
        pricePeriod: 'month',
        address: '',
        city: '',
        images: [],
        mainImage: null,
        bedrooms: 0,
        bathrooms: 0,
        surface: 0,
        hasPool: false,
        hasWifi: false,
        hasRestaurant: false,
        isVacationResidence: false,
        isSpecialResidence: false,
        isAvailable: true,
        rating: 0,
        reviewCount: 0,
        category: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (json.isEmpty) {
        print('Données vides reçues du backend');
        return defaultResidence;
      }

      // Ajuster le type si nécessaire pour la compatibilité avec le frontend
      String residenceType = json['type']?.toString() ?? 'studio_meuble';
      // Important: Si le backend nous envoie "studio", nous le convertissons en "studio_meuble" pour le frontend
      if (residenceType == 'studio') {
        residenceType = 'studio_meuble';
      }

      // Extraire les taux avec des valeurs par défaut pour éviter les problèmes de nullabilité
      double hourlyRate = 0.0;
      double halfDayRate = 0.0;
      double fullDayRate = 0.0;
      double weekendRate = 0.0;
      
      // Traiter les taux horaires
      if (json['hourlyRates'] is Map && json['hourlyRates']['oneHour'] is num) {
        hourlyRate = (json['hourlyRates']['oneHour'] as num).toDouble();
      }
      
      // Traiter les taux journaliers
      if (json['dailyRates'] is Map) {
        if (json['dailyRates']['halfDay'] is num) {
          halfDayRate = (json['dailyRates']['halfDay'] as num).toDouble();
        }
        if (json['dailyRates']['fullDay'] is num) {
          fullDayRate = (json['dailyRates']['fullDay'] as num).toDouble();
        }
        if (json['dailyRates']['weekend'] is num) {
          weekendRate = (json['dailyRates']['weekend'] as num).toDouble();
        }
      }

      return Residence(
        id: json['_id']?.toString() ?? '',
        name: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        type: residenceType,
        price: (json['price'] is num) 
            ? (json['price'] as num).toDouble() 
            : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
        pricePeriod: json['pricePeriod']?.toString() ?? 'month',
        hourlyRate: hourlyRate,
        halfDayRate: halfDayRate,
        fullDayRate: fullDayRate,
        weekendRate: weekendRate,
        address: json['address']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        bedrooms: (json['bedrooms'] is num) 
            ? (json['bedrooms'] as num).toInt() 
            : int.tryParse(json['bedrooms']?.toString() ?? '0') ?? 0,
        bathrooms: (json['bathrooms'] is num) 
            ? (json['bathrooms'] as num).toInt() 
            : int.tryParse(json['bathrooms']?.toString() ?? '0') ?? 0,
        surface: (json['area'] is num) 
            ? (json['area'] as num).toDouble() 
            : double.tryParse(json['area']?.toString() ?? '0') ?? 0.0,
        amenities: json['amenities'] is List 
            ? List<String>.from(json['amenities']) 
            : <String>[],
        hasPool: json['hasPool'] == true,
        hasWifi: json['hasWifi'] == true,
        hasRestaurant: json['hasRestaurant'] == true,
        isVacationResidence: json['isVacationResidence'] == true,
        isSpecialResidence: json['isSpecialResidence'] == true,
        isAvailable: json['status'] == 'available',
        rating: 0,
        reviewCount: 0,
        category: json['category']?.toString() ?? '',
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt'].toString()) 
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null 
            ? DateTime.parse(json['updatedAt'].toString()) 
            : DateTime.now(),
        partnerInfo: _extractPartnerInfo(json),
        images: _extractImages(json),
        mainImage: json['mainImage']?.toString(),
      );
    } catch (e) {
      print('Erreur lors de l\'adaptation des données: $e');
      return Residence(
        id: json['_id']?.toString() ?? '',
        name: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        type: 'studio_meuble',
        price: 0,
        pricePeriod: 'month',
        address: json['address']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        images: [],
        mainImage: null,
        bedrooms: 0,
        bathrooms: 0,
        surface: 0,
        hasPool: false,
        hasWifi: false,
        hasRestaurant: false,
        isVacationResidence: false,
        isSpecialResidence: false,
        isAvailable: true,
        rating: 0,
        reviewCount: 0,
        category: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        hourlyRate: 0.0,
        halfDayRate: 0.0,
        fullDayRate: 0.0,
        weekendRate: 0.0,
      );
    }
  }
  
  // Méthode utilitaire pour adapter les données de résidence du frontend au backend
  Map<String, dynamic> _adaptFrontendResidenceToBackend(Map<String, dynamic> data) {
    // Créer une copie pour éviter de modifier l'original
    final Map<String, dynamic> adapted = Map.from(data);
    
    // ÉTAPE 1: Extraire les coordonnées GPS sous forme numérique
    final numLat = _extractNumericValue(data['latitude']);
    final numLng = _extractNumericValue(data['longitude']);
    
    // ÉTAPE 2: Supprimer tous les champs liés à la localisation pour éviter les conflits
    adapted.remove('locationData');
    adapted.remove('location');
    
    // ÉTAPE 3: Toujours conserver les coordonnées au niveau racine pour compatibilité
    adapted['latitude'] = numLat;
    adapted['longitude'] = numLng;
    
    // ÉTAPE 4: Formater les coordonnées dans la structure attendue par le backend
    // Le backend attend locationData.coordinates.latitude/longitude
    if (numLat != null && numLng != null) {
      adapted['locationData'] = {
        'coordinates': {
          'latitude': numLat,
          'longitude': numLng
        }
      };
    }

    // Adapter les noms de champs pour correspondre à ceux attendus par le backend
    if (data.containsKey('name')) {
      adapted['title'] = data['name'];
    }
    
    if (data.containsKey('surface')) {
      adapted['area'] = data['surface'];
    }
    
    // IMPORTANT: Convertir le type pour le backend
    if (data.containsKey('type')) {
      adapted['type'] = _mapFrontendTypeToBackendType(data['type']);
    }

    // Gérer le statut
    if (data['status'] != null) {
      adapted['isAvailable'] = data['status'] == 'available';
    }
    
    // Assurer que l'adresse formatée est utilisée si disponible
    if (data.containsKey('formattedAddress') && data['formattedAddress'] != null) {
      adapted['address'] = data['formattedAddress'];
    }

    // 3. Traiter les amenities dans une liste
    if (data['amenities'] != null) {
      // Si déjà une liste, la préserver
      if (data['amenities'] is List) {
        adapted['amenities'] = data['amenities'];
      } 
      // Si c'est une chaîne JSON, la parser
      else if (data['amenities'] is String) {
        try {
          adapted['amenities'] = jsonDecode(data['amenities']);
        } catch (e) {
          print('❌ Erreur de décodage des amenities: $e');
          adapted['amenities'] = [];
        }
      }
    } else {
      // Sinon, créer une liste à partir des propriétés booléennes
      final List<String> amenities = [];
      if (data['hasPool'] == true) amenities.add('pool');
      if (data['hasWifi'] == true) amenities.add('wifi');
      if (data['hasParking'] == true) amenities.add('parking');
      if (data['hasKitchen'] == true) amenities.add('kitchen');
      if (data['hasAirConditioning'] == true) amenities.add('air_conditioning');
      if (data['hasGym'] == true) amenities.add('gym');
      if (data['hasSpa'] == true) amenities.add('spa');
      if (data['hasMeetingRoom'] == true) amenities.add('meeting_room');
      if (data['hasTerrace'] == true) amenities.add('terrace');
      if (data['hasBalcony'] == true) amenities.add('balcony');
      if (data['isVacationResidence'] == true) amenities.add('vacation_residence');
      if (data['isSpecialResidence'] == true) amenities.add('special_residence');
      adapted['amenities'] = amenities;
    }

    // 4. Structurer les règles de la maison
    if (data['rules'] != null) {
      // Si déjà un objet ou liste, le préserver
      if (data['rules'] is Map || data['rules'] is List) {
        adapted['rules'] = data['rules'];
      } 
      // Si c'est une chaîne JSON, la parser
      else if (data['rules'] is String) {
        try {
          adapted['rules'] = jsonDecode(data['rules']);
        } catch (e) {
          print('❌ Erreur de décodage des règles: $e');
          adapted['rules'] = {};
        }
      }
    }

    print('🏠 Création résidence - Données adaptées: $data');
    print('🏠 Création résidence - JSON des données: ${json.encode(adapted)}');

    return adapted;
  }

  /// Extrait une valeur numérique à partir d'un objet qui peut être numérique ou un Map
  /// Utilisé pour gérer les coordonnées GPS qui peuvent être passées sous différentes formes
  /// @return num? - Retourne toujours une valeur numérique ou null, jamais un Map ou autre objet
  num? _extractNumericValue(dynamic value) {
    try {
      if (value == null) {
        return null;
      }
      
      // Si c'est déjà un nombre, retourner tel quel
      if (value is num) {
        return value;
      }
      
      // Si c'est une chaîne, essayer de la convertir en nombre
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      
      // Si c'est un Map (probablement un objet AddressSearchResult), extraire la valeur numérique
      if (value is Map) {
        // Essayer d'obtenir la valeur par la clé 'latitude' ou 'longitude'
        if (value.containsKey('latitude') && value['latitude'] != null) {
          final extractedValue = value['latitude'];
          // Récursion mais avec vérification explicite des types pour éviter les boucles infinies
          if (extractedValue is num) {
            return extractedValue;
          } else if (extractedValue is String) {
            return double.tryParse(extractedValue) ?? 0.0;
          } else {
            // Si on ne peut pas extraire une valeur numérique, retourner 0.0 par défaut
            print('Impossible d\'extraire une valeur numérique de latitude: $extractedValue');
            return 0.0;
          }
        }
        
        if (value.containsKey('longitude') && value['longitude'] != null) {
          final extractedValue = value['longitude'];
          // Récursion mais avec vérification explicite des types pour éviter les boucles infinies
          if (extractedValue is num) {
            return extractedValue;
          } else if (extractedValue is String) {
            return double.tryParse(extractedValue) ?? 0.0;
          } else {
            // Si on ne peut pas extraire une valeur numérique, retourner 0.0 par défaut
            print('Impossible d\'extraire une valeur numérique de longitude: $extractedValue');
            return 0.0;
          }
        }
        
        // Si on ne trouve pas ces clés, essayer de prendre la première valeur numérique
        for (var entry in value.entries) {
          if (entry.value is num) {
            print('Extraction de valeur numérique depuis Map: ${entry.value}');
            return entry.value;
          } else if (entry.value is String) {
            final numValue = double.tryParse(entry.value as String);
            if (numValue != null) {
              print('Extraction de valeur numérique depuis String: $numValue');
              return numValue;
            }
          }
        }
        
        // Aucune valeur numérique trouvée dans le Map
        print('Aucune valeur numérique trouvée dans: $value');
        return 0.0;
      }
      
      // Cas par défaut: impossible d'extraire une valeur numérique
      print('Type non supporté pour extraction numérique: ${value.runtimeType}');
      return 0.0;
    } catch (e) {
      print('Erreur lors de l\'extraction d\'une valeur numérique: $e');
      return 0.0;
    }
  }

  String _mapFrontendTypeToBackendType(String frontendType) {
    final Map<String, String> typeMapping = {
      // Résidences meublées
      'studio_meuble': 'studio',
      'appartement_meuble': 'apartment',
      'villa_meublee': 'villa',
      'penthouse': 'apartment',
      'loft': 'apartment',
      'grenier': 'apartment',
      
      // Hôtels & Hébergements classiques
      'hotel_passage': 'hotel',
      'motel': 'hotel',
      'boutique_hotel': 'hotel',
      'hotel_luxe': 'hotel',
      'guest_house': 'house',
      'residence_hoteliere': 'hotel',
      
      // Hébergements insolites & nature
      'bungalow': 'house',
      'lodge': 'house',
      'case_traditionnelle': 'house',
      'maison_flottante': 'house',
      'campement_touristique': 'house',
      
      // Colocation & résidences partagées
      'chambre_colocation': 'apartment',
      'coliving': 'apartment',
      'maison_hotes': 'house',
      'residence_universitaire': 'apartment',
      'cite_dortoir': 'apartment',
      
      // Résidences longue durée
      'appartement_vide': 'apartment',
      'villa_vide': 'villa',
      'immeuble': 'apartment',
      'cour_commune': 'house',
      
      // Hébergements économiques
      'maison_hotes_economique': 'house',
      'residence_familiale': 'house',
      'chambres_passage': 'apartment',
    };
  
    return typeMapping[frontendType] ?? 'apartment';
  }

  Future<Residence> createResidence(Map<String, dynamic> data, List<ResidenceImage> images) async {
    try {
      // Vérifier le token d'authentification
      final token = await storage.read(key: 'token');
      if (token == null) throw Exception('Aucun token d\'authentification trouvé');

      // Adapter les données pour le backend
      final adaptedData = _adaptFrontendResidenceToBackend(data);

      print('🏠 Création résidence - Approche en 2 étapes');
      print('🏠 Création résidence - Étape 1: Création de la résidence sans images');
      
      // Préparer les headers pour la requête JSON
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      // Vérifier les champs obligatoires
      final requiredFields = ['title', 'description', 'price', 'type', 'address', 'city', 'bedrooms', 'bathrooms', 'area'];
      for (final field in requiredFields) {
        if (adaptedData[field] == null || adaptedData[field].toString().isEmpty) {
          print('⚠️ Champ obligatoire manquant: $field');
          // Ajouter des valeurs par défaut
          if (field == 'title') adaptedData[field] = 'Sans titre';
          if (field == 'description') adaptedData[field] = 'Aucune description';
          if (field == 'price') adaptedData[field] = 0;
          if (field == 'type') adaptedData[field] = 'studio'; // Type par défaut
          if (field == 'address') adaptedData[field] = 'Adresse non spécifiée';
          if (field == 'city') adaptedData[field] = 'Abidjan';
          if (field == 'bedrooms') adaptedData[field] = 1;
          if (field == 'bathrooms') adaptedData[field] = 1;
          if (field == 'area') adaptedData[field] = 0;
        }
      }
      
      // S'assurer que le type est correctement mappé pour le backend
      if (adaptedData.containsKey('type') && adaptedData['type'] is String) {
        adaptedData['type'] = _mapFrontendTypeToBackendType(adaptedData['type']);
      }
      
      // Convertir en JSON
      final jsonBody = jsonEncode(adaptedData);
      print('🏠 Création résidence - Données JSON: $jsonBody');
      
      // Appel API pour créer la résidence
      // Suivre la même convention que getResidences() qui fonctionne
      // C'est-à-dire inclure explicitement /api/ même si baseUrl contient déjà ce préfixe
      final fullUrl = '$baseUrl/residences';
      
      print('🏠 Création résidence - URL complète: $fullUrl');
      
      final response = await client.post(
        Uri.parse(fullUrl),
        headers: headers,
        body: jsonBody,
      );
      
      print('🏠 Création résidence - Statut de la réponse: ${response.statusCode}');
        print('🏠 Création résidence - Corps de la réponse: ${response.body}');
        
      // Vérifier si la création a réussi
        if (response.statusCode != 201 && response.statusCode != 200) {
        throw ApiException(
          'Erreur lors de la création de la résidence: ${response.statusCode}',
          response.statusCode,
          {}
        );
      }
      
      // Extraire l'ID de la résidence créée
          final responseData = jsonDecode(response.body);
      if (!responseData['success']) {
        throw Exception('La création de la résidence a échoué: ${responseData['message']}');
      }
      
      final String residenceId = responseData['data']['_id'];
      print('🏠 Création résidence - Résidence créée avec ID: $residenceId');
      
      // Étape 2: Télécharger les images si disponibles
        if (images.isNotEmpty) {
        print('🏠 Création résidence - Étape 2: Téléchargement des ${images.length} images');
        await uploadResidenceImages(residenceId, images);
      }
      
      // Étape 3: Récupérer les détails complets de la résidence
      print('🏠 Création résidence - Étape 3: Récupération des détails de la résidence');
      final residence = await getResidenceById(residenceId);
      
      // Étape 4: Notifier les autres parties de l'application via le bus d'événements
      print('🏠 Création résidence - Étape 4: Notification des autres composants');
      _eventBus.emit(ResidenceEventType.created);
      
      return residence;
          } catch (e) {
      print('❌ Création résidence - Erreur: $e');
            if (e is ApiException) rethrow;
      throw ApiException(
        'Erreur lors de la création de la résidence: $e',
        500,
        {'error': e.toString()}
      );
    }
  }

  String _getImageMimeType(String filename) {
    final extension = filename.split('.').last;
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      case 'bmp':
        return 'bmp';
      default:
        return 'jpeg';
    }
  }

  Future<Residence> updateResidence(String id, Map<String, dynamic> data, List<ResidenceImage> images) async {
    try {
      // Vérifier le token d'authentification
      final token = await storage.read(key: 'token');
      if (token == null) throw Exception('Aucun token d\'authentification trouvé');

      // Adapter les données pour le backend
      final adaptedData = _adaptFrontendResidenceToBackend(data);

      print('Mise à jour de la résidence $id');
      print('Données adaptées: $adaptedData');
      print('Envoi de la requête avec ${images.length} images');

      // Utiliser http.MultipartRequest pour créer une requête multipart
      final request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/residences/$id'));
      
      // Ajouter le token d'authentification
      request.headers['Authorization'] = 'Bearer $token';
      
      // Ajouter tous les champs du formulaire
      adaptedData.forEach((key, value) {
        if (value != null) {
          if (value is List || value is Map) {
            request.fields[key] = jsonEncode(value);
          } else {
            request.fields[key] = value.toString();
          }
        }
      });
      
      // Ajouter les images si elles existent
      if (images.isNotEmpty) {
        for (int i = 0; i < images.length; i++) {
          final img = images[i];
          try {
            if (img.isWeb && img.webImage != null) {
              // Image web (Uint8List)
              print('Ajout de l\'image web ${i+1}/${images.length}');
              final multipartFile = http.MultipartFile.fromBytes(
                'images',
                img.webImage!,
                filename: 'image_${i+1}.jpg',
                contentType: MediaType('image', 'jpeg'),
              );
              request.files.add(multipartFile);
            } else if (img.file != null) {
              try {
                // Pour mobile
                print('Ajout de l\'image mobile ${i+1}/${images.length}');
                if (kIsWeb) {
                  // En environnement web, on ne peut pas utiliser fromPath ni readAsBytes()
                  print('Environnement web détecté, utilisation directe de webImage...');
                  
                  // Si nous avons une image web dans ResidenceImage, l'utiliser directement
                  if (img.webImage != null) {
                    final multipartFile = http.MultipartFile.fromBytes(
                      'images',
                      img.webImage!,
                      filename: 'image_${i+1}.jpg',
                      contentType: MediaType('image', 'jpeg'),
                    );
                    request.files.add(multipartFile);
                  } else {
                    print('⚠️ Création résidence - Impossible de lire le fichier en environnement web sans webImage');
                  }
                } else {
                  // Environnement mobile
                  final multipartFile = await http.MultipartFile.fromPath(
                    'images',
                    img.file!.path,
                    contentType: MediaType('image', 'jpeg'),
                  );
                  request.files.add(multipartFile);
                }
              } catch (e) {
                print('❌ Création résidence - Erreur lors de l\'ajout de l\'image: $e');
                // Continuer avec les autres images même si une échoue
              }
            }
          } catch (e) {
            print('Erreur lors de l\'ajout de l\'image: $e');
            // Continuer avec les autres images même si une échoue
          }
        }
      }
      
      // Afficher les données envoyées pour le debug
      print('Champs envoyés: ${request.fields}');
      print('Fichiers envoyés: ${request.files.length}');
      
      // Envoyer la requête
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      // Traiter la réponse
      print('Réponse du serveur: ${response.statusCode}');
      if (kDebugMode) {
        print('Corps de la réponse: ${response.body}');
      }
      
      if (response.statusCode != 200) {
        final errorResponse = jsonDecode(response.body);
        final errorMessage = errorResponse['message'] ?? 'Erreur lors de la mise à jour de la résidence';
        throw ApiException(errorMessage, response.statusCode, {});
      }
      
      final responseData = jsonDecode(response.body);
      
      // Transformer et adapter la réponse API pour éviter les erreurs de conversion de type
      final Map<String, dynamic> residenceData = responseData['data'];
      
      // Préserver les équipements originaux car le backend peut ne pas tous les renvoyer
      try {
        // Vérifier d'abord si les amenities originales sont disponibles dans les données adaptées
        if (adaptedData.containsKey('amenities')) {
          // Utiliser les amenities originales des données adaptées
          final originalAmenities = adaptedData['amenities'];
          
          // Remplacer les équipements renvoyés par ceux envoyés initialement
          residenceData['amenities'] = originalAmenities;
          
          // Sauvegarder les équipements pour les futures requêtes getResidenceById
          saveResidenceAmenities(id, originalAmenities);
          
          print('✅ Préservation des équipements originaux: $originalAmenities');
        }
      } catch (e) {
        print('⚠️ Erreur lors de la préservation des équipements: $e');
      }
      
      // Extraire et simplifier les tarifs horaires et journaliers si présents
      if (residenceData.containsKey('hourlyRates') && residenceData['hourlyRates'] is Map) {
        try {
          final hourlyRates = residenceData['hourlyRates'] as Map<String, dynamic>;
          residenceData['hourlyRate'] = hourlyRates['oneHour'] ?? 0;
        } catch (e) {
          print('Erreur lors de la conversion des tarifs horaires: $e');
          residenceData['hourlyRate'] = 0;
        }
      }
      
      if (residenceData.containsKey('dailyRates') && residenceData['dailyRates'] is Map) {
        try {
          final dailyRates = residenceData['dailyRates'] as Map<String, dynamic>;
          residenceData['halfDayRate'] = dailyRates['halfDay'] ?? 0;
          residenceData['fullDayRate'] = dailyRates['fullDay'] ?? 0;
          residenceData['weekendRate'] = dailyRates['weekend'] ?? 0;
        } catch (e) {
          print('Erreur lors de la conversion des tarifs journaliers: $e');
          residenceData['halfDayRate'] = 0;
          residenceData['fullDayRate'] = 0;
          residenceData['weekendRate'] = 0;
        }
      }
      
      final residence = Residence.fromJson(residenceData);
      return residence;
    } catch (e) {
      print('Exception complète lors de la mise à jour de la résidence: $e');
      if (e is ApiException) rethrow;
      
      throw ApiException(
        'Erreur lors de la mise à jour de la résidence: $e',
        500,
        {}
      );
    }
  }

  // Méthode améliorée avec retry pour l'upload d'images
  /// Upload des images de résidence avec possibilité d'utiliser Cloudinary
  /// 
  /// Si [useCloudinary] est true, les images sont d'abord uploadées vers Cloudinary
  /// puis les URLs sont envoyées au backend.
  /// Sinon, les images sont directement envoyées au backend via multipart.
  Future<void> uploadResidenceImages(
    String residenceId, 
    List<ResidenceImage> images, 
    {int maxRetries = 3, bool? useCloudinary}
  ) async {
    // Utiliser la valeur du paramètre ou celle du feature flag
    final useCloudinaryFlag = useCloudinary ?? FeatureFlags.useCloudinary;
    try {
      final logger = Logger('UploadImages');
      logger.info("\n===== DÉBUT DE L'UPLOAD DES IMAGES =====");
      logger.info("Téléchargement de ${images.length} images pour la résidence $residenceId");
      logger.info("Mode: ${useCloudinaryFlag ? 'Cloudinary' : 'Upload direct'}");
      
      // Si aucune image à télécharger, sortir immédiatement
      if (images.isEmpty) {
        logger.info("Aucune image à télécharger");
        return;
      }
      
      // Optimiser les images avant l'envoi
      final mediaService = MediaService();
      final optimizedImages = await mediaService.optimizeImagesForUpload(images);
      
      logger.info("${optimizedImages.length}/${images.length} images validées et optimisées");
      
      if (optimizedImages.isEmpty) {
        logger.warning("Aucune image valide à envoyer après validation");
        return;
      }
      
      // Si Cloudinary est activé, utiliser cette méthode
      if (useCloudinaryFlag) {
        await _uploadImagesWithCloudinary(residenceId, optimizedImages, logger);
        return;
      }
      
      // Sinon, continuer avec la méthode standard
      final token = await storage.read(key: 'token');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/residences/$residenceId/images'),
      );

      // Ajouter tous les headers nécessaires
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      logger.info("Préparation des images pour l'upload:");
      // SIMPLIFIÉ: Parcourir chaque image et l'ajouter avec le MÊME nom de champ "images"
      // Le backend s'attend à recevoir plusieurs fichiers avec le même nom de champ
      int imagesAdded = 0;
      
      for (var i = 0; i < optimizedImages.length; i++) {
        final image = optimizedImages[i];
        
        try {
          if (image.url != null && image.url!.startsWith('http')) {
            // Si c'est une URL externe, on ne l'ajoute pas comme fichier mais comme champ
            logger.fine("Image ${i+1}: URL externe (ignorée pour l'upload): ${image.url}");
            // Ne pas ajouter aux fichiers, c'est déjà sur le serveur
            continue;
          }
          
          if (image.isWeb && image.webImage != null) {
            // Image web (Uint8List)
            logger.fine("Image ${i+1}: Préparation de l'image web (${image.webImage!.length} octets)");
            final multipartFile = http.MultipartFile.fromBytes(
              'images',  // IMPORTANT: Le nom du champ doit être "images" pour toutes les images
              image.webImage!,
              filename: 'image_${i+1}.jpg',
              contentType: MediaType('image', 'jpeg'),
            );
            request.files.add(multipartFile);
            imagesAdded++;
            logger.fine("Image ${i+1}: Ajoutée à la requête (fichier: image_${i+1}.jpg)");
          } else if (image.file != null) {
            if (kIsWeb) {
              // Pour environnement web avec File (pas supporté directement)
              logger.fine("Image ${i+1}: Impossible d'utiliser File en environnement web");
              if (image.webImage != null) {
                logger.fine("Image ${i+1}: Utilisation de webImage comme alternative");
                final multipartFile = http.MultipartFile.fromBytes(
                  'images',
                  image.webImage!,
                  filename: 'image_${i+1}.jpg',
                  contentType: MediaType('image', 'jpeg'),
                );
                request.files.add(multipartFile);
                imagesAdded++;
                logger.fine("Image ${i+1}: Ajoutée à la requête via webImage");
              } else {
                logger.warning("Image ${i+1}: Pas de webImage disponible, image ignorée");
              }
              continue;
            }
            
            // Image File (mobile native)
            logger.fine("Image ${i+1}: Préparation de l'image mobile (${image.file!.path})");
            final multipartFile = await http.MultipartFile.fromPath(
              'images',  // IMPORTANT: Le nom du champ doit être "images" pour toutes les images
              image.file!.path,
              contentType: MediaType('image', 'jpeg'),
            );
            request.files.add(multipartFile);
            imagesAdded++;
            logger.fine("Image ${i+1}: Ajoutée à la requête (fichier: ${path.basename(image.file!.path)})");
          } else {
            logger.warning("Image ${i+1}: Aucun contenu valide trouvé, image ignorée");
          }
        } catch (e) {
          logger.warning("Image ${i+1}: Erreur lors de la préparation: $e");
          // Continuer avec les autres images
        }
      }

      logger.info("Récapitulatif: $imagesAdded/${optimizedImages.length} images prêtes à être envoyées");
      
      if (imagesAdded == 0) {
        logger.warning("Aucune image valide à envoyer après préparation");
        return;
      }
      
      // Afficher les informations de debug (uniquement en mode développement)
      if (kDebugMode) {
        _dio.interceptors.add(PrettyDioLogger());
      }
      logger.fine("URL: ${request.url}");
      logger.fine("Headers: ${request.headers}");
      logger.fine("Files count: ${request.files.length}");
      
      // Envoi de la requête
      logger.info("Envoi des images au serveur...");
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      logger.info("Statut de la réponse: ${response.statusCode}");
      if (kDebugMode) {
        logger.fine("Corps de la réponse: ${response.body}");
      }
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        logger.info("Images téléchargées avec succès!");
        return;
      } else {
        logger.warning("Échec du téléchargement des images: ${response.statusCode}");
        logger.warning("Détail de l'erreur: ${response.body}");
        throw ApiException(
          'Erreur lors du téléchargement des images: ${response.statusCode}',
          response.statusCode,
          {'error': response.body}
        );
      }
    } catch (e) {
      final logger = Logger('UploadImages');
      logger.severe("Exception complète lors de l'upload d'images: $e");
      if (e is ApiException) rethrow;
      
      throw ApiException(
        'Échec de l\'envoi des images: $e',
        500,
        {'error': e.toString()}
      );
    } finally {
      Logger('UploadImages').info("===== FIN DE L'UPLOAD DES IMAGES =====\n");
    }
  }
  
  /// Upload des images via Cloudinary puis envoi des URLs au backend
  /// 
  /// Cette méthode gère le processus complet:
  /// 1. Upload des images vers Cloudinary
  /// 2. Collecte des URLs générées
  /// 3. Envoi des URLs au backend pour mise à jour de la résidence
  Future<void> _uploadImagesWithCloudinary(
    String residenceId,
    List<ResidenceImage> optimizedImages,
    Logger logger
  ) async {
    try {
      logger.info("🌥️ Utilisation de Cloudinary pour l'upload des images");
      
      // Initialiser Cloudinary
      final cloudinaryService = CloudinaryService();
      final List<String> cloudinaryUrls = [];
      
      // Upload de chaque image vers Cloudinary
      for (var i = 0; i < optimizedImages.length; i++) {
        final image = optimizedImages[i];
        
        try {
          // Si c'est déjà une URL externe (comme une URL Cloudinary), la conserver
          if (image.url != null && image.url!.startsWith('http')) {
            logger.fine("Image ${i+1}: URL externe conservée: ${image.url}");
            cloudinaryUrls.add(image.url!);
            continue;
          }
          
          // Upload vers Cloudinary avec dossier par résidence
          final url = await cloudinaryService.uploadImage(
            image,
            folder: 'chapechape/residences/$residenceId',
          );
          
          cloudinaryUrls.add(url);
          logger.info("Image ${i+1}: Uploadée vers Cloudinary: $url");
          
        } catch (e) {
          logger.warning("Image ${i+1}: Erreur upload Cloudinary: $e");
          // Continuer avec les autres images
        }
      }
      
      if (cloudinaryUrls.isEmpty) {
        logger.warning("Aucune image n'a pu être uploadée vers Cloudinary");
        throw ApiException(
          'Échec de l\'upload des images vers Cloudinary',
          500,
          {'error': 'cloudinary_upload_failed'}
        );
      }
      
      // Envoi des URLs au backend
      logger.info("Envoi de ${cloudinaryUrls.length} URLs Cloudinary au backend");
      
      final token = await storage.read(key: 'token');
      final response = await http.post(
        Uri.parse('$baseUrl/residences/$residenceId/images'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'images': cloudinaryUrls,
        }),
      );
      
      logger.info("Statut de la réponse: ${response.statusCode}");
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        logger.info("✅ URLs Cloudinary enregistrées avec succès!");
        return;
      } else {
        logger.warning("❌ Échec de l'enregistrement des URLs: ${response.statusCode}");
        logger.warning("Détail de l'erreur: ${response.body}");
        throw ApiException(
          'Erreur lors de l\'enregistrement des URLs Cloudinary: ${response.statusCode}',
          response.statusCode,
          {'error': response.body}
        );
      }
    } catch (e) {
      logger.severe("Exception complète lors de l'upload via Cloudinary: $e");
      if (e is ApiException) rethrow;
      
      throw ApiException(
        'Échec de l\'upload via Cloudinary: $e',
        500,
        {'error': e.toString()}
      );
    }
  }

  Future<void> deleteResidence(String id) async {
    try {
      print("🗑️ Début de la suppression de la résidence $id");
      final headers = await _getAuthHeaders();
      final response = await client.delete(
        Uri.parse('$baseUrl/residences/$id'),
        headers: headers,
      );

      print("📊 Status code de la suppression: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        print("✅ Résidence $id supprimée avec succès");
        
        // Vider le cache local pour forcer un rafraîchissement
        try {
          if (storage != null) {
            storage.delete(key: 'residences_cache');
            print("🧹 Cache des résidences effacé après suppression");
          }
        } catch (e) {
          print("⚠️ Erreur lors de la suppression du cache: $e");
        }
      } else {
        print("⚠️ Code de statut inattendu lors de la suppression: ${response.statusCode}");
        throw ApiException(
          'Erreur lors de la suppression de la résidence',
          response.statusCode,
          json.decode(response.body)
        );
      }
    } on SocketException {
      throw ApiException(
        'Pas de connexion Internet. Veuillez vérifier votre connexion et réessayer.',
        0,
        {'error': 'network_error'}
      );
    } catch (e) {
      print("❌ Erreur lors de la suppression: $e");
      rethrow;
    }
  }

  Future<List<Residence>> searchResidences(String query) async {
    try {
      final headers = await _getAuthHeaders();
      // Rechercher d'abord localement puis faire la requête au serveur si nécessaire
      final List<Residence> allResidences = await getResidences();
      
      // Recherche locale par filtrage
      if (query.isNotEmpty) {
        final queryLower = query.toLowerCase();
        return allResidences.where((residence) {
          return residence.name.toLowerCase().contains(queryLower) ||
                 residence.address.toLowerCase().contains(queryLower) ||
                 residence.city.toLowerCase().contains(queryLower) ||
                 residence.description.toLowerCase().contains(queryLower);
        }).toList();
      }
      
      return allResidences;
    } catch (e) {
      if (e is ApiException) rethrow;
      
      throw ApiException(
        'Échec de la recherche de résidences: $e',
        500,
        {'error': e.toString()}
      );
    }
  }

  // Méthode spécifique pour obtenir les résidences d'un partenaire
  Future<List<Residence>> getPartnerResidences() async {
    try {
      debugPrint('📥 Début de la récupération des résidences du partenaire');
      
      final headers = await _getAuthHeaders();
      
      // 🔧 FIX: Utiliser la route backend correcte qui existe
      // La route /api/residences/my-residences utilise le token JWT pour identifier le partenaire
      final response = await client.get(
        Uri.parse('$baseUrl/residences/my-residences'),
        headers: headers,
      );

      return _handleResponse<List<Residence>>(
        response,
        (data) {
          if (data is Map<String, dynamic> && data.containsKey('data')) {
            var dataList = data['data'];
            if (dataList is List) {
              List<Residence> result = [];
              for (var item in dataList) {
                if (item is Map<String, dynamic>) {
                  result.add(_adaptBackendResidenceToFrontend(item));
                }
              }
              debugPrint('✅ Récupéré ${result.length} résidences du partenaire');
              return result;
            }
          }
          throw ApiException(
            'Format de données inattendu pour les résidences du partenaire',
            500,
            {'error': 'unexpected_data_format'}
          );
        }
      );
    } on SocketException {
      throw ApiException(
        'Pas de connexion Internet. Veuillez vérifier votre connexion et réessayer.',
        0,
        {'error': 'network_error'}
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      
      throw ApiException(
        'Échec du chargement des résidences du partenaire: $e',
        500,
        {'error': e.toString()}
      );
    }
  }

  List<String> _extractImages(Map<String, dynamic> json) {
    List<String> imageUrls = [];
    
    if (json.containsKey('images') && json['images'] != null) {
      var images = json['images'];
      if (images is List) {
        for (var image in images) {
          String imageUrl = '';
          
          if (image is String) {
            imageUrl = image;
          } else if (image is Map) {
            imageUrl = image['url'] ?? '';
          }
          
          // Ajouter le domaine si c'est un chemin relatif
          if (imageUrl.isNotEmpty) {
            if (!imageUrl.startsWith('http')) {
              // Supprimer les doubles slashes potentiels
              while (imageUrl.startsWith('/')) {
                imageUrl = imageUrl.substring(1);
              }
              
              // Construire l'URL complète
              String serverUrl = baseUrl.replaceAll('/api', '');
              // S'assurer que serverUrl se termine par un slash
              if (!serverUrl.endsWith('/')) {
                serverUrl = '$serverUrl/';
              }
              
              imageUrl = '$serverUrl$imageUrl';
            }
            print("URL d'image extraite: $imageUrl");
            imageUrls.add(imageUrl);
          }
        }
      }
    }
    
    // Vérifier l'image principale aussi
    if (json.containsKey('mainImage') && json['mainImage'] is String && json['mainImage'].isNotEmpty) {
      String mainImageUrl = json['mainImage'];
      if (!mainImageUrl.startsWith('http')) {
        // Supprimer les doubles slashes potentiels
        while (mainImageUrl.startsWith('/')) {
          mainImageUrl = mainImageUrl.substring(1);
        }
        
        // Construire l'URL complète
        String serverUrl = baseUrl.replaceAll('/api', '');
        // S'assurer que serverUrl se termine par un slash
        if (!serverUrl.endsWith('/')) {
          serverUrl = '$serverUrl/';
        }
        
        String fullMainImageUrl = '$serverUrl$mainImageUrl';
        print("URL d'image principale complète: $fullMainImageUrl");
        
        // Ajouter l'image principale aux URLs si elle n'y est pas déjà
        if (!imageUrls.contains(fullMainImageUrl)) {
          imageUrls.add(fullMainImageUrl);
        }
        
        // Mettre à jour la propriété mainImage dans le json pour qu'elle soit utilisée avec l'URL complète
        json['mainImage'] = fullMainImageUrl;
      }
    }
    
    print("Total d'images extraites: ${imageUrls.length}");
    return imageUrls;
  }

  // Méthode pour extraire les informations du partenaire de manière robuste
  Map<String, dynamic>? _extractPartnerInfo(Map<String, dynamic> json) {
    try {
      // Cas 1: L'objet partner est présent avec un format standard
      if (json['partner'] is Map<String, dynamic>) {
        var partner = json['partner'] as Map<String, dynamic>;
        print("Partner info from JSON: $partner");
        
        // Cas 1.1: Format avec _id
        if (partner.containsKey('_id')) {
          return {
            'id': partner['_id']?.toString() ?? '',
            'name': partner['name']?.toString() ?? 
                    "${partner['firstName'] ?? ''} ${partner['lastName'] ?? ''}".trim(),
            'email': partner['email']?.toString() ?? '',
          };
        }
        
        // Cas 1.2: Format avec id (sans underscore)
        if (partner.containsKey('id')) {
          return {
            'id': partner['id']?.toString() ?? '',
            'name': partner['name']?.toString() ?? 
                    "${partner['firstName'] ?? ''} ${partner['lastName'] ?? ''}".trim(),
            'email': partner['email']?.toString() ?? '',
          };
        }
      }
      
      // Cas 2: Juste l'ID du partenaire est présent (comme une chaîne)
      if (json['partner'] is String) {
        return {
          'id': json['partner']?.toString() ?? '',
          'name': 'Partenaire',
          'email': '',
        };
      }
      
      // Aucune information de partenaire trouvée
      print("Aucune information de partenaire trouvée dans: $json");
      return null;
    } catch (e) {
      print("Erreur lors de l'extraction des infos du partenaire: $e");
      return null;
    }
  }
  
  // Récupérer seulement les résidences du partenaire connecté
  Future<List<Residence>> getMyResidences() async {
    try {
      print("📥 Début de la récupération des résidences du partenaire");
      
      final headers = await _getAuthHeaders();
      // Ajouter des en-têtes pour désactiver le cache
      headers['Cache-Control'] = 'no-cache, no-store, must-revalidate';
      headers['Pragma'] = 'no-cache';
      headers['Expires'] = '0';
      
      // Récupérer l'ID du partenaire pour le logging
      final userId = await storage.read(key: 'userId');
      print("👤 ID du partenaire connecté: $userId");
      
      // Ajouter un paramètre timestamp pour éviter le cache côté serveur
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final response = await client.get(
        Uri.parse('$baseUrl/residences/my-residences?_t=$timestamp'),
        headers: headers,
      );

      print("📊 Status code: ${response.statusCode}");
      print("📝 Réponse brute: ${response.body}");

      return _handleResponse<List<Residence>>(
        response,
        (data) {
          if (data is Map<String, dynamic> && data.containsKey('data')) {
            var dataList = data['data'];
            if (dataList is List) {
              List<Residence> result = [];
              print("📋 Nombre d'éléments dans la réponse: ${dataList.length}");
              
              for (var item in dataList) {
                if (item is Map<String, dynamic>) {
                  // Ignorer les résidences marquées comme supprimées
                  if (item['deleted'] == true) {
                    print("🗑️ Résidence ignorée car supprimée: ${item['_id']}");
                    continue;
                  }
                  
                  var residence = _adaptBackendResidenceToFrontend(item);
                  print("🏠 Résidence trouvée - ID: ${residence.id}, Nom: ${residence.name}");
                  result.add(residence);
                }
              }
              
              print("✅ ${result.length} résidences actives récupérées pour le partenaire $userId");
              
              // Vider le cache local pour éviter les problèmes
              try {
                storage.delete(key: 'residences_cache');
                print("🧹 Cache des résidences effacé");
              } catch (e) {
                print("⚠️ Erreur lors de la suppression du cache: $e");
              }
              
              return result;
            }
          }
          print("⚠️ Format de données inattendu dans la réponse");
          throw ApiException(
            'Format de données inattendu pour les résidences',
            500,
            {'error': 'unexpected_data_format'}
          );
        }
      );
    } on SocketException {
      print("❌ Erreur de connexion réseau");
      throw ApiException(
        'Pas de connexion Internet. Veuillez vérifier votre connexion et réessayer.',
        0,
        {'error': 'network_error'}
      );
    } catch (e) {
      print("❌ Erreur lors de la récupération des résidences: $e");
      if (e is ApiException) rethrow;
      
      throw ApiException(
        'Échec du chargement des résidences: $e',
        500,
        {'error': e.toString()}
      );
    }
  }

  // Méthode pour mettre à jour une résidence avec des images
  Future<Residence> uploadImagesAndRefreshResidence(String residenceId, List<ResidenceImage> images) async {
    try {
      print("===== DÉBUT DE L'UPLOAD D'IMAGES ET RAFRAÎCHISSEMENT =====");
      
      // 1. Télécharger les images
      print("Étape 1: Téléchargement des images");
      await uploadResidenceImages(residenceId, images);
      
      // 2. Récupérer la résidence mise à jour pour obtenir les URLs des images
      print("Étape 2: Récupération de la résidence mise à jour");
      final updatedResidence = await getResidenceById(residenceId);
      
      // 3. Log pour déboguer
      print("Images dans la résidence mise à jour: ${updatedResidence.images.length}");
      updatedResidence.images.forEach((imgUrl) => print("- Image URL: $imgUrl"));
      
      // 4. Notifier les autres parties de l'application via le bus d'événements
      print("🔔 Notification de mise à jour de la résidence");
      _eventBus.emit(ResidenceEventType.updated);
      
      print("===== FIN DE L'UPLOAD D'IMAGES ET RAFRAÎCHISSEMENT =====");
      
      return updatedResidence;
    } on SocketException {
      throw ApiException(
        'Pas de connexion Internet. Veuillez vérifier votre connexion et réessayer.',
        0,
        {'error': 'network_error'}
      );
    } catch (e) {
      print("Erreur lors de l'upload et du rafraîchissement: $e");
      if (e is ApiException) rethrow;
      
      throw ApiException(
        'Échec de l\'envoi des images et du rafraîchissement: $e',
        500,
        {'error': e.toString()}
      );
    }
  }

  Future<void> deleteResidenceImage(String residenceId, String imageName) async {
    try {
      final headers = await _getAuthHeaders();
      
      final response = await client.delete(
        Uri.parse('$baseUrl/residences/$residenceId/images/$imageName'),
        headers: headers,
      );
      
      _handleResponse<void>(
        response,
        (data) => null
      );
    } on SocketException {
      throw ApiException(
        'Pas de connexion Internet. Veuillez vérifier votre connexion et réessayer.',
        0,
        {'error': 'network_error'}
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      
      throw ApiException(
        'Échec de la suppression de l\'image: $e',
        500,
        {'error': e.toString()}
      );
    }
  }

  // Méthodes pour les nouvelles fonctionnalités
  
  /// Ajoute un lieu à proximité d'une résidence
  Future<Map<String, dynamic>> addNearbyPlace(String residenceId, Map<String, dynamic> nearbyPlace) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        throw ApiException('Token non trouvé. Veuillez vous reconnecter.', 401, {});
      }

      final response = await _dio.post(
        '/api/residences/$residenceId/nearby-places',
        data: nearbyPlace,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201) {
        return response.data['data'];
      } else {
        throw ApiException('Erreur lors de l\'ajout du lieu à proximité: ${response.statusMessage}', 
            response.statusCode ?? 500, response.data ?? {});
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 500;
      final data = e.response?.data ?? {};
      final message = e.response?.statusMessage ?? e.message ?? 'Erreur réseau';
      throw ApiException('Erreur lors de l\'ajout du lieu à proximité: $message', statusCode, data);
    } catch (e) {
      throw ApiException('Erreur lors de l\'ajout du lieu à proximité: $e', 500, {});
    }
  }

  /// Ajoute une FAQ à une résidence
  Future<Map<String, dynamic>> addFaq(String residenceId, Map<String, dynamic> faq) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        throw ApiException('Token non trouvé. Veuillez vous reconnecter.', 401, {});
      }

      final response = await _dio.post(
        '/api/residences/$residenceId/faqs',
        data: faq,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201) {
        return response.data['data'];
      } else {
        throw ApiException('Erreur lors de l\'ajout de la FAQ: ${response.statusMessage}', 
            response.statusCode ?? 500, response.data ?? {});
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 500;
      final data = e.response?.data ?? {};
      final message = e.response?.statusMessage ?? e.message ?? 'Erreur réseau';
      throw ApiException('Erreur lors de l\'ajout de la FAQ: $message', statusCode, data);
    } catch (e) {
      throw ApiException('Erreur lors de l\'ajout de la FAQ: $e', 500, {});
    }
  }

  /// Met à jour les équipements améliorés d'une résidence
  Future<Map<String, dynamic>> updateEnhancedAmenities(String residenceId, Map<String, dynamic> enhancedAmenities) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        throw ApiException('Token non trouvé. Veuillez vous reconnecter.', 401, {});
      }

      final response = await _dio.put(
        '/api/residences/$residenceId/enhanced-amenities',
        data: enhancedAmenities,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw ApiException('Erreur lors de la mise à jour des équipements améliorés: ${response.statusMessage}', 
            response.statusCode ?? 500, response.data ?? {});
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 500;
      final data = e.response?.data ?? {};
      final message = e.response?.statusMessage ?? e.message ?? 'Erreur réseau';
      throw ApiException('Erreur lors de la mise à jour des équipements améliorés: $message', statusCode, data);
    } catch (e) {
      throw ApiException('Erreur lors de la mise à jour des équipements améliorés: $e', 500, {});
    }
  }

  /// Met à jour les méthodes de paiement acceptées pour une résidence
  Future<List<String>> updatePaymentMethods(String residenceId, List<String> paymentMethods) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        throw ApiException('Token non trouvé. Veuillez vous reconnecter.', 401, {});
      }

      final response = await _dio.put(
        '/api/residences/$residenceId/payment-methods',
        data: {'paymentMethods': paymentMethods},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return List<String>.from(response.data['data']);
      } else {
        throw ApiException('Erreur lors de la mise à jour des méthodes de paiement: ${response.statusMessage}', 
            response.statusCode ?? 500, response.data ?? {});
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 500;
      final data = e.response?.data ?? {};
      final message = e.response?.statusMessage ?? e.message ?? 'Erreur réseau';
      throw ApiException('Erreur lors de la mise à jour des méthodes de paiement: $message', statusCode, data);
    } catch (e) {
      throw ApiException('Erreur lors de la mise à jour des méthodes de paiement: $e', 500, {});
    }
  }
  
  /// Met à jour les points d'intérêt à proximité d'une résidence
  Future<bool> updateNearbyPlaces({
    required String residenceId,
    required List<NearbyPlace> places,
  }) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        throw ApiException('Token non trouvé. Veuillez vous reconnecter.', 401, {});
      }
      
      final response = await _dio.put(
        '/api/residences/$residenceId/nearby-places',
        data: {
          'nearbyPlaces': places.map((place) => place.toJson()).toList(),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('Erreur lors de la mise à jour des points d\'intérêt: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour des points d\'intérêt: $e');
      return false;
    }
  }
  
  /// Met à jour les FAQ d'une résidence
  Future<bool> updateFaqs({
    required String residenceId,
    required List<Faq> faqs,
  }) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        throw ApiException('Token non trouvé. Veuillez vous reconnecter.', 401, {});
      }
      
      final response = await _dio.put(
        '/api/residences/$residenceId/faqs',
        data: {
          'faqs': faqs.map((faq) => faq.toJson()).toList(),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      return response.statusCode == 200;
    } on DioException catch (e) {
      debugPrint('Erreur lors de la mise à jour des FAQ: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour des FAQ: $e');
      return false;
    }
  }

  // ===============================
  // MÉTHODES PRICING DYNAMIQUE
  // ===============================

  /// Calculer le pricing optimal pour une résidence
  Future<PricingModel> calculateResidencePricing({
    required double basePrice,
    String? paymentMethod,
  }) async {
    return await _pricingService.calculateOptimalPricing(
      basePrice: basePrice,
      paymentMethod: paymentMethod,
    );
  }

  /// Obtenir toutes les méthodes de paiement optimisées
  Future<List<PaymentMethodInfo>> getOptimizedPaymentMethods() async {
    return await _pricingService.getOptimizedPaymentMethods();
  }

  /// Analyser les économies potentielles pour un prix de résidence
  Future<SavingsAnalysis> calculateResidenceSavings({
    required double basePrice,
  }) async {
    return await _pricingService.calculateSavingsAnalysis(basePrice: basePrice);
  }

  /// Obtenir les statistiques de pricing du partner
  Future<PricingStats> getPartnerPricingStats() async {
    return await _pricingService.getPartnerPricingStats();
  }

  /// Calculer le pricing pour toutes les méthodes disponibles
  Future<Map<String, PricingModel>> calculateMultiMethodPricing({
    required double basePrice,
  }) async {
    return await _pricingService.calculateMultiMethodPricing(basePrice: basePrice);
  }

  /// Obtenir la méthode de paiement recommandée
  Future<String> getRecommendedPaymentMethod(double basePrice) async {
    return await _pricingService.getRecommendedPaymentMethod(basePrice);
  }

  /// Calculer les économies vs une méthode spécifique
  Future<double> calculateSavingsVsMethod({
    required double basePrice,
    required String comparisonMethod,
  }) async {
    return await _pricingService.calculateSavingsVsMethod(
      basePrice: basePrice,
      comparisonMethod: comparisonMethod,
    );
  }
}
