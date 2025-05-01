import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_suggestion_model.dart';
import '../models/city.dart';
import '../models/country.dart';
import '../models/region.dart';
import '../models/neighborhood.dart';
import 'map_provider/map_service_interface.dart';
import 'map_provider/osm_map_service.dart';
import 'location_cache_service.dart';

class LocationService {
  static LocationService? _instance;
  List<City> _cities = [];
  List<Country> _countries = [];
  List<Region> _regions = [];
  List<Neighborhood> _neighborhoods = [];
  
  // Service cartographique utilisé (peut être changé facilement)
  final MapServiceInterface _mapService = OSMMapService();
  
  // Service de cache
  final LocationCacheService _cacheService = LocationCacheService();
  
  // Indicateur de chargement des données
  bool _isLoading = false;
  Completer<bool>? _loadingCompleter;
  
  // Chemins des fichiers JSON
  static const String _countriesPath = 'assets/data/countries.json';
  static const String _regionsPath = 'assets/data/regions.json';
  static const String _citiesPath = 'assets/data/cities.json';
  static const String _neighborhoodsPath = 'assets/data/neighborhoods.json';
  
  // Singleton pattern
  factory LocationService() {
    _instance ??= LocationService._internal();
    return _instance!;
  }
  
  LocationService._internal() {
    // Charger les données
    _loadData();
  }
  
  /// Charge les données de localisation
  /// Priorité: 
  /// 1. Cache en mémoire
  /// 2. Cache persistant
  /// 3. Fichiers JSON dans assets
  Future<bool> _loadData() async {
    // Si le chargement est déjà en cours, attendre sa fin
    if (_isLoading) {
      return await _loadingCompleter!.future;
    }
    
    // Créer un nouveau completer
    _isLoading = true;
    _loadingCompleter = Completer<bool>();
    
    try {
      // Essayer de charger depuis le cache
      final bool cacheValid = await _cacheService.isValid();
      
      if (cacheValid) {
        final loadedFromCache = await _loadFromCache();
        if (loadedFromCache) {
          _isLoading = false;
          _loadingCompleter!.complete(true);
          return true;
        }
      }
      
      // Si le cache n'est pas valide, charger depuis les fichiers assets
      await _loadFromAssets();
      
      // Sauvegarder dans le cache
      await _saveToCache();
      
      _isLoading = false;
      _loadingCompleter!.complete(true);
      return true;
    } catch (e) {
      print('Erreur lors du chargement des données de localisation: $e');
      
      // En cas d'erreur, initialiser avec des données par défaut
      _initializeDefaultData();
      
      _isLoading = false;
      _loadingCompleter!.complete(false);
      return false;
    }
  }
  
  /// Charger les données depuis le cache
  Future<bool> _loadFromCache() async {
    try {
      // Charger les pays
      final countries = await _cacheService.getCountries();
      if (countries != null) {
        _countries = countries;
      } else {
        return false;
      }
      
      // Charger les régions
      final regions = await _cacheService.getRegions();
      if (regions != null) {
        _regions = regions;
      } else {
        return false;
      }
      
      // Charger les villes
      final cities = await _cacheService.getCities();
      if (cities != null) {
        _cities = cities;
      } else {
        return false;
      }
      
      // Charger les quartiers
      final neighborhoods = await _cacheService.getNeighborhoods();
      if (neighborhoods != null) {
        _neighborhoods = neighborhoods;
      } else {
        return false;
      }
      
      return true;
    } catch (e) {
      print('Erreur lors du chargement des données depuis le cache: $e');
      return false;
    }
  }
  
  /// Sauvegarder les données dans le cache
  Future<void> _saveToCache() async {
    await _cacheService.setCountries(_countries);
    await _cacheService.setRegions(_regions);
    await _cacheService.setCities(_cities);
    await _cacheService.setNeighborhoods(_neighborhoods);
  }
  
  /// Charger les données depuis les fichiers assets
  Future<void> _loadFromAssets() async {
    try {
      // Charger les pays
      final countriesString = await rootBundle.loadString(_countriesPath);
      final countriesJson = jsonDecode(countriesString) as List<dynamic>;
      _countries = countriesJson.map((json) => Country.fromJson(json)).toList();
      
      // Charger les régions
      final regionsString = await rootBundle.loadString(_regionsPath);
      final regionsJson = jsonDecode(regionsString) as List<dynamic>;
      _regions = regionsJson.map((json) => Region.fromJson(json)).toList();
      
      // Charger les villes
      final citiesString = await rootBundle.loadString(_citiesPath);
      final citiesJson = jsonDecode(citiesString) as List<dynamic>;
      _cities = citiesJson.map((json) => City.fromJson(json)).toList();
      
      // S'assurer que le drapeau isPopular est bien défini
      for (var city in _cities) {
        // Vérifier si isPopular est null, et le définir à false par défaut
        if (city.isPopular == null) {
          city = city.copyWith(isPopular: false);
        }
      }
      
      // Charger les quartiers
      final neighborhoodsString = await rootBundle.loadString(_neighborhoodsPath);
      final neighborhoodsJson = jsonDecode(neighborhoodsString) as List<dynamic>;
      _neighborhoods = neighborhoodsJson.map((json) => Neighborhood.fromJson(json)).toList();
    } catch (e) {
      print('Erreur lors du chargement des données depuis les assets: $e');
      throw e;
    }
  }
  
  // Initialiser avec des données par défaut
  void _initializeDefaultData() {
    // Pays par défaut
    _countries = [
      Country(code: 'ci', name: 'Côte d\'Ivoire', phoneCode: '+225', capital: 'Yamoussoukro'),
      Country(code: 'sn', name: 'Sénégal', phoneCode: '+221', capital: 'Dakar'),
      Country(code: 'gh', name: 'Ghana', phoneCode: '+233', capital: 'Accra'),
      Country(code: 'ng', name: 'Nigeria', phoneCode: '+234', capital: 'Abuja'),
    ];
    
    // Quelques régions par défaut pour la Côte d'Ivoire
    _regions = [
      Region(id: 'lagunes', name: 'Lagunes', countryCode: 'ci', mainCity: 'Abidjan'),
      Region(id: 'lacs', name: 'Lacs', countryCode: 'ci', mainCity: 'Yamoussoukro'),
      Region(id: 'gbeke', name: 'Gbêkê', countryCode: 'ci', mainCity: 'Bouaké'),
      Region(id: 'san_pedro', name: 'San-Pédro', countryCode: 'ci', mainCity: 'San Pedro'),
    ];
    
    // Villes par défaut
    _cities = [
      City(
        id: 'abidjan',
        name: 'Abidjan',
        region: 'Lagunes',
        regionId: 'lagunes',
        countryCode: 'ci',
        latitude: 5.3599517,
        longitude: -4.0082563,
        isPopular: true,
      ),
      City(
        id: 'yamoussoukro',
        name: 'Yamoussoukro',
        region: 'Lacs',
        regionId: 'lacs',
        countryCode: 'ci',
        latitude: 6.8276228,
        longitude: -5.2893433,
        isPopular: true,
      ),
      City(
        id: 'bouake',
        name: 'Bouaké',
        region: 'Gbêkê',
        regionId: 'gbeke',
        countryCode: 'ci',
        latitude: 7.6898864,
        longitude: -5.0364485,
        isPopular: true,
      ),
      City(
        id: 'san_pedro',
        name: 'San Pedro',
        region: 'San-Pédro',
        regionId: 'san_pedro',
        countryCode: 'ci',
        latitude: 4.7456134,
        longitude: -6.6391225,
        isPopular: true,
      ),
    ];
    
    // Quartiers par défaut
    _neighborhoods = [
      Neighborhood(
        id: 'cocody',
        name: 'Cocody',
        cityId: 'abidjan',
        countryCode: 'ci',
        latitude: 5.3641352,
        longitude: -3.9673475,
        isPopular: true,
      ),
      Neighborhood(
        id: 'marcory',
        name: 'Marcory',
        cityId: 'abidjan',
        countryCode: 'ci',
        latitude: 5.3020198,
        longitude: -3.9784288,
        isPopular: true,
      ),
      Neighborhood(
        id: 'plateau',
        name: 'Plateau',
        cityId: 'abidjan',
        countryCode: 'ci',
        latitude: 5.3220556,
        longitude: -4.0168485,
        isPopular: true,
      ),
    ];
  }
  
  /// Retourne tous les pays disponibles
  List<Country> getCountries() {
    return _countries;
  }
  
  /// Obtenir un pays par son code
  Country? getCountryByCode(String code) {
    try {
      return _countries.firstWhere(
        (country) => country.code.toLowerCase() == code.toLowerCase()
      );
    } catch (e) {
      return null;
    }
  }
  
  // Obtenir toutes les régions d'un pays
  List<Region> getRegionsByCountry(String countryCode) {
    return _regions.where((region) => 
      region.countryCode.toLowerCase() == countryCode.toLowerCase()
    ).toList();
  }
  
  // Méthode de compatibilité pour l'ancien code - retourne les noms des régions
  List<String> getRegionNamesByCountry(String countryCode) {
    final regions = getRegionsByCountry(countryCode);
    return regions.map((region) => region.name).toList();
  }
  
  // Obtenir une région par son ID
  Region? getRegionById(String regionId, String countryCode) {
    try {
      return _regions.firstWhere((region) => 
        region.id.toLowerCase() == regionId.toLowerCase() && 
        region.countryCode.toLowerCase() == countryCode.toLowerCase()
      );
    } catch (e) {
      return null;
    }
  }
  
  // Obtenir toutes les villes d'un pays
  List<City> getCitiesByCountry(String countryCode) {
    return _cities.where((city) => city.countryCode.toLowerCase() == countryCode.toLowerCase()).toList();
  }
  
  // Obtenir les villes populaires d'un pays
  List<City> getPopularCitiesByCountry(String countryCode) {
    List<City> result = [];
    
    try {
      // Filtrer les villes populaires du pays spécifié
      result = _cities.where(
        (city) => 
          city.countryCode.toLowerCase() == countryCode.toLowerCase() && 
          city.isPopular == true
      ).toList();
      
      // Si aucune ville populaire n'est trouvée, retourner les 5 premières villes du pays
      if (result.isEmpty) {
        print('Aucune ville populaire trouvée pour le pays $countryCode');
        return getCitiesByCountry(countryCode).take(5).toList();
      }
    } catch (e) {
      print('Erreur lors de la récupération des villes populaires: $e');
    }
    
    return result;
  }
  
  // Obtenir les villes d'une région
  List<City> getCitiesByRegion(String countryCode, String region) {
    return _cities.where(
      (city) => city.countryCode.toLowerCase() == countryCode.toLowerCase() && 
                (city.regionId != null && city.regionId!.toLowerCase() == region.toLowerCase())
    ).toList();
  }
  
  // Obtenir une ville par son ID
  City? getCityById(String cityId) {
    try {
      return _cities.firstWhere((city) => city.id.toLowerCase() == cityId.toLowerCase());
    } catch (e) {
      return null;
    }
  }
  
  // Rechercher des villes par nom
  List<City> searchCitiesByName(String query, {String? countryCode, String? region}) {
    List<City> filteredCities = _cities;
    
    if (countryCode != null) {
      filteredCities = filteredCities.where((city) => 
        city.countryCode.toLowerCase() == countryCode.toLowerCase()
      ).toList();
    }
    
    if (region != null) {
      filteredCities = filteredCities.where((city) => 
        city.regionId != null && city.regionId!.toLowerCase() == region.toLowerCase()
      ).toList();
    }
    
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      filteredCities = filteredCities.where((city) => 
        city.name.toLowerCase().contains(lowerQuery)
      ).toList();
    }
    
    return filteredCities;
  }
  
  // Méthode de compatibilité pour l'ancien nom
  List<City> searchCities(String query, {String? countryCode, String? region}) {
    return searchCitiesByName(query, countryCode: countryCode, region: region);
  }
  
  // Obtenir tous les quartiers d'une ville
  List<Neighborhood> getNeighborhoodsByCity(String cityId) {
    return _neighborhoods.where((neighborhood) => 
      neighborhood.cityId.toLowerCase() == cityId.toLowerCase()
    ).toList();
  }
  
  // Obtenir les quartiers populaires d'une ville
  List<Neighborhood> getPopularNeighborhoodsByCity(String cityId) {
    return _neighborhoods.where((neighborhood) => 
      neighborhood.cityId.toLowerCase() == cityId.toLowerCase() && 
      neighborhood.isPopular
    ).toList();
  }
  
  // Méthode de compatibilité - retourne les noms des quartiers par ID de ville
  List<String> getNeighborhoodNamesByCity(String cityId) {
    final neighborhoods = getNeighborhoodsByCity(cityId);
    return neighborhoods.map((n) => n.name).toList();
  }
  
  // Méthode de compatibilité - retourne les noms des quartiers populaires par ID de ville
  List<String> getPopularNeighborhoodNamesByCity(String cityId) {
    final neighborhoods = getPopularNeighborhoodsByCity(cityId);
    return neighborhoods.map((n) => n.name).toList();
  }
  
  // Obtenir un quartier par son ID
  Neighborhood? getNeighborhoodById(String neighborhoodId) {
    try {
      return _neighborhoods.firstWhere((neighborhood) => 
        neighborhood.id.toLowerCase() == neighborhoodId.toLowerCase()
      );
    } catch (e) {
      return null;
    }
  }
  
  // Rechercher des quartiers par nom
  List<Neighborhood> searchNeighborhoods(String query, {String? cityId}) {
    final normalizedQuery = query.toLowerCase();
    var filteredNeighborhoods = _neighborhoods.where((neighborhood) => 
      neighborhood.name.toLowerCase().contains(normalizedQuery)
    ).toList();
    
    if (cityId != null) {
      filteredNeighborhoods = filteredNeighborhoods.where((neighborhood) => 
        neighborhood.cityId.toLowerCase() == cityId.toLowerCase()
      ).toList();
    }
    
    return filteredNeighborhoods;
  }
  
  /// Recherche par niveau (country, region, city, neighborhood)
  List<dynamic> searchByLevel(String query, String level, {String? parentId}) {
    switch (level) {
      case 'country':
        return _countries.where((country) => 
          country.name.toLowerCase().contains(query.toLowerCase())
        ).toList();
      case 'region':
        if (parentId != null) {
          return getRegionsByCountry(parentId).where((region) => 
            region.name.toLowerCase().contains(query.toLowerCase())
          ).toList();
        }
        return [];
      case 'city':
        if (parentId != null) {
          if (parentId.contains('region_')) {
            // parentId est une région
            final regionId = parentId.replaceFirst('region_', '');
            final region = getRegionById(regionId, '');
            return getCitiesByRegion(region?.countryCode ?? '', region?.id ?? '')
                   .where((city) => city.name.toLowerCase().contains(query.toLowerCase()))
                   .toList();
          } else {
            // parentId est un pays
            return getCitiesByCountry(parentId)
                   .where((city) => city.name.toLowerCase().contains(query.toLowerCase()))
                   .toList();
          }
        }
        return [];
      case 'neighborhood':
        if (parentId != null) {
          return getNeighborhoodsByCity(parentId)
                 .where((neighborhood) => neighborhood.name.toLowerCase().contains(query.toLowerCase()))
                 .toList();
        }
        return [];
      default:
        return [];
    }
  }
  
  // Simuler une API de suggestions de localisation
  Future<List<LocationSuggestionModel>> getSuggestions(String query) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (query.isEmpty) {
      return [];
    }
    
    // Suggestions fictives pour la démonstration
    final suggestions = [
      LocationSuggestionModel(
        id: '1',
        name: 'Cocody',
        fullAddress: 'Cocody, Abidjan, Côte d\'Ivoire',
        city: 'Abidjan',
        district: 'Cocody',
        country: 'Côte d\'Ivoire',
        latitude: 5.3601,
        longitude: -4.0083,
        isPopular: true,
        searchCount: 1250,
      ),
      LocationSuggestionModel(
        id: '2',
        name: 'Plateau',
        fullAddress: 'Plateau, Abidjan, Côte d\'Ivoire',
        city: 'Abidjan',
        district: 'Plateau',
        country: 'Côte d\'Ivoire',
        latitude: 5.3234,
        longitude: -4.0168,
        isPopular: true,
        searchCount: 980,
      ),
      LocationSuggestionModel(
        id: '3',
        name: 'Marcory',
        fullAddress: 'Marcory, Abidjan, Côte d\'Ivoire',
        city: 'Abidjan',
        district: 'Marcory',
        country: 'Côte d\'Ivoire',
        latitude: 5.3019,
        longitude: -3.9826,
        isPopular: true,
        searchCount: 850,
      ),
      LocationSuggestionModel(
        id: '4',
        name: 'Bietry',
        fullAddress: 'Bietry, Zone 4, Abidjan, Côte d\'Ivoire',
        city: 'Abidjan',
        district: 'Zone 4',
        country: 'Côte d\'Ivoire',
        latitude: 5.2910,
        longitude: -3.9734,
        isPopular: false,
        searchCount: 420,
      ),
      LocationSuggestionModel(
        id: '5',
        name: 'Riviera',
        fullAddress: 'Riviera, Cocody, Abidjan, Côte d\'Ivoire',
        city: 'Abidjan',
        district: 'Cocody',
        country: 'Côte d\'Ivoire',
        latitude: 5.3782,
        longitude: -3.9534,
        isPopular: true,
        searchCount: 1100,
      ),
    ];
    
    // Filtrer les suggestions en fonction de la requête
    return suggestions
        .where((suggestion) => 
            suggestion.name.toLowerCase().contains(query.toLowerCase()) ||
            suggestion.fullAddress.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
  
  // Obtenir les localisations populaires
  Future<List<LocationSuggestionModel>> getPopularLocations() async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Suggestions fictives pour la démonstration
    final suggestions = [
      LocationSuggestionModel(
        id: '1',
        name: 'Cocody',
        fullAddress: 'Cocody, Abidjan, Côte d\'Ivoire',
        city: 'Abidjan',
        district: 'Cocody',
        country: 'Côte d\'Ivoire',
        latitude: 5.3601,
        longitude: -4.0083,
        isPopular: true,
        searchCount: 1250,
      ),
      LocationSuggestionModel(
        id: '2',
        name: 'Plateau',
        fullAddress: 'Plateau, Abidjan, Côte d\'Ivoire',
        city: 'Abidjan',
        district: 'Plateau',
        country: 'Côte d\'Ivoire',
        latitude: 5.3234,
        longitude: -4.0168,
        isPopular: true,
        searchCount: 980,
      ),
      LocationSuggestionModel(
        id: '5',
        name: 'Riviera',
        fullAddress: 'Riviera, Cocody, Abidjan, Côte d\'Ivoire',
        city: 'Abidjan',
        district: 'Cocody',
        country: 'Côte d\'Ivoire',
        latitude: 5.3782,
        longitude: -3.9534,
        isPopular: true,
        searchCount: 1100,
      ),
    ];
    
    return suggestions;
  }
  
  // Simuler l'obtention de la position actuelle de l'utilisateur
  // Note: Normalement, cela utiliserait geolocator, mais nous simulons ici
  Future<LatLng?> getCurrentUserLocation() async {
    // Utiliser le service cartographique pour obtenir la position
    final position = await _mapService.getCurrentLocation();
    
    if (position != null) {
      return LatLng(position['latitude']!, position['longitude']!);
    }
    
    return null;
  }
  
  // Obtenir l'autorisation de localisation
  Future<bool> requestLocationPermission() async {
    // Utiliser le service cartographique pour demander l'autorisation
    return _mapService.requestLocationPermission();
  }
  
  // Calculer la distance entre deux points en kilomètres (formule de Haversine)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Utiliser le service cartographique pour calculer la distance
    return _mapService.calculateDistance(lat1, lon1, lat2, lon2);
  }
  
  // Obtenir les résidences à proximité de la position de l'utilisateur
  Future<List<LocationSuggestionModel>> getNearbyLocations(LatLng userLocation, {double radiusKm = 5.0}) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Liste complète des emplacements disponibles
    final allLocations = await getAllLocations();
    
    // Filtrer pour ne conserver que les emplacements dans le rayon spécifié
    final nearbyLocations = allLocations.where((location) {
      final distance = calculateDistance(
        userLocation.latitude, 
        userLocation.longitude,
        location.latitude ?? 0.0,
        location.longitude ?? 0.0
      );
      
      return distance <= radiusKm;
    }).toList();
    
    // Trier par distance
    nearbyLocations.sort((a, b) {
      final distanceA = calculateDistance(
        userLocation.latitude, 
        userLocation.longitude,
        a.latitude ?? 0.0,
        a.longitude ?? 0.0
      );
      
      final distanceB = calculateDistance(
        userLocation.latitude, 
        userLocation.longitude,
        b.latitude ?? 0.0,
        b.longitude ?? 0.0
      );
      
      return distanceA.compareTo(distanceB);
    });
    
    return nearbyLocations;
  }
  
  // Obtenir tous les emplacements disponibles
  Future<List<LocationSuggestionModel>> getAllLocations() async {
    // Combiner toutes les sources d'emplacements
    final List<LocationSuggestionModel> allLocations = [];
    
    // Ajouter les emplacements populaires
    allLocations.addAll(await getPopularLocations());
    
    // Ajouter des emplacements supplémentaires
    allLocations.addAll([
      LocationSuggestionModel(
        id: '3',
        name: 'Marcory',
        fullAddress: 'Marcory, Abidjan, Côte d\'Ivoire',
        city: 'Abidjan',
        district: 'Marcory',
        country: 'Côte d\'Ivoire',
        latitude: 5.3019,
        longitude: -3.9826,
        isPopular: true,
        searchCount: 850,
      ),
      LocationSuggestionModel(
        id: '4',
        name: 'Bietry',
        fullAddress: 'Bietry, Zone 4, Abidjan, Côte d\'Ivoire',
        city: 'Abidjan',
        district: 'Zone 4',
        country: 'Côte d\'Ivoire',
        latitude: 5.2910,
        longitude: -3.9734,
        isPopular: false,
        searchCount: 420,
      ),
      LocationSuggestionModel(
        id: '6',
        name: 'Yopougon',
        fullAddress: 'Yopougon, Abidjan, Côte d\'Ivoire',
        city: 'Abidjan',
        district: 'Yopougon',
        country: 'Côte d\'Ivoire',
        latitude: 5.3364,
        longitude: -4.0674,
        isPopular: false,
        searchCount: 780,
      ),
      LocationSuggestionModel(
        id: '7',
        name: 'Treichville',
        fullAddress: 'Treichville, Abidjan, Côte d\'Ivoire',
        city: 'Abidjan',
        district: 'Treichville',
        country: 'Côte d\'Ivoire',
        latitude: 5.2950,
        longitude: -4.0200,
        isPopular: false,
        searchCount: 650,
      ),
      LocationSuggestionModel(
        id: '8',
        name: 'Angré',
        fullAddress: 'Angré, Cocody, Abidjan, Côte d\'Ivoire',
        city: 'Abidjan',
        district: 'Cocody',
        country: 'Côte d\'Ivoire',
        latitude: 5.3839,
        longitude: -3.9980,
        isPopular: false,
        searchCount: 920,
      ),
    ]);
    
    return allLocations;
  }
}
