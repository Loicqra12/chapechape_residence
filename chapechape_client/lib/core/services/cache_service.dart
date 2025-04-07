import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  static const String _boxName = 'api_cache';
  late final Box<String> _cacheBox;
  static CacheService? _instance;

  // Durée par défaut de la mise en cache (5 minutes)
  final Duration defaultCacheDuration;

  // Constructeur privé
  CacheService._({this.defaultCacheDuration = const Duration(minutes: 5)});

  /// Initialiser et récupérer l'instance singleton du service de cache
  static Future<CacheService> initialize({
    Duration defaultCacheDuration = const Duration(minutes: 5),
  }) async {
    if (_instance != null) return _instance!;

    final instance = CacheService._(defaultCacheDuration: defaultCacheDuration);
    await instance._initialize();
    _instance = instance;
    return instance;
  }

  /// Initialiser la boîte Hive pour le stockage du cache
  Future<void> _initialize() async {
    try {
      _cacheBox = await Hive.openBox<String>(_boxName);
      debugPrint('Cache service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing cache service: $e');
      // En cas d'erreur d'ouverture, on tente de supprimer et recréer la boîte
      try {
        await Hive.deleteBoxFromDisk(_boxName);
        _cacheBox = await Hive.openBox<String>(_boxName);
        debugPrint('Cache box recreated successfully after error');
      } catch (e) {
        debugPrint('Fatal error initializing cache box: $e');
        rethrow;
      }
    }
  }

  /// Récupérer une valeur du cache.
  /// Si la valeur n'existe pas ou est expirée, utilise la fonction fetcher pour la récupérer.
  Future<T> get<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration? duration,
    bool forceRefresh = false,
  }) async {
    // Utiliser la durée spécifiée ou la durée par défaut
    final cacheDuration = duration ?? defaultCacheDuration;
    final cacheKey = _generateCacheKey(key);

    // Si le forceRefresh est activé, on ignore le cache
    if (!forceRefresh) {
      // Vérifier si la clé existe dans le cache
      final cachedValue = _cacheBox.get(cacheKey);
      if (cachedValue != null) {
        try {
          // Décoder la valeur du cache
          final cacheEntry = CacheEntry.fromJson(jsonDecode(cachedValue));
          
          // Vérifier si la valeur n'est pas expirée
          if (!cacheEntry.isExpired) {
            debugPrint('Cache hit for key: $key');
            return cacheEntry.data as T;
          }
          debugPrint('Cache expired for key: $key');
        } catch (e) {
          debugPrint('Error decoding cache for key $key: $e');
          // Supprimer l'entrée invalide
          await _cacheBox.delete(cacheKey);
        }
      }
    }

    // Cache miss ou forceRefresh, récupérer les données via fetcher
    debugPrint('Cache miss for key: $key, fetching fresh data');
    try {
      final data = await fetcher();
      
      // Sauvegarder dans le cache avec la durée spécifiée
      final cacheEntry = CacheEntry(
        data: data,
        expiryTime: DateTime.now().add(cacheDuration),
      );

      // Sérialiser et stocker l'entrée
      await _cacheBox.put(cacheKey, jsonEncode(cacheEntry.toJson()));
      
      return data;
    } catch (e) {
      debugPrint('Error fetching data for key $key: $e');
      rethrow;
    }
  }

  /// Générer une clé de cache unique pour une clé donnée
  String _generateCacheKey(String key) {
    // Normaliser la clé pour éviter les doublons
    return key.trim().toLowerCase();
  }

  /// Invalider une entrée spécifique du cache
  Future<void> invalidate(String key) async {
    final cacheKey = _generateCacheKey(key);
    await _cacheBox.delete(cacheKey);
    debugPrint('Cache invalidated for key: $key');
  }

  /// Invalider toutes les entrées du cache
  Future<void> invalidateAll() async {
    await _cacheBox.clear();
    debugPrint('All cache entries invalidated');
  }

  /// Invalider toutes les entrées qui correspondent à un préfixe
  Future<void> invalidateByPrefix(String prefix) async {
    final normalizedPrefix = prefix.trim().toLowerCase();
    
    // Récupérer toutes les clés qui commencent par le préfixe
    final keysToDelete = _cacheBox.keys
        .where((key) => (key as String).startsWith(normalizedPrefix))
        .toList();
    
    // Supprimer chaque clé
    for (final key in keysToDelete) {
      await _cacheBox.delete(key);
    }
    
    debugPrint('Invalidated ${keysToDelete.length} cache entries with prefix: $prefix');
  }
} 