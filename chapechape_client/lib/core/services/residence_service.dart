import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chapechape_client/core/models/residence_model.dart';
import 'package:chapechape_client/core/models/residence_type_enum.dart'; 
import 'package:chapechape_client/core/services/api_service.dart';
import 'package:chapechape_client/core/services/cache_service.dart';
import 'package:chapechape_client/core/services/logger_service.dart';
import 'package:http/http.dart' as http;

class ResidenceService {
  final ApiService _apiService;
  final CacheService _cacheService;
  final LoggerService _logger = LoggerService();
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

  // Récupérer toutes les résidences (standards et partenaires)
  Future<List<Residence>> getAllResidences({
    Map<String, dynamic>? filters,
    int? page,
    int? limit,
    bool forceRefresh = false,
  }) async {
    try {
      _logger.info('📋 DÉBUT getAllResidences - forceRefresh: $forceRefresh');
      
      // Construire une clé de cache basée sur les paramètres
      final cacheKey = 'residences_all_${filters ?? ''}_page${page ?? 1}_limit${limit ?? 10}';
      
      // Vérifier si les données sont en cache et si on ne force pas le rafraîchissement
      if (!forceRefresh) {
        final cachedData = await _cacheService.get(cacheKey);
        if (cachedData != null) {
          final List<Residence> cachedResidences = (cachedData as List).cast<Residence>();
          _logger.info('📋 Utilisation des résidences en cache (${cachedResidences.length})');
          return cachedResidences;
        }
      }
      
      // Liste pour stocker toutes les résidences
      List<Residence> allResidences = [];
      bool hasLocalResidences = false;
      
      // 1. D'abord récupérer les résidences générales
      try {
        _logger.info('📋 Récupération des résidences générales...');
        final response = await _apiService.get(
          '/residences',
          queryParameters: {
            if (filters != null) ...filters,
            if (page != null) 'page': page,
            if (limit != null) 'limit': limit,
          },
        );
        
        if (response.data['data'] is List) {
          _logger.info('📋 ${(response.data['data'] as List).length} résidences générales trouvées');
          final residences = (response.data['data'] as List)
              .map((json) => _adaptBackendResidenceToClient(json))
              .toList();
          
          allResidences.addAll(residences);
          _logger.info('📋 Résidences générales ajoutées: ${residences.length}');
          hasLocalResidences = residences.isNotEmpty;
        } else {
          _logger.warning('📋 Aucune résidence générale trouvée');
        }
      } catch (e) {
        _logger.error('📋 ERREUR lors de la récupération des résidences générales', e);
        // Continuer même en cas d'erreur pour tenter de récupérer les résidences partenaires
      }
      
      // 2. Ensuite récupérer les résidences partenaires avec stratégie anti-429
      // Au lieu d'un délai fixe, utiliser un mécanisme de retry via notre interceptor
      try {
        _logger.info('📋 Récupération des résidences partenaires...');
        final response = await _apiService.get('/residences/all');
        
        if (response.statusCode == 200 && response.data is List) {
          _logger.info('📋 ${(response.data as List).length} résidences partenaires trouvées');
          final partnerResidences = (response.data as List)
              .map((json) => _adaptBackendResidenceToClient(json))
              .toList();
          
          allResidences.addAll(partnerResidences);
          _logger.info('📋 Résidences partenaires ajoutées: ${partnerResidences.length}');
        } else {
          _logger.warning('📋 Aucune résidence partenaire trouvée ou format de réponse incorrect');
        }
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 429) {
          _logger.error('📋 ERREUR lors de la récupération des résidences partenaires: Limite de taux (429)', e);
          // Si on n'a pas de résidences locales, essayer de récupérer du cache
          if (allResidences.isEmpty && !hasLocalResidences) {
            try {
              final cachedData = await _cacheService.get(cacheKey);
              if (cachedData != null) {
                _logger.info('📋 Utilisation du cache comme secours après erreur 429');
                return (cachedData as List).cast<Residence>();
              }
            } catch (cacheError) {
              _logger.error('📋 Impossible d\'accéder au cache', cacheError);
            }
          }
        } else {
          _logger.error('📋 ERREUR lors de la récupération des résidences partenaires', e);
        }
        // On continue avec les résidences locales uniquement
      }
      
      // Mettre en cache toutes les résidences obtenues (même si partielles)
      if (allResidences.isNotEmpty) {
        await _cacheService.put(cacheKey, allResidences, expiryInMinutes: 5);
        _logger.info('📋 ${allResidences.length} résidences mises en cache pour 5 minutes');
      }
      
      _logger.info('📋 FIN getAllResidences - ${allResidences.length} résidences au total');
      return allResidences;
    } catch (e) {
      _logger.error('📋 ERREUR GÉNÉRALE dans getAllResidences', e);
      return [];
    }
  }

  // Récupérer une résidence par son ID avec cache
  // Retourne Residence? pour indiquer que la résidence peut être null si non trouvée
  Future<Residence?> getResidenceById(String id, {bool forceRefresh = false}) async {
    final cacheKey = 'residence_$id';
    
    try {
      // Vérifier si on a des données en cache et qu'on ne force pas le rafraîchissement
      final cachedData = await _cacheService.get(cacheKey);
      if (cachedData != null && !forceRefresh) {
        print('🏠 Utilisation du cache pour la résidence $id');
        if (cachedData is Residence) {
          return cachedData;
        } else if (cachedData is Map<String, dynamic>) {
          try {
            return _adaptBackendResidenceToClient(cachedData);
          } catch (e) {
            print('🏠 ERREUR lors de l\'adaptation des données du cache: $e');
            // Si l'adaptation échoue, continuer avec la récupération depuis l'API
          }
        } else {
          print('🏠 Type de données en cache incorrect: ${cachedData.runtimeType}');
        }
      }
      
      print('🏠 Récupération des détails de la résidence $id depuis l\'API...');
      
      // Liste pour stocker les erreurs rencontrées
      final List<String> attempts = [];
      
      // Méthode 1: Essayer avec le endpoint standard
      try {
        // Ajouter un timestamp pour éviter les problèmes de cache
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        // Utiliser options au lieu de headers directement car l'API ne prend pas de headers
        final response = await _apiService.get(
          '/residences/$id?_t=$timestamp',
          options: Options(
            headers: {
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              'Pragma': 'no-cache',
              'Expires': '0',
            },
          ),
        );
        
        if (response.statusCode == 200) {
          if (response.data['data'] != null) {
            print('🏠 Résidence $id trouvée via endpoint normal');
            final residence = _adaptBackendResidenceToClient(response.data['data']);
            
            // Mettre en cache avec une durée de validité plus longue (15 minutes)
            await _cacheService.put(cacheKey, residence, expiryInMinutes: 15);
            
            return residence;
          }
        }
      } catch (e) {
        attempts.add('Endpoint standard: $e');
        print('🏠 Erreur lors de la récupération via l\'endpoint normal: $e');
      }
      
      // Méthode 2: Essayer avec une requête HTTP directe (comme dans l'app partenaire)
      try {
        // Utiliser une requête HTTP directe sans préfixe /api pour éviter les confusions
        final baseUrl = _apiService.baseUrl.replaceFirst('/api', '');
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        print('🏠 Tentative avec requête HTTP directe: $baseUrl/residences/$id?_t=$timestamp');
        final publicResponse = await http.get(
          Uri.parse('$baseUrl/residences/$id?_t=$timestamp'),
          headers: {
            'Accept': 'application/json',
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          },
        );
        
        if (publicResponse.statusCode == 200) {
          final responseData = json.decode(publicResponse.body);
          if (responseData['data'] != null) {
            print('🏠 Résidence $id trouvée via requête HTTP directe');
            final residence = _adaptBackendResidenceToClient(responseData['data']);
            await _cacheService.put(cacheKey, residence, expiryInMinutes: 15);
            return residence;
          }
        } else {
          attempts.add('Requête HTTP directe: ${publicResponse.statusCode} - ${publicResponse.body}');
        }
      } catch (publicError) {
        attempts.add('Requête HTTP directe: $publicError');
        print('🏠 Erreur lors de la tentative avec requête HTTP directe: $publicError');
      }
      
      // Méthode 3: Essayer avec la route /all qui ne nécessite pas d'authentification
      try {
        print('🏠 Tentative via la route /residences/all...');
        final allResponse = await _apiService.get('/residences/all');
        
        if (allResponse.statusCode == 200 && allResponse.data is List) {
          print('🏠 Recherche de la résidence $id dans ${allResponse.data.length} résidences...');
          final List<dynamic> allResidences = allResponse.data;
          
          // Rechercher la résidence par ID dans la liste
          final Map<String, dynamic>? foundResidence = allResidences.firstWhere(
            (item) => item['_id'] == id || item['id'] == id,
            orElse: () => null,
          );
          
          if (foundResidence != null) {
            print('🏠 Résidence $id trouvée via la route /all');
            final residence = _adaptBackendResidenceToClient(foundResidence);
            await _cacheService.put(cacheKey, residence, expiryInMinutes: 15);
            return residence;
          } else {
            attempts.add('Route /all: Résidence non trouvée dans la liste');
          }
        }
      } catch (allError) {
        attempts.add('Route /all: $allError');
        print('🏠 Erreur lors de la tentative via la route /all: $allError');
      }
      
      // Méthode 4: Rechercher dans toutes les résidences en cache
      try {
        print('🏠 Recherche de la résidence $id dans toutes les résidences en cache...');
        final cachedAllResidences = await _cacheService.get('all_residences');
        
        if (cachedAllResidences != null && cachedAllResidences is List) {
          final List<Residence> residences = cachedAllResidences.cast<Residence>();
          
          for (final residence in residences) {
            if (residence.id == id) {
              print('🏠 Résidence $id trouvée dans le cache global');
              await _cacheService.put(cacheKey, residence, expiryInMinutes: 15);
              return residence;
            }
          }
          
          attempts.add('Cache global: Résidence non trouvée');
        } else {
          attempts.add('Cache global: Aucune résidence en cache');
        }
      } catch (cacheError) {
        attempts.add('Cache global: $cacheError');
        print('🏠 Erreur lors de la recherche dans le cache: $cacheError');
      }
      
      // Si nous arrivons ici, la résidence n'a pas été trouvée
      print('🏠 RÉSIDENCE NON TROUVÉE APRÈS TOUTES LES TENTATIVES:');
      for (int i = 0; i < attempts.length; i++) {
        print('🏠 Tentative ${i+1}: ${attempts[i]}');
      }
      
      throw Exception('Résidence non trouvée après plusieurs tentatives');
    } catch (e) {
      print('🏠 ERREUR lors de la récupération de la résidence $id: $e');
      
      // En cas d'erreur, essayer de récupérer du cache même si forceRefresh=true
      if (forceRefresh) {
        try {
          final lastResortCache = await _cacheService.get(cacheKey);
          if (lastResortCache != null) {
            print('🏠 Utilisation du cache comme dernier recours malgré forceRefresh=true');
            return lastResortCache as Residence;
          }
        } catch (cacheError) {
          print('🏠 Impossible d\'accéder au cache comme dernier recours: $cacheError');
        }
      }
      
      return null; // Retourner null si la résidence n'a pas été trouvée
    }
  }

  // Rechercher des résidences avec des critères spécifiques
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
      final cachedData = await _cacheService.get(cacheKey);
      if (cachedData != null && !forceRefresh) {
        return (cachedData as List).cast<Residence>();
      }
      
      // Liste pour stocker tous les résultats de recherche
      List<Residence> allResults = [];
      
      // 1. Rechercher dans les résidences générales
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

        if (response.data['data'] is List) {
          final residences = (response.data['data'] as List)
              .map((json) => _adaptBackendResidenceToClient(json))
              .toList();
          
          allResults.addAll(residences);
        }
      } catch (e) {
        print('Erreur lors de la recherche de résidences générales: $e');
        // Continuer pour rechercher dans les résidences partenaires
      }
      
      // 2. Rechercher dans les résidences partenaires
      try {
        final partnerResponse = await _apiService.get(
          '/residences/all',
          queryParameters: {
            if (query != null) 'query': query,
            if (city != null) 'city': city,
          },
        );

        if (partnerResponse.data['data'] is List) {
          // Filtrer manuellement les résultats des partenaires
          final partnerResidences = (partnerResponse.data['data'] as List)
              .map((json) => _adaptBackendResidenceToClient(json))
              .where((residence) {
                bool matches = true;
                
                // Filtrer par prix si spécifié
                if (minPrice != null && residence.price < minPrice) matches = false;
                if (maxPrice != null && residence.price > maxPrice) matches = false;
                
                // Filtrer par nombre de chambres/salles de bain si spécifié
                if (bedrooms != null && residence.bedrooms < bedrooms) matches = false;
                if (bathrooms != null && residence.bathrooms < bathrooms) matches = false;
                
                // Filtrer par disponibilité si spécifié
                if (checkIn != null && checkOut != null) {
                  // Logique de vérification de disponibilité à implémenter
                }
                
                return matches;
              })
              .toList();
          
          // Ajouter les résidences partenaires qui ne sont pas déjà dans les résultats
          for (var residence in partnerResidences) {
            if (!allResults.any((r) => r.id == residence.id)) {
              allResults.add(residence);
            }
          }
        }
      } catch (e) {
        print('Erreur lors de la recherche de résidences partenaires: $e');
      }
      
      // Mettre en cache pour 5 minutes
      await _cacheService.put(cacheKey, allResults, expiryInMinutes: 5);
      
      return allResults;
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
      // Si l'objet est déjà une instance de Residence, le retourner directement
      if (data is Residence) {
        print('✅ Objet déjà de type Residence, pas besoin d\'adaptation');
        return data as Residence;
      }
      
      final String residenceTitle = data['title'] ?? data['name'] ?? 'Sans titre';
      final String residenceId = data['_id'] ?? data['id'] ?? '';
      
      print('✅ Adaptation de la résidence: $residenceTitle ($residenceId)');
      print('✅ Structure de données reçue: ${data.keys.join(', ')}');
      
      // Extraire et formater les images
      final List<String> images = _extractImages(data['images']);
      
      // Création de la localisation
      final Map<String, dynamic> locationMap = {
        'address': data['address'] ?? '',
        'city': data['city'] ?? '',
        'country': data['country'] ?? '',
      };
      
      // Ajouter les coordonnées si elles existent
      if (data['latitude'] != null && data['longitude'] != null) {
        locationMap['coordinates'] = [
          data['longitude'], 
          data['latitude']
        ];
      } else if (data['location']?['coordinates'] is List) {
        locationMap['coordinates'] = data['location']['coordinates'];
      }

      // Type de résidence
      String typeStr = (data['type'] ?? 'apartment').toString();
      final residenceType = _mapBackendTypeToClientType(typeStr);
      
      // Convertir de façon sécurisée les valeurs numériques
      int _safeParseInt(dynamic value, [int defaultValue = 0]) {
        if (value == null) return defaultValue;
        if (value is int) return value;
        try {
          return int.parse(value.toString());
        } catch (e) {
          print('❌ Erreur conversion int: $e pour valeur: $value');
          return defaultValue;
        }
      }
      
      double _safeParseDouble(dynamic value, [double defaultValue = 0.0]) {
        if (value == null) return defaultValue;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        try {
          return double.parse(value.toString());
        } catch (e) {
          print('❌ Erreur conversion double: $e pour valeur: $value');
          return defaultValue;
        }
      }
      
      // Extraire les règles de la résidence
      List<String> _extractRules(Map<String, dynamic> data) {
        if (data['rules'] == null) return [];
        
        if (data['rules'] is List) {
          return (data['rules'] as List).map((e) => e.toString()).toList();
        } else if (data['rules'] is Map) {
          // Si les règles sont fournies comme un objet, extraire les valeurs
          final Map<String, dynamic> rulesMap = data['rules'] as Map<String, dynamic>;
          List<String> rules = [];
          rulesMap.forEach((key, value) {
            if (value == true) {
              rules.add(key);
            } else if (value is String && value.isNotEmpty) {
              rules.add(value);
            }
          });
          return rules;
        }
        return [];
      }
      
      // Extraire les points d'intérêt à proximité
      List<String> _extractNearbyPlaces(Map<String, dynamic> data) {
        if (data['nearbyPlaces'] == null) return [];
        
        if (data['nearbyPlaces'] is List) {
          return (data['nearbyPlaces'] as List)
            .map((place) => place is Map ? place['name']?.toString() ?? '' : place.toString())
            .where((name) => name.isNotEmpty)
            .toList();
        }
        return [];
      }
      
      // Extraire et formater les FAQ
      List<Map<String, String>> _extractFaqs(Map<String, dynamic> data) {
        if (data['faqs'] == null) return [];
        
        if (data['faqs'] is List) {
          return (data['faqs'] as List)
            .map((faq) {
              if (faq is Map) {
                return {
                  'question': faq['question']?.toString() ?? '',
                  'answer': faq['answer']?.toString() ?? '',
                };
              }
              return <String, String>{};
            })
            .where((faq) => faq.isNotEmpty && faq['question']?.isNotEmpty == true)
            .toList();
        }
        return [];
      }
      
      // Extraire les équipements améliorés
      Map<String, dynamic> _extractEnhancedAmenities(Map<String, dynamic> data) {
        if (data['enhancedAmenities'] == null) return {};
        
        if (data['enhancedAmenities'] is Map) {
          return data['enhancedAmenities'] as Map<String, dynamic>;
        }
        return {};
      }
      
      // Extraire les méthodes de paiement acceptées
      List<String> _extractPaymentMethods(Map<String, dynamic> data) {
        if (data['paymentMethods'] == null) return [];
        
        if (data['paymentMethods'] is List) {
          return (data['paymentMethods'] as List).map((e) => e.toString()).toList();
        }
        return [];
      }
      
      // Extraction des tarifs
      double hourlyRate = _safeParseDouble(data['hourlyRate']);
      double halfDayRate = _safeParseDouble(data['halfDayRate']);
      double fullDayRate = _safeParseDouble(data['fullDayRate']);
      double weekendRate = _safeParseDouble(data['weekendRate']);
      
      // Si les tarifs sont fournis sous forme d'objets
      if (data['hourlyRates'] is Map) {
        hourlyRate = _safeParseDouble(data['hourlyRates']['oneHour'], hourlyRate);
      }
      
      if (data['dailyRates'] is Map) {
        halfDayRate = _safeParseDouble(data['dailyRates']['halfDay'], halfDayRate);
        fullDayRate = _safeParseDouble(data['dailyRates']['fullDay'], fullDayRate);
        weekendRate = _safeParseDouble(data['dailyRates']['weekend'], weekendRate);
      }
      
      // Extraire les règles, points d'intérêt et autres nouvelles propriétés
      final List<String> rules = _extractRules(data);
      final List<String> nearbyPlaces = _extractNearbyPlaces(data);
      final List<Map<String, String>> faqs = _extractFaqs(data);
      final Map<String, dynamic> enhancedAmenities = _extractEnhancedAmenities(data);
      final List<String> paymentMethods = _extractPaymentMethods(data);
      
      // Récupérer les informations sur les étoiles/classification
      final int stars = _safeParseInt(data['stars'], 0);
      
      print('✅ Règles extraites: ${rules.join(', ')}');
      print('✅ Équipements améliorés: ${enhancedAmenities.keys.join(', ')}');
      
      return Residence(
        id: residenceId,
        title: residenceTitle,
        description: data['description'] ?? 'Aucune description disponible',
        shortDescription: data['shortDescription'] ?? '',
        images: images,
        price: _safeParseDouble(data['price']),
        location: locationMap,
        bedrooms: _safeParseInt(data['bedrooms']),
        bathrooms: _safeParseInt(data['bathrooms']),
        squareMeters: data['surface'] != null 
          ? _safeParseDouble(data['surface']) 
          : _safeParseDouble(data['area']),
        amenities: data['amenities'] is List 
          ? (data['amenities'] as List).map((e) => e.toString()).toList() 
          : _extractAmenities(data['features'] ?? {}, data),
        hasPool: data['hasPool'] == true || (data['amenities'] is List && (data['amenities'] as List).contains('pool')),
        hasWifi: data['hasWifi'] == true || (data['amenities'] is List && (data['amenities'] as List).contains('wifi')),
        isVacationResidence: data['isVacationResidence'] == true,
        isSpecialResidence: data['isSpecial'] == true || data['isSpecialResidence'] == true,
        isAvailable: data['status'] == 'available' || data['isAvailable'] == true,
        isFeatured: data['isFeatured'] == true,
        isPopular: data['isPopular'] == true,
        isVerified: data['isVerified'] == true,
        isNew: data['isNew'] == true,
        rating: _safeParseDouble(data['rating']),
        reviewCount: _safeParseInt(data['reviews']),
        currency: data['currency']?.toString() ?? 'XOF',
        type: residenceType,
        maxOccupancy: _safeParseInt(data['maxOccupancy'], 2),
        owner: data['owner'] ?? data['ownerId'] ?? '',
        pricePeriod: data['pricePeriod']?.toString() ?? 'month',
        // Nouveaux champs ajoutés
        rules: rules,
        allowsPets: data['allowsPets'] == true || (rules.contains('pets') || rules.contains('allowsPets')),
        allowsSmoking: data['allowsSmoking'] == true || (rules.contains('smoking') || rules.contains('allowsSmoking')),
        allowsParties: data['allowsParties'] == true || (rules.contains('parties') || rules.contains('allowsParties')),
        nearbyAttractions: nearbyPlaces,
        hourlyRate: hourlyRate,
        halfDayRate: halfDayRate,
        fullDayRate: fullDayRate,
        weekendRate: weekendRate,
        isVip: data['isVip'] == true || stars >= 4,
        // Stocker les nouvelles propriétés étendues dans priceDetails pour compatibilité
        priceDetails: {
          'enhancedAmenities': enhancedAmenities,
          'paymentMethods': paymentMethods,
          'faqs': faqs,
          'stars': stars,
          'isFavorite': data['isFavorite'] == true,
        },
      );
    } catch (e, stackTrace) {
      print('❌ ERREUR lors de l\'adaptation de la résidence: $e');
      print('Stack trace: $stackTrace');
      print('❌ Données reçues: $data');
      
      // Créer une résidence par défaut en cas d'erreur
      return Residence(
        id: data['_id'] ?? data['id'] ?? 'error-${DateTime.now().millisecondsSinceEpoch}',
        title: data['title'] ?? 'Résidence indisponible',
        description: 'Information indisponible',
        shortDescription: '',
        images: [],
        price: 0,
        location: {'address': 'Adresse indisponible', 'city': '', 'country': ''},
        bedrooms: 0,
        bathrooms: 0,
        squareMeters: 0,
        amenities: [],
        hasPool: false,
        hasWifi: false,
        isVacationResidence: false,
        isSpecialResidence: false,
        isAvailable: false,
        isFeatured: false,
        isPopular: false,
        isVerified: false, 
        isNew: false,
        rating: 0.0,
        reviewCount: 0,
        currency: 'XOF',
        type: ResidenceType.apartment,
        maxOccupancy: 1,
        owner: '',
        pricePeriod: 'month',
        rules: [],
        allowsPets: false,
        allowsSmoking: false,
        allowsParties: false,
        hourlyRate: 0,
        halfDayRate: 0,
        fullDayRate: 0,
        weekendRate: 0,
        isVip: false,
      );
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
    if (imagesData == null) {
      print("❌ Images data est null");
      return [];
    }
    
    List<String> imageUrls = [];
    String baseUrl = _apiService.baseUrl;
    
    // S'assurer que l'URL de base se termine sans slash
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    
    // Nettoyer la baseUrl et s'assurer qu'elle ne contient pas de '/api' à la fin
    String cleanBaseUrl = baseUrl;
    if (cleanBaseUrl.endsWith('/api')) {
      cleanBaseUrl = cleanBaseUrl.substring(0, cleanBaseUrl.length - 4);
    } else {
      // Simplifier la logique pour éviter les problèmes de remplacements multiples
      final apiIndex = cleanBaseUrl.lastIndexOf('/api');
      if (apiIndex != -1) {
        cleanBaseUrl = cleanBaseUrl.substring(0, apiIndex);
      }
    }
    
    print("Base URL utilisée pour les images: $cleanBaseUrl");
    print("Images data brut: $imagesData");
    print("Type des données d'images: ${imagesData.runtimeType}");
    
    if (imagesData is List) {
      int index = 0;
      for (var img in imagesData) {
        String imageUrl = '';
        print("Traitement de l'image #$index: $img (type: ${img.runtimeType})");
        
        // Extraction de l'URL selon différents formats possibles
        if (img is String) {
          imageUrl = img;
        } else if (img is Map) {
          // Chercher des clés courantes pour les URLs d'images
          final possibleKeys = ['url', 'path', 'src', 'source', 'file', 'image'];
          for (final key in possibleKeys) {
            if (img[key] != null) {
              imageUrl = img[key].toString();
              print("✅ URL trouvée via la clé '$key': $imageUrl");
              break;
            }
          }
        }
        
        // Ajouter le domaine si c'est un chemin relatif
        if (imageUrl.isNotEmpty) {
          if (imageUrl.startsWith('http')) {
            // C'est déjà une URL complète, vérifier si elle contient '/uploads/' mais pas '/residences/'
            if (imageUrl.contains('/uploads/') && !imageUrl.contains('/uploads/residences/')) {
              imageUrl = imageUrl.replaceAll('/uploads/', '/uploads/residences/');
            }
          } else {
            // C'est un chemin relatif, normaliser et construire l'URL complète
            if (imageUrl.startsWith('/')) {
              imageUrl = imageUrl.substring(1);
            }
            
            // Vérifier différents patterns de chemins et normaliser
            if (imageUrl.startsWith('uploads/')) {
              if (!imageUrl.contains('residences/')) {
                imageUrl = imageUrl.replaceAll('uploads/', 'uploads/residences/');
              }
            } else if (!imageUrl.contains('uploads/')) {
              imageUrl = 'uploads/residences/$imageUrl';
            }
            
            // Construire l'URL complète
            imageUrl = '$cleanBaseUrl/$imageUrl';
          }
          
          // Vérifier si l'URL est valide
          final hasValidExtension = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].any(
            (ext) => imageUrl.toLowerCase().endsWith(ext)
          );
          
          if (hasValidExtension || imageUrl.contains('cloudinary.com') || imageUrl.contains('placeholder.com')) {
            print("✅ URL d'image #$index formatée et valide: $imageUrl");
            imageUrls.add(imageUrl);
          } else {
            print("⚠️ URL d'image #$index a un format inhabituel: $imageUrl");
            // Ajouter quand même, car c'est peut-être une URL valide sans extension
            imageUrls.add(imageUrl);
          }
        } else {
          print("❌ URL vide pour l'image #$index");
        }
        index++;
      }
    } else if (imagesData is Map) {
      // Si imagesData est un Map, essayer d'extraire les valeurs
      print("🔍 Images data est un Map, extraction des valeurs");
      imagesData.forEach((key, value) {
        if (value is String) {
          final imageUrl = _formatImageUrl(value, cleanBaseUrl);
          if (imageUrl.isNotEmpty) {
            imageUrls.add(imageUrl);
          }
        }
      });
    } else {
      print("❌ Images data n'est pas une liste ni un map: ${imagesData.runtimeType}");
    }
    
    // Si aucune image trouvée, ajouter une image par défaut
    if (imageUrls.isEmpty) {
      print("❌ Aucune image trouvée, utilisation de l'image par défaut");
      // Utiliser une image en ligne sécurisée pour éviter les problèmes d'assets manquants
      imageUrls.add('assets/images/placeholders/residence_standard.jpg');
      
      // Déboguer pourquoi aucune image n'a été trouvée
      if (imagesData != null) {
        print("🔍 Débogage des données d'images originales: $imagesData");
        if (imagesData is List && imagesData.isNotEmpty) {
          print("🔍 Premier élément des images: ${imagesData.first}");
        }
      }
    }
    
    print("Images finales extraites (${imageUrls.length}): ${imageUrls.join('\n')}");
    return imageUrls;
  }
  
  // Méthode auxiliaire pour formater une URL d'image
  String _formatImageUrl(String url, String baseUrl) {
    if (url.isEmpty) return '';
    
    if (url.startsWith('http')) {
      return url;
    }
    
    // Normaliser le chemin relatif
    if (url.startsWith('/')) {
      url = url.substring(1);
    }
    
    // Ajouter le préfixe 'uploads/residences/' si nécessaire
    if (!url.contains('uploads/')) {
      url = 'uploads/residences/$url';
    } else if (!url.contains('residences/')) {
      url = url.replaceAll('uploads/', 'uploads/residences/');
    }
    
    // Construire l'URL complète
    return '$baseUrl/$url';
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
  Future<List<Residence>> getFeaturedResidences({bool forceRefresh = false}) async {
    final cacheKey = 'featured_residences';
    
    try {
      // Vérifier si on a des données en cache et si on ne force pas le rafraîchissement
      final cachedData = await _cacheService.get(cacheKey);
      if (cachedData != null && !forceRefresh) {
        print('🌟 Utilisation du cache pour les résidences en vedette');
        final List<dynamic> cachedList = cachedData as List;
        return cachedList.map((e) => e as Residence).toList();
      }
      
      // Récupérer toutes les résidences
      final allResidences = await getAllResidences(forceRefresh: forceRefresh);
      
      // Filtrer les résidences mises en avant
      final featuredResidences = allResidences.where((r) => r.isFeatured == true).toList();
      print('🌟 ${featuredResidences.length} résidences en vedette trouvées');
      
      // Mettre en cache avec une durée de validité plus longue (30 minutes)
      if (featuredResidences.isNotEmpty) {
        await _cacheService.put(cacheKey, featuredResidences, expiryInMinutes: 30);
        print('🌟 Résidences en vedette mises en cache pour 30 minutes');
      }
      
      return featuredResidences;
    } catch (e) {
      print('🌟 ERREUR lors de la récupération des résidences en vedette: $e');
      
      // En cas d'erreur, essayer de récupérer du cache même si forceRefresh=true
      try {
        final cachedData = await _cacheService.get(cacheKey);
        if (cachedData != null) {
          print('🌟 Utilisation du cache comme fallback après erreur');
          final List<dynamic> cachedList = cachedData as List;
          return cachedList.map((e) => e as Residence).toList();
        }
      } catch (_) {}
      
      // Si tout échoue, retourner une liste vide
      return [];
    }
  }

  // Récupérer les résidences spéciales
  Future<List<Residence>> getSpecialResidences({bool forceRefresh = false}) async {
    final cacheKey = 'special_residences';
    
    try {
      // Vérifier si on a des données en cache et si on ne force pas le rafraîchissement
      final cachedData = await _cacheService.get(cacheKey);
      if (cachedData != null && !forceRefresh) {
        print('✨ Utilisation du cache pour les résidences spéciales');
        final List<dynamic> cachedList = cachedData as List;
        return cachedList.map((e) => e as Residence).toList();
      }
      
      // Récupérer toutes les résidences
      final allResidences = await getAllResidences(forceRefresh: forceRefresh);
      
      // Filtrer les résidences spéciales
      final specialResidences = allResidences.where((r) => r.isSpecialResidence == true).toList();
      print('✨ ${specialResidences.length} résidences spéciales trouvées');
      
      // Mettre en cache avec une durée de validité plus longue (30 minutes)
      if (specialResidences.isNotEmpty) {
        await _cacheService.put(cacheKey, specialResidences, expiryInMinutes: 30);
        print('✨ Résidences spéciales mises en cache pour 30 minutes');
      }
      
      return specialResidences;
    } catch (e) {
      print('✨ ERREUR lors de la récupération des résidences spéciales: $e');
      
      // En cas d'erreur, essayer de récupérer du cache même si forceRefresh=true
      try {
        final cachedData = await _cacheService.get(cacheKey);
        if (cachedData != null) {
          print('✨ Utilisation du cache comme fallback après erreur');
          final List<dynamic> cachedList = cachedData as List;
          return cachedList.map((e) => e as Residence).toList();
        }
      } catch (_) {}
      
      // Si tout échoue, retourner une liste vide
      return [];
    }
  }

  // Récupérer les résidences populaires
  Future<List<Residence>> getPopularResidences({bool forceRefresh = false}) async {
    final cacheKey = 'residences_popular';
    
    try {
      if (!forceRefresh) {
        final cachedData = await _cacheService.get(cacheKey);
        if (cachedData != null) {
          return (cachedData as List).cast<Residence>();
        }
      }
      
      List<Residence> popularResidences = [];
      
      // 1. Récupérer les résidences populaires standards
      try {
        final response = await _apiService.get('/residences/popular');
        if (response.data['data'] is List) {
          final residences = (response.data['data'] as List)
            .map((json) => _adaptBackendResidenceToClient(json))
            .toList();
          
          popularResidences.addAll(residences);
        }
      } catch (e) {
        print('Erreur lors de la récupération des résidences populaires standards: $e');
      }
      
      // 2. Récupérer toutes les résidences des partenaires et sélectionner les plus récentes
      try {
        final partnerResponse = await _apiService.get('/residences/all');
        if (partnerResponse.data['data'] is List) {
          // Convertir en objets Residence
          List<Residence> partnerResidences = (partnerResponse.data['data'] as List)
            .map((json) => _adaptBackendResidenceToClient(json))
            .toList();
          
          // Trier par date de création (les plus récentes d'abord)
          partnerResidences.sort((a, b) {
            // Vérification de null safety
            final dateA = a.createdAt ?? DateTime.now();
            final dateB = b.createdAt ?? DateTime.now();
            return dateB.compareTo(dateA);
          });
          
          // Prendre les 5 plus récentes
          partnerResidences = partnerResidences.take(5).toList();
          
          // Ajouter uniquement celles qui ne sont pas déjà présentes
          for (var residence in partnerResidences) {
            if (!popularResidences.any((r) => r.id == residence.id)) {
              popularResidences.add(residence);
            }
          }
        }
      } catch (e) {
        print('Erreur lors de la récupération des résidences populaires des partenaires: $e');
      }
      
      await _cacheService.put(cacheKey, popularResidences, expiryInMinutes: 5);
      return popularResidences;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Récupérer les avis d'une résidence
  Future<Map<String, dynamic>> getResidenceReviews(String residenceId, {int page = 1, int limit = 10}) async {
    try {
      _logger.info('📖 Récupération des avis pour la résidence $residenceId');
      
      final response = await _apiService.get(
        '/reviews/residence/$residenceId',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      
      return response.data;
    } catch (e) {
      _logger.error('📖 Exception lors de la récupération des avis');
      rethrow;
    }
  }

  // Soumettre un commentaire pour une résidence
  Future<bool> submitReview({
    required String residenceId,
    required double rating,
    required String comment,
  }) async {
    try {
      _logger.info('💬 Soumission d\'un commentaire pour la résidence $residenceId');
      
      // Appeler l'API pour enregistrer le commentaire
      final response = await _apiService.post(
        '/reviews',
        data: {
          'residenceId': residenceId,
          'rating': {
            'overall': rating,
            'cleanliness': rating,
            'comfort': rating,
            'facilities': rating,
            'value': rating,
            'location': rating,
          },
          'comment': comment,
        },
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        _logger.info('💬 Commentaire soumis avec succès');
        return true;
      } else {
        _logger.error('💬 Erreur lors de la soumission du commentaire: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.error('💬 Exception lors de la soumission du commentaire', e);
      return false;
    }
  }
}