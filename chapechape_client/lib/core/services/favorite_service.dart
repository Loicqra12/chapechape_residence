import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/residence_model.dart';
import 'api_service.dart';
import 'cache_service.dart';
import 'logger_service.dart';

/// Service pour gérer les résidences favorites de l'utilisateur
class FavoriteService {
  final ApiService _apiService;
  final CacheService _cacheService;
  final LoggerService _logger;
  final SharedPreferences? _prefs;
  static const String _favoritesKey = 'user_favorites';
  
  FavoriteService({
    required ApiService apiService,
    required CacheService cacheService,
    required LoggerService logger,
    SharedPreferences? prefs,
  }) : _apiService = apiService,
       _cacheService = cacheService,
       _logger = logger,
       _prefs = prefs;

  // Instance unique (singleton)
  static FavoriteService? _instance;
  
  /// Initialise le service de favoris
  static Future<FavoriteService> initialize() async {
    if (_instance != null) {
      return _instance!;
    }
    
    final apiService = await ApiService.initialize();
    final cacheService = CacheService.getInstance();
    await cacheService.ensureInitialized();
    final loggerService = LoggerService();
    
    _instance = FavoriteService(
      apiService: apiService,
      cacheService: cacheService,
      logger: loggerService,
    );
    
    return _instance!;
  }

  /// Récupère la liste des résidences favorites de l'utilisateur
  Future<List<String>> getFavorites() async {
    try {
      // Vérifier d'abord dans le cache
      final cachedFavorites = _cacheService.get(_favoritesKey);
      if (cachedFavorites != null) {
        return List<String>.from(cachedFavorites as List);
      }
      
      // Sinon, essayer dans les SharedPreferences
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final favoritesString = prefs.getString(_favoritesKey);
      
      if (favoritesString != null) {
        final List<dynamic> decodedFavorites = jsonDecode(favoritesString);
        final favoritesList = List<String>.from(decodedFavorites);
        
        // Stocker dans le cache pour un accès plus rapide ultérieurement
        _cacheService.put(_favoritesKey, favoritesList);
        
        return favoritesList;
      }
      
      return [];
    } catch (e) {
      _logger.error('Erreur lors de la récupération des favoris: $e');
      return [];
    }
  }

  /// Ajoute une résidence aux favoris
  Future<bool> addToFavorites(String residenceId) async {
    try {
      final favorites = await getFavorites();
      
      if (!favorites.contains(residenceId)) {
        favorites.add(residenceId);
        await _saveFavorites(favorites);
        await _syncFavoritesWithServer(residenceId, true);
        _logger.info('Résidence ajoutée aux favoris: $residenceId');
        return true;
      }
      
      return false;
    } catch (e) {
      _logger.error('Erreur lors de l\'ajout aux favoris: $e');
      return false;
    }
  }

  /// Supprime une résidence des favoris
  Future<bool> removeFromFavorites(String residenceId) async {
    try {
      final favorites = await getFavorites();
      
      if (favorites.contains(residenceId)) {
        favorites.remove(residenceId);
        await _saveFavorites(favorites);
        await _syncFavoritesWithServer(residenceId, false);
        _logger.info('Résidence supprimée des favoris: $residenceId');
        return true;
      }
      
      return false;
    } catch (e) {
      _logger.error('Erreur lors de la suppression des favoris: $e');
      return false;
    }
  }

  /// Sauvegarde la liste des favoris en local
  Future<void> _saveFavorites(List<String> favorites) async {
    try {
      // Sauvegarder dans SharedPreferences
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString(_favoritesKey, jsonEncode(favorites));
      
      // Mettre à jour également dans le cache
      _cacheService.put(_favoritesKey, favorites);
      
      // Supprimer les caches associés aux favoris
      _cacheService.remove('favorites_stats');
    } catch (e) {
      _logger.error('Erreur lors de la sauvegarde des favoris: $e');
    }
  }

  /// Bascule l'état favori d'une résidence
  Future<bool> toggleFavorite(String residenceId) async {
    try {
      final favorites = await getFavorites();
      final isFav = favorites.contains(residenceId);
      
      if (isFav) {
        return await removeFromFavorites(residenceId);
      } else {
        return await addToFavorites(residenceId);
      }
    } catch (e) {
      _logger.error('Erreur lors du basculement des favoris: $e');
      return false;
    }
  }

  /// Synchronise les favoris avec le serveur
  Future<void> _syncFavoritesWithServer(String residenceId, bool isAdding) async {
    try {
      // Implémenter l'appel API ici quand le backend sera prêt
      _logger.info('Favoris synchronisé avec le serveur: $residenceId (${isAdding ? 'ajout' : 'suppression'})');
    } catch (e) {
      _logger.error('Erreur lors de la synchronisation avec le serveur: $e');
    }
  }

  /// Synchronise tous les favoris avec le serveur
  Future<void> syncAllFavorites() async {
    try {
      final localFavorites = await getFavorites();
      // Implémenter l'appel API pour obtenir les favoris du serveur
      final serverFavorites = <String>[]; // À remplacer par l'appel API
      
      // Fusionner les favoris locaux et du serveur
      final mergedFavorites = <String>{...localFavorites, ...serverFavorites}.toList();
      
      // Sauvegarder la liste fusionnée en local
      await _saveFavorites(mergedFavorites);
      
      _logger.info('Tous les favoris ont été synchronisés');
    } catch (e) {
      _logger.error('Erreur lors de la synchronisation de tous les favoris: $e');
    }
  }

  /// Vérifie si une résidence est dans les favoris
  Future<bool> checkFavorite(String residenceId) async {
    try {
      // Construire une clé de cache spécifique pour cette vérification
      final cacheKey = 'favorite_check_$residenceId';
      
      // Vérifier dans le cache
      final cachedResult = _cacheService.get(cacheKey);
      if (cachedResult != null) {
        return cachedResult as bool;
      }
      
      // Obtenir les favoris actuels et vérifier
      final favorites = await getFavorites();
      final isFavorite = favorites.contains(residenceId);
      
      // Mettre en cache le résultat pour des vérifications rapides ultérieures
      _cacheService.put(cacheKey, isFavorite, expiryInMinutes: 5);
      
      return isFavorite;
    } catch (e) {
      _logger.error('Erreur lors de la vérification des favoris: $e');
      return false;
    }
  }

  /// Obtient les statistiques des favoris
  Future<Map<String, dynamic>> getFavoriteStats() async {
    try {
      // Vérifier d'abord dans le cache
      final cachedStats = _cacheService.get('favorites_stats');
      if (cachedStats != null) {
        return Map<String, dynamic>.from(cachedStats as Map);
      }
      
      // Générer les statistiques depuis les favoris actuels
      final favorites = await getFavorites();
      final stats = {
        'count': favorites.length,
        'ids': favorites,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      // Stocker les stats dans le cache
      _cacheService.put('favorites_stats', stats, expiryInMinutes: 30);
      
      return stats;
    } catch (e) {
      _logger.error('Erreur lors de la récupération des statistiques: $e');
      return {
        'count': 0,
        'ids': <String>[],
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    }
  }
}
