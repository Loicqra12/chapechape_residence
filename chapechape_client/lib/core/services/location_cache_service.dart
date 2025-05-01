import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/city.dart';
import '../models/country.dart';
import '../models/region.dart';
import '../models/neighborhood.dart';

/// Service de cache pour les données de localisation
/// Implémente une stratégie de cache à plusieurs niveaux:
/// 1. Cache en mémoire (le plus rapide)
/// 2. Cache persistant avec SharedPreferences
class LocationCacheService {
  static LocationCacheService? _instance;
  
  // Clés du cache
  static const String _countriesKey = 'location_cache_countries';
  static const String _regionsKey = 'location_cache_regions';
  static const String _citiesKey = 'location_cache_cities';
  static const String _neighborhoodsKey = 'location_cache_neighborhoods';
  static const String _timestampKey = 'location_cache_timestamp';
  
  // Durée de validité du cache (en millisecondes) - 1 jour
  static const int _cacheDuration = 24 * 60 * 60 * 1000;
  
  // Cache en mémoire
  Map<String, List<dynamic>> _memoryCache = {};
  
  // Horodatage de la dernière mise à jour du cache
  DateTime? _lastCacheUpdate;
  
  // Singleton pattern
  factory LocationCacheService() {
    _instance ??= LocationCacheService._internal();
    return _instance!;
  }
  
  LocationCacheService._internal() {
    _initCache();
  }
  
  /// Initialiser le cache en chargeant les données depuis SharedPreferences
  Future<void> _initCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_timestampKey);
      
      if (timestamp != null) {
        _lastCacheUpdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
        
        // Vérifier si le cache est encore valide
        if (_isCacheValid()) {
          _loadFromPrefs(prefs);
        }
      }
    } catch (e) {
      print('Erreur lors de l\'initialisation du cache de localisation: $e');
    }
  }
  
  /// Vérifier si le cache est encore valide
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    
    final now = DateTime.now();
    final diff = now.difference(_lastCacheUpdate!).inMilliseconds;
    
    return diff < _cacheDuration;
  }
  
  /// Charger les données depuis SharedPreferences
  Future<void> _loadFromPrefs(SharedPreferences prefs) async {
    try {
      final countriesJson = prefs.getString(_countriesKey);
      final regionsJson = prefs.getString(_regionsKey);
      final citiesJson = prefs.getString(_citiesKey);
      final neighborhoodsJson = prefs.getString(_neighborhoodsKey);
      
      if (countriesJson != null) {
        final List<dynamic> decoded = jsonDecode(countriesJson);
        _memoryCache[_countriesKey] = decoded;
      }
      
      if (regionsJson != null) {
        final List<dynamic> decoded = jsonDecode(regionsJson);
        _memoryCache[_regionsKey] = decoded;
      }
      
      if (citiesJson != null) {
        final List<dynamic> decoded = jsonDecode(citiesJson);
        _memoryCache[_citiesKey] = decoded;
      }
      
      if (neighborhoodsJson != null) {
        final List<dynamic> decoded = jsonDecode(neighborhoodsJson);
        _memoryCache[_neighborhoodsKey] = decoded;
      }
    } catch (e) {
      print('Erreur lors du chargement des données du cache de localisation: $e');
    }
  }
  
  /// Sauvegarder les données dans SharedPreferences
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_memoryCache.containsKey(_countriesKey)) {
        await prefs.setString(_countriesKey, jsonEncode(_memoryCache[_countriesKey]));
      }
      
      if (_memoryCache.containsKey(_regionsKey)) {
        await prefs.setString(_regionsKey, jsonEncode(_memoryCache[_regionsKey]));
      }
      
      if (_memoryCache.containsKey(_citiesKey)) {
        await prefs.setString(_citiesKey, jsonEncode(_memoryCache[_citiesKey]));
      }
      
      if (_memoryCache.containsKey(_neighborhoodsKey)) {
        await prefs.setString(_neighborhoodsKey, jsonEncode(_memoryCache[_neighborhoodsKey]));
      }
      
      // Mettre à jour l'horodatage
      _lastCacheUpdate = DateTime.now();
      await prefs.setInt(_timestampKey, _lastCacheUpdate!.millisecondsSinceEpoch);
    } catch (e) {
      print('Erreur lors de la sauvegarde des données du cache de localisation: $e');
    }
  }
  
  /// Récupérer des données du cache
  Future<List<dynamic>?> get(String key) async {
    // Vérifier le cache en mémoire d'abord
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }
    
    // Si pas en mémoire, vérifier SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(key);
      
      if (data != null) {
        final decoded = jsonDecode(data) as List<dynamic>;
        _memoryCache[key] = decoded; // Mettre en cache pour les futurs accès
        return decoded;
      }
    } catch (e) {
      print('Erreur lors de la récupération des données du cache de localisation: $e');
    }
    
    return null;
  }
  
  /// Stocker des données dans le cache
  Future<void> set(String key, List<dynamic> data) async {
    // Mettre à jour le cache en mémoire
    _memoryCache[key] = data;
    
    // Mettre à jour SharedPreferences
    await _saveToPrefs();
  }
  
  /// Récupérer les pays du cache
  Future<List<Country>?> getCountries() async {
    final data = await get(_countriesKey);
    
    if (data != null) {
      return data.map((item) => Country.fromJson(item)).toList();
    }
    
    return null;
  }
  
  /// Stocker les pays dans le cache
  Future<void> setCountries(List<Country> countries) async {
    final data = countries.map((country) => country.toJson()).toList();
    await set(_countriesKey, data);
  }
  
  /// Récupérer les régions du cache
  Future<List<Region>?> getRegions() async {
    final data = await get(_regionsKey);
    
    if (data != null) {
      return data.map((item) => Region.fromJson(item)).toList();
    }
    
    return null;
  }
  
  /// Stocker les régions dans le cache
  Future<void> setRegions(List<Region> regions) async {
    final data = regions.map((region) => region.toJson()).toList();
    await set(_regionsKey, data);
  }
  
  /// Récupérer les villes du cache
  Future<List<City>?> getCities() async {
    final data = await get(_citiesKey);
    
    if (data != null) {
      return data.map((item) => City.fromJson(item)).toList();
    }
    
    return null;
  }
  
  /// Stocker les villes dans le cache
  Future<void> setCities(List<City> cities) async {
    final data = cities.map((city) => city.toJson()).toList();
    await set(_citiesKey, data);
  }
  
  /// Récupérer les quartiers du cache
  Future<List<Neighborhood>?> getNeighborhoods() async {
    final data = await get(_neighborhoodsKey);
    
    if (data != null) {
      return data.map((item) => Neighborhood.fromJson(item)).toList();
    }
    
    return null;
  }
  
  /// Stocker les quartiers dans le cache
  Future<void> setNeighborhoods(List<Neighborhood> neighborhoods) async {
    final data = neighborhoods.map((neighborhood) => neighborhood.toJson()).toList();
    await set(_neighborhoodsKey, data);
  }
  
  /// Invalider tout le cache
  Future<void> invalidateCache() async {
    _memoryCache.clear();
    _lastCacheUpdate = null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_countriesKey);
      await prefs.remove(_regionsKey);
      await prefs.remove(_citiesKey);
      await prefs.remove(_neighborhoodsKey);
      await prefs.remove(_timestampKey);
    } catch (e) {
      print('Erreur lors de l\'invalidation du cache de localisation: $e');
    }
  }
  
  /// Vérifier si les données dans le cache sont encore valides
  Future<bool> isValid() async {
    if (_lastCacheUpdate == null) return false;
    return _isCacheValid();
  }
  
  /// Obtenir des statistiques sur le cache
  Future<Map<String, dynamic>> getStats() async {
    final countriesCount = _memoryCache.containsKey(_countriesKey) ? _memoryCache[_countriesKey]?.length ?? 0 : 0;
    final regionsCount = _memoryCache.containsKey(_regionsKey) ? _memoryCache[_regionsKey]?.length ?? 0 : 0;
    final citiesCount = _memoryCache.containsKey(_citiesKey) ? _memoryCache[_citiesKey]?.length ?? 0 : 0;
    final neighborhoodsCount = _memoryCache.containsKey(_neighborhoodsKey) ? _memoryCache[_neighborhoodsKey]?.length ?? 0 : 0;
    
    return {
      'lastUpdate': _lastCacheUpdate?.toIso8601String() ?? 'Jamais',
      'isValid': _isCacheValid(),
      'counts': {
        'countries': countriesCount,
        'regions': regionsCount,
        'cities': citiesCount,
        'neighborhoods': neighborhoodsCount,
      },
      'memoryKeys': _memoryCache.keys.toList(),
    };
  }
}
