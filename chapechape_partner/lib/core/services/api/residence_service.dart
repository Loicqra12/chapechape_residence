import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/residence/residence.dart';
import '../../models/residence/residence_image.dart';
import '../../exceptions/api_exception.dart';

class ResidenceService {
  final String baseUrl;
  final http.Client client;
  final FlutterSecureStorage storage;

  ResidenceService({
    required this.baseUrl,
    http.Client? client,
    FlutterSecureStorage? storage,
  }) : client = client ?? http.Client(),
       storage = storage ?? const FlutterSecureStorage();

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
        Uri.parse('$baseUrl/residences'),
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
        Uri.parse('$baseUrl/residences').replace(queryParameters: filters),
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

  Future<Residence> getResidenceById(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await client.get(
        Uri.parse('$baseUrl/residences/$id'),
        headers: headers,
      );

      return _handleResponse<Residence>(
        response,
        (data) {
          if (data is Map<String, dynamic> && data.containsKey('data')) {
            var residenceData = data['data'];
            if (residenceData is Map<String, dynamic>) {
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
        partnerInfo: json['partner'] is Map 
            ? {
                'id': json['partner']['_id']?.toString() ?? '',
                'name': json['partner']['name']?.toString() ?? '',
                'email': json['partner']['email']?.toString() ?? '',
              }
            : null,
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
    // Identifier le type backend basé sur le type frontend
    String backendType = _mapFrontendTypeToBackendType(data['type'] ?? 'studio_meuble');
    
    // Déterminer la période de tarification basée sur le type de résidence
    String pricePeriod = data['pricePeriod'] ?? 'month';
    
    // Pour certains types spécifiques, forcer la période de tarification
    if (data['type'] == 'hotel_passage' || data['type'] == 'motel') {
      pricePeriod = 'hour';
    } else if (data['type'] == 'studio_meuble' || data['type'] == 'guest_house') {
      pricePeriod = 'day';
    }
    
    // Convertir tous les champs numériques en double ou int
    double price = double.tryParse(data['price'].toString()) ?? 0.0;
    int bedrooms = int.tryParse(data['bedrooms'].toString()) ?? 0;
    int bathrooms = int.tryParse(data['bathrooms'].toString()) ?? 0;
    double surface = double.tryParse(data['surface'].toString()) ?? 0.0;
    double hourlyRate = double.tryParse(data['hourlyRate']?.toString() ?? '0') ?? 0.0;
    double halfDayRate = double.tryParse(data['halfDayRate']?.toString() ?? '0') ?? 0.0;
    double fullDayRate = double.tryParse(data['fullDayRate']?.toString() ?? '0') ?? 0.0;
    double weekendRate = double.tryParse(data['weekendRate']?.toString() ?? '0') ?? 0.0;
    double latitude = double.tryParse(data['latitude']?.toString() ?? '0') ?? 0.0;
    double longitude = double.tryParse(data['longitude']?.toString() ?? '0') ?? 0.0;
    
    return {
      'title': data['name'],
      'description': data['description'],
      'price': price,
      'pricePeriod': pricePeriod,
      'hourlyRates': {
        'oneHour': hourlyRate,
        'twoHours': hourlyRate * 1.8,
        'threeHours': hourlyRate * 2.7,
        'additionalHour': hourlyRate * 0.8,
      },
      'dailyRates': {
        'halfDay': halfDayRate,
        'fullDay': fullDayRate,
        'weekend': weekendRate,
      },
      'type': backendType,
      'address': data['address'],
      'city': data['city'],
      'bedrooms': data['type'].toString().contains('studio') ? 0 : bedrooms,
      'bathrooms': bathrooms,
      'area': surface,
      'latitude': latitude,
      'longitude': longitude,
      'amenities': data['amenities'] ?? [],
      'rules': data['rules'] ?? [],
      'hasPool': data['hasPool'] ?? false,
      'isVacationResidence': data['isVacationResidence'] ?? false,
      'isSpecialResidence': data['isSpecialResidence'] ?? false,
      'status': data['isAvailable'] == true ? 'available' : 'unavailable',
    };
  }

  String _mapFrontendTypeToBackendType(String frontendType) {
    final Map<String, String> typeMapping = {
      // Résidences meublées
      'studio_meuble': 'studio',
      'appartement_meuble': 'apartment',
      'villa_meublee': 'villa',
      'penthouse': 'apartment',
      'loft': 'apartment',
      
      // Hôtels
      'hotel_passage': 'apartment',
      'motel': 'apartment',
      'boutique_hotel': 'apartment',
      'hotel_luxe': 'apartment',
      'guest_house': 'house',
      
      // Hébergements insolites
      'bungalow': 'house',
      'lodge': 'house',
      'case_traditionnelle': 'house',
      'maison_flottante': 'house',
      
      // Colocation
      'chambre_colocation': 'apartment',
      'coliving': 'apartment',
      'maison_hotes': 'house',
      
      // Résidences longue durée
      'appartement_vide': 'apartment',
      'villa_vide': 'villa',
      'immeuble': 'apartment',
    };
  
    return typeMapping[frontendType] ?? 'apartment';
  }

  Future<Residence> createResidence(Map<String, dynamic> data, List<ResidenceImage> images) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        throw ApiException(
          'Vous n\'êtes pas connecté. Veuillez vous connecter pour continuer.',
          401,
          {'error': 'auth_required'}
        );
      }
      
      // Adapter les données au format du backend
      final adaptedData = _adaptFrontendResidenceToBackend(data);
      
      // Débogage - afficher les données adaptées
      print('Données adaptées: $adaptedData');
      
      // Si aucune image n'est fournie, utiliser une simple requête POST
      if (images.isEmpty) {
        final headers = await _getAuthHeaders();
        headers['Content-Type'] = 'application/json';
        
        final response = await http.post(
          Uri.parse('$baseUrl/residences'),
          headers: headers,
          body: json.encode(adaptedData),
        );
        
        return _handleResponse<Residence>(
          response,
          (data) {
            if (data is Map<String, dynamic> && data.containsKey('data')) {
              var residenceData = data['data'];
              if (residenceData is Map<String, dynamic>) {
                return _adaptBackendResidenceToFrontend(residenceData);
              }
            }
            throw ApiException(
              'Format de données inattendu pour la résidence créée',
              500,
              {'error': 'unexpected_data_format'}
            );
          }
        );
      }
      
      // Sinon, utiliser une requête multipart
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/residences'));
      
      // Ajouter le token d'authentification
      request.headers['Authorization'] = 'Bearer $token';
      
      // Convertir l'objet adaptedData en un format plat pour la requête multipart
      // Au lieu d'utiliser des notations complexes, convertir tout en JSON et envoyer comme un champ unique
      request.fields['residenceData'] = json.encode(adaptedData);
      
      // Ajouter les images
      int imageIndex = 0;
      for (var image in images) {
        if (image.file != null) {
          try {
            final imageBytes = await image.file!.readAsBytes();
            final filename = image.file!.path.split('/').last;
            
            final multipartFile = http.MultipartFile.fromBytes(
              'images',  // Nom du champ, doit correspondre à ce que le backend attend
              imageBytes,
              filename: filename,
              contentType: MediaType('image', _getImageMimeType(filename)),
            );
            
            request.files.add(multipartFile);
            imageIndex++;
          } catch (e) {
            print("Erreur lors de la lecture de l'image: $e");
          }
        } else if (image.isWeb) {
          // Si c'est une image web, l'envoyer comme données binaires
          request.files.add(
            http.MultipartFile.fromBytes(
              'images',
              image.webImage!,
              filename: 'image_$imageIndex.jpg',
              contentType: MediaType('image', 'jpeg'),
            ),
          );
          imageIndex++;
        }
      }
      
      try {
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        
        return _handleResponse<Residence>(
          response,
          (data) {
            if (data is Map<String, dynamic> && data.containsKey('data')) {
              var residenceData = data['data'];
              if (residenceData is Map<String, dynamic>) {
                return _adaptBackendResidenceToFrontend(residenceData);
              }
            }
            throw ApiException(
              'Format de données inattendu pour la résidence créée',
              500,
              {'error': 'unexpected_data_format'}
            );
          }
        );
      } catch (e) {
        print("Erreur lors de l'envoi de la requête: $e");
        throw ApiException(
          "Une erreur est survenue lors de la création de la résidence: $e",
          500,
          {'error': 'request_failed'}
        );
      }
    } on SocketException {
      throw ApiException(
        'Pas de connexion Internet. Veuillez vérifier votre connexion et réessayer.',
        0,
        {'error': 'network_error'}
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      
      throw ApiException(
        'Échec de la création de la résidence: $e',
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

  Future<void> updateResidence(String id, Map<String, dynamic> data) async {
    try {
      final headers = await _getAuthHeaders();
      
      final residenceData = _adaptFrontendResidenceToBackend(data);
      print('Données adaptées pour le backend : $residenceData');
      
      final response = await client.put(
        Uri.parse('$baseUrl/residences/$id'),
        headers: headers,
        body: json.encode(residenceData),
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
      if (e is ApiException) {
        if (e.statusCode == 403) {
          throw ApiException(
            'Vous n\'êtes pas autorisé à modifier cette résidence. Seul le propriétaire ou un administrateur peut la modifier.',
            403,
            {'error': 'forbidden', 'details': 'residence_ownership_required'}
          );
        }
        rethrow;
      }
      
      throw ApiException(
        'Échec de la mise à jour de la résidence: $e',
        500,
        {'error': e.toString()}
      );
    }
  }

  Future<void> uploadResidenceImages(String residenceId, List<ResidenceImage> images) async {
    try {
      final token = await storage.read(key: 'token');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/residences/$residenceId/images'),
      );

      // Ajouter tous les headers nécessaires
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'contentType': 'application/json',
        'responseType': 'ResponseType.json',
        'followRedirects': 'true',
        'connectTimeout': '0:00:30.000000',
        'receiveTimeout': '0:00:30.000000',
      });

      for (var i = 0; i < images.length; i++) {
        final image = images[i];
        if (image.file != null) {
          try {
            final imageBytes = await image.file!.readAsBytes();
            final filename = image.file!.path.split('/').last;
            
            final multipartFile = http.MultipartFile.fromBytes(
              'images',  // Nom du champ, doit correspondre à ce que le backend attend
              imageBytes,
              filename: filename,
              contentType: MediaType('image', _getImageMimeType(filename)),
            );
            
            request.files.add(multipartFile);
          } catch (e) {
            print("Erreur lors de la lecture de l'image: $e");
          }
        } else if (image.isWeb) {
          // Si c'est une image web, l'envoyer comme données binaires
          request.files.add(
            http.MultipartFile.fromBytes(
              'images',
              image.webImage!,
              filename: 'image_$i.jpg',
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
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
        'Échec de l\'envoi des images: $e',
        500,
        {'error': e.toString()}
      );
    }
  }

  Future<void> deleteResidence(String id) async {
    try {
      final headers = await _getAuthHeaders();
      
      final response = await client.delete(
        Uri.parse('$baseUrl/residences/$id'),
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
      if (e is ApiException) {
        if (e.statusCode == 403) {
          throw ApiException(
            'Vous n\'êtes pas autorisé à supprimer cette résidence. Seul le propriétaire ou un administrateur peut la supprimer.',
            403,
            {'error': 'forbidden', 'details': 'residence_ownership_required'}
          );
        } else if (e.statusCode == 404) {
          throw ApiException(
            'La résidence que vous essayez de supprimer n\'existe pas ou a déjà été supprimée.',
            404,
            {'error': 'not_found', 'details': 'residence_not_found'}
          );
        }
        rethrow;
      }
      
      throw ApiException(
        'Échec de la suppression de la résidence: $e',
        500,
        {'error': e.toString()}
      );
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
      final headers = await _getAuthHeaders();
      final response = await client.get(
        Uri.parse('$baseUrl/residences/partner'),
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
    if (json['images'] == null) return [];
    
    if (json['images'] is List) {
      return List<String>.from(
        (json['images'] as List).map((img) {
          if (img is String) {
            return img;
          } else if (img is Map && img['url'] != null) {
            return img['url'].toString();
          }
          return '';
        }).where((url) => url.isNotEmpty)
      );
    }
    
    return [];
  }
}
