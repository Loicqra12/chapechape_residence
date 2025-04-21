import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Structure pour stocker une entrée de cache avec sa date d'expiration
class CacheEntry {
  final dynamic data;
  final DateTime expiryTime;

  CacheEntry({required this.data, required this.expiryTime});

  bool get isExpired => DateTime.now().isAfter(expiryTime);

  Map<String, dynamic> toJson() => {
    'data': data,
    'expiryTime': expiryTime.toIso8601String(),
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      data: json['data'],
      expiryTime: DateTime.parse(json['expiryTime']),
    );
  }
}

/// Service de mise en cache des réponses API pour améliorer la performance
/// et la résilience aux problèmes de connectivité.
class CacheService {
  static SharedPreferences? _prefs;
  static const String _cachePrefix = 'api_cache_';
  static const String _timestampPrefix = 'api_timestamp_';
  static const String _authTokenKey = 'auth_token';
  
  static CacheService? _instance;

  /// Obtenir l'instance singleton de CacheService
  static CacheService getInstance() {
    _instance ??= CacheService();
    return _instance!;
  }
  
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Vérifie si le service est initialisé
  bool get isInitialized => _prefs != null;

  /// Initialise le service si ce n'est pas déjà fait
  Future<void> ensureInitialized() async {
    if (_prefs == null) {
      await initialize();
    }
  }

  /// Vérifie si l'utilisateur est authentifié
  Future<bool> isAuthenticated() async {
    await ensureInitialized();
    if (_prefs == null) return false;
    
    final token = _prefs!.getString(_authTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Enregistre une réponse en cache
  Future<bool> put(String key, dynamic data, {int? expiryInMinutes}) async {
    await ensureInitialized();
    if (_prefs == null) return false;
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final jsonData = json.encode(data);
    
    await _prefs!.setString('$_cachePrefix$key', jsonData);
    await _prefs!.setInt('$_timestampPrefix$key', timestamp);
    
    if (expiryInMinutes != null) {
      await _prefs!.setInt('${_timestampPrefix}expiry_$key', expiryInMinutes);
    }
    
    return true;
  }

  /// Récupère une réponse du cache
  Future<dynamic> get(String key, {bool checkExpiry = true}) async {
    await ensureInitialized();
    if (_prefs == null) return null;
    
    final jsonData = _prefs!.getString('$_cachePrefix$key');
    if (jsonData == null) return null;
    
    if (checkExpiry && await isExpired(key)) {
      return null;
    }
    
    return json.decode(jsonData);
  }

  /// Pour compatibilité avec l'ancienne API
  Future<T> getWithFetcher<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration? duration,
    bool forceRefresh = false,
  }) async {
    await ensureInitialized();
    
    // Utiliser l'API simple pour vérifier si on a une valeur en cache
    final cachedData = await get(key);
    
    // Si on a des données en cache et qu'on ne force pas le refresh
    if (cachedData != null && !forceRefresh) {
      return cachedData as T;
    }
    
    // Sinon, on récupère les données via le fetcher
      final data = await fetcher();
      
    // On met en cache avec la durée spécifiée
    int? expiryInMinutes;
    if (duration != null) {
      expiryInMinutes = duration.inMinutes;
    }
    
    await put(key, data, expiryInMinutes: expiryInMinutes);
      
      return data;
  }

  /// Vérifie si une entrée de cache a expiré
  Future<bool> isExpired(String key) async {
    await ensureInitialized();
    if (_prefs == null) return true;
    
    final timestamp = _prefs!.getInt('$_timestampPrefix$key');
    final expiryMinutes = _prefs!.getInt('${_timestampPrefix}expiry_$key');
    
    if (timestamp == null || expiryMinutes == null) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiryTime = timestamp + (expiryMinutes * 60 * 1000);
    
    return now > expiryTime;
  }

  /// Supprime une entrée du cache
  Future<bool> remove(String key) async {
    await ensureInitialized();
    if (_prefs == null) return false;
    
    await _prefs!.remove('$_cachePrefix$key');
    await _prefs!.remove('$_timestampPrefix$key');
    await _prefs!.remove('${_timestampPrefix}expiry_$key');
    return true;
  }

  /// Vide tout le cache
  Future<bool> clear() async {
    await ensureInitialized();
    if (_prefs == null) return false;
    
    final keys = _prefs!.getKeys();
    for (final key in keys) {
      if (key.startsWith(_cachePrefix) || key.startsWith(_timestampPrefix)) {
        await _prefs!.remove(key);
      }
    }
    return true;
  }
  
  /// Calcule la taille approximative du cache en octets
  Future<int> getCacheSize() async {
    await ensureInitialized();
    if (_prefs == null) return 0;
    
    int totalSize = 0;
    final keys = _prefs!.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(_cachePrefix)) {
        final value = _prefs!.getString(key);
        if (value != null) {
          totalSize += key.length * 2; // Approximation pour les caractères UTF-16
          totalSize += value.length * 2;
        }
      }
    }
    
    return totalSize;
  }
  
  /// Méthode alternative pour vider le cache (alias pour clear)
  Future<bool> clearCache() async {
    return await clear();
  }
  
  /// Invalide toutes les entrées qui correspondent à un préfixe
  Future<bool> invalidateByPrefix(String prefix) async {
    await ensureInitialized();
    if (_prefs == null) return false;
    
    final keys = _prefs!.getKeys();
    int count = 0;
    
    for (final key in keys) {
      if (key.startsWith('$_cachePrefix$prefix')) {
        final cacheKey = key.substring(_cachePrefix.length);
        await remove(cacheKey);
        count++;
      }
    }
    
    return count > 0;
  }
} 