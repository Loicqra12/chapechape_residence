import '../models/residence_model.dart';
import '../models/residence_type_enum.dart';
import 'api_service.dart';

class NearbyResidencesService {
  late final ApiService _apiService;
  
  NearbyResidencesService() {
    ApiService.initialize().then((service) {
      _apiService = service;
    });
  }
  
  // Constructeur avec injection d'une instance existante (utile pour les tests)
  NearbyResidencesService.withService(this._apiService);
  
  /// Récupère les résidences à proximité d'un point géographique
  /// [latitude] - Latitude du point central
  /// [longitude] - Longitude du point central
  /// [radius] - Rayon de recherche en kilomètres
  /// [limit] - Nombre maximum de résultats à retourner
  /// [categoryId] - ID de la catégorie pour filtrer (optionnel)
  /// [typeId] - ID du type de résidence pour filtrer (optionnel)
  Future<List<Residence>> getNearbyResidences({
    required double latitude,
    required double longitude,
    required double radius,
    int limit = 20,
    String? categoryId,
    String? typeId,
  }) async {
    try {
      // Construire l'URL avec les paramètres de requête
      final Map<String, dynamic> queryParams = {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'radius': radius.toString(),
        'limit': limit.toString(),
      };
      
      // Ajouter les paramètres optionnels s'ils sont présents
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['category'] = categoryId;
      }
      
      if (typeId != null && typeId.isNotEmpty) {
        queryParams['type'] = typeId;
      }
      
      // Appeler l'API
      final response = await _apiService.get(
        '/maps/nearby',
        queryParameters: queryParams,
      );
      
      // Vérifier le statut de la réponse
      if (response.statusCode == 200) {
        // Analyser la réponse JSON
        final data = response.data;
        
        if (data['success'] == true && data['data'] != null) {
          // Ajouter des logs pour déboguer la structure des données
          print('Structure de data["data"]: ${data['data'].runtimeType}');
          
          // Extraire les données de résidence en gérant les différents formats possibles
          List<dynamic> residencesData;
          
          if (data['data'] is List) {
            // Si c'est déjà une liste, l'utiliser directement
            residencesData = data['data'];
          } else if (data['data'] is Map) {
            // Si c'est un Map avec une propriété qui contient la liste
            // Essayer plusieurs clés possibles
            if (data['data']['residences'] is List) {
              residencesData = data['data']['residences'];
            } else if (data['data']['items'] is List) {
              residencesData = data['data']['items'];
            } else if (data['data']['results'] is List) {
              residencesData = data['data']['results'];
            } else {
              // Si on n'a pas trouvé de liste, créer une liste avec l'unique élément
              residencesData = [data['data']];
            }
          } else {
            // Fallback par défaut: liste vide
            print('Format de données inattendu: ${data['data']}');
            residencesData = [];
          }
          
          print('Résidences trouvées: ${residencesData.length}');
          
          // Convertir en liste d'objets Residence
          List<Residence> residences = [];
          for (var item in residencesData) {
            try {
              residences.add(_adaptBackendResidenceToClient(item));
            } catch (e) {
              print('Erreur lors de la conversion d\'une résidence: $e');
            }
          }
          
          return residences;
        } else {
          print('Erreur API: ${data['message']}');
          return [];
        }
      } else {
        print('Erreur API: ${response.statusCode} - ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      print('Exception pendant la recherche de résidences à proximité: $e');
      return [];
    }
  }
  
  /// Adapte la structure de résidence du backend vers la structure client
  /// Assure notamment que les coordonnées GPS sont bien des valeurs numériques
  Residence _adaptBackendResidenceToClient(Map<String, dynamic> backendResidence) {
    // Imprimer pour debug
    print('Conversion de la résidence: ${backendResidence['title']}');
    
    // Préparer les données essentielles
    String id = backendResidence['_id'] ?? '';
    String title = backendResidence['title'] ?? 'Sans titre';
    String description = backendResidence['description'] ?? '';
    double price = _extractNumericValue(backendResidence['price']) ?? 0.0;
    
    // Extraire les coordonnées GPS
    double? rawLat = _extractNumericValue(backendResidence['latitude']);
    double? rawLng = _extractNumericValue(backendResidence['longitude']);
    
    // Récupérer les images
    List<String> imagesList = [];
    if (backendResidence['images'] != null) {
      if (backendResidence['images'] is List) {
        imagesList = (backendResidence['images'] as List)
            .map((img) => img.toString())
            .toList();
      }
    }
    
    // Gérer l'adresse
    String address = backendResidence['address'] ?? '';
    String city = backendResidence['city'] ?? 'CO';
    String country = backendResidence['locationData'] != null && 
                   backendResidence['locationData']['country'] != null ? 
                   backendResidence['locationData']['country'] : 'CI';
    
    // Créer la map de location structurée
    Map<String, dynamic> location = {
      'address': address,
      'city': city,
      'country': country,
      'displayAddress': address,
      'coordinates': {
        'latitude': rawLat ?? 0.0,
        'longitude': rawLng ?? 0.0
      }
    };
    
    // Gérer les commodités
    List<String> amenities = [];
    if (backendResidence['amenities'] != null && backendResidence['amenities'] is List) {
      amenities = (backendResidence['amenities'] as List)
          .map((item) => item.toString())
          .toList();
    }
    
    // Extraire le nombre de chambres/salles de bain
    int bedrooms = (backendResidence['bedrooms'] ?? 1) as int;
    int bathrooms = (backendResidence['bathrooms'] ?? 1) as int;
    double area = _extractNumericValue(backendResidence['area']) ?? 0.0;
    
    // Déterminer le type de résidence
    String typeStr = (backendResidence['type'] ?? 'apartment').toString().toLowerCase();
    ResidenceType residenceType;
    try {
      residenceType = ResidenceType.values.firstWhere(
        (e) => e.toString().toLowerCase().contains(typeStr),
        orElse: () => ResidenceType.appartementMeuble
      );
    } catch (e) {
      // Fallback sur un type par défaut en cas d'erreur
      residenceType = ResidenceType.appartementMeuble;
    }
    
    // Calculer la distance
    double? distance = _extractNumericValue(backendResidence['distance']);
    
    // Créer un objet Residence complet avec les valeurs par défaut pour les champs manquants
    return Residence(
      id: id,
      title: title,
      description: description,
      shortDescription: description.length > 100 ? description.substring(0, 100) + '...' : description,
      images: imagesList,
      price: price,
      location: location,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      squareMeters: area,
      amenities: amenities,
      hasPool: amenities.contains('pool'),
      hasWifi: amenities.contains('wifi'),
      isVacationResidence: typeStr.contains('vacation'),
      isSpecialResidence: false,
      isAvailable: backendResidence['status'] == 'available',
      isFeatured: false,
      isPopular: false,
      isVerified: false,
      isNew: backendResidence['createdAt'] != null && 
             DateTime.tryParse(backendResidence['createdAt']) != null &&
             DateTime.now().difference(DateTime.parse(backendResidence['createdAt'])).inDays < 30,
      rating: _extractNumericValue(backendResidence['rating']?['overall']) ?? 0.0,
      reviewCount: backendResidence['rating']?['reviewCount'] as int? ?? 0,
      currency: 'XOF',
      type: residenceType,
      pricePeriod: backendResidence['pricePeriod'] ?? 'day',
      hourlyRate: _extractNumericValue(backendResidence['hourlyRates']?['oneHour']) ?? 0.0,
      halfDayRate: _extractNumericValue(backendResidence['dailyRates']?['halfDay']) ?? 0.0,
      fullDayRate: _extractNumericValue(backendResidence['dailyRates']?['fullDay']) ?? 0.0,
      weekendRate: _extractNumericValue(backendResidence['dailyRates']?['weekend']) ?? 0.0,
      isVip: false,
      priceDetails: {'distance': distance},
    );
  }
  
  /// Extrait une valeur numérique validée à partir d'un objet dynamique
  /// Retourne null si la conversion n'est pas possible
  double? _extractNumericValue(dynamic value) {
    if (value == null) {
      return null;
    }
    
    if (value is num) {
      return value.toDouble();
    }
    
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }
}
