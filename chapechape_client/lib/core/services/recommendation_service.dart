import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/residence_model.dart';
import '../models/residence_type_enum.dart';
import '../models/user_preferences_model.dart';
import 'residence_service.dart';

/// Service pour gérer les recommandations personnalisées
/// 
/// Ce service analyse les comportements utilisateur et génère des 
/// recommandations de résidences personnalisées en fonction de leurs
/// préférences et historique de navigation
class RecommendationService {
  static RecommendationService? _instance;
  late ResidenceService _residenceService;
  bool _isInitialized = false;
  
  // Clés pour le stockage des préférences
  static const String _viewHistoryKey = 'user_view_history';
  static const String _searchHistoryKey = 'user_search_history';
  static const String _preferencesKey = 'user_preferences';
  static const String _lastRecommendationKey = 'last_recommendation_timestamp';
  
  // Durée avant de rafraîchir les recommandations (12 heures)
  static const Duration _refreshInterval = Duration(hours: 12);
  
  // Nombre maximum d'items dans l'historique
  static const int _maxHistoryItems = 50;
  
  // Cache des recommandations
  List<Residence>? _cachedRecommendations;
  DateTime? _lastRecommendationUpdate;
  
  // Constructeur privé
  RecommendationService._();
  
  // Factory pour l'accès singleton
  factory RecommendationService() {
    _instance ??= RecommendationService._();
    return _instance!;
  }
  
  /// Initialise le service de recommandation
  Future<RecommendationService> initialize() async {
    if (_isInitialized) return this;
    
    // Initialiser le service de résidence
    _residenceService = await ResidenceService.initialize();
    _isInitialized = true;
    
    // Vérifier si le cache a expiré
    if (_cachedRecommendations == null || _isCacheExpired()) {
      // Générer de nouvelles recommandations
      _cachedRecommendations = await _generateRecommendations();
      _lastRecommendationUpdate = DateTime.now();
      
      // Enregistrer la date de dernière mise à jour
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastRecommendationKey, DateTime.now().toIso8601String());
      } catch (e) {
        print('Erreur lors de la sauvegarde de la date de recommandation: $e');
      }
    }
    
    return this;
  }
  
  /// Vérifie si le cache des recommandations a expiré
  bool _isCacheExpired() {
    if (_lastRecommendationUpdate == null) return true;
    
    final now = DateTime.now();
    return now.difference(_lastRecommendationUpdate!) > _refreshInterval;
  }
  
  /// Ajoute une résidence à l'historique de consultation
  Future<void> addToViewHistory(String residenceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Récupérer l'historique existant
      final viewHistory = prefs.getStringList(_viewHistoryKey) ?? [];
      
      // Ajouter l'ID au début de la liste (plus récent d'abord)
      // Si l'ID existe déjà, le supprimer d'abord pour éviter les doublons
      viewHistory.remove(residenceId);
      viewHistory.insert(0, residenceId);
      
      // Limiter la taille de l'historique
      if (viewHistory.length > _maxHistoryItems) {
        viewHistory.removeRange(_maxHistoryItems, viewHistory.length);
      }
      
      // Sauvegarder la liste mise à jour
      await prefs.setStringList(_viewHistoryKey, viewHistory);
      
      // Invalider le cache des recommandations
      _invalidateRecommendationsCache();
    } catch (e) {
      print('Erreur lors de l\'ajout à l\'historique de consultation: $e');
    }
  }
  
  /// Ajoute un terme de recherche à l'historique
  Future<void> addToSearchHistory(String searchTerm) async {
    if (searchTerm.trim().isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Récupérer l'historique existant
      final searchHistory = prefs.getStringList(_searchHistoryKey) ?? [];
      
      // Normaliser le terme de recherche
      final normalizedTerm = searchTerm.toLowerCase().trim();
      
      // Éviter les doublons et mettre le terme au début
      searchHistory.remove(normalizedTerm);
      searchHistory.insert(0, normalizedTerm);
      
      // Limiter la taille de l'historique
      if (searchHistory.length > _maxHistoryItems) {
        searchHistory.removeRange(_maxHistoryItems, searchHistory.length);
      }
      
      // Sauvegarder la liste mise à jour
      await prefs.setStringList(_searchHistoryKey, searchHistory);
      
      // Invalider le cache des recommandations
      _invalidateRecommendationsCache();
    } catch (e) {
      print('Erreur lors de l\'ajout à l\'historique de recherche: $e');
    }
  }
  
  /// Enregistre les préférences utilisateur
  Future<void> saveUserPreferences(UserPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convertir en Map pour stocker
      final prefMap = preferences.toJson();
      
      // Stocker chaque préférence individuellement
      for (final entry in prefMap.entries) {
        if (entry.value is String) {
          await prefs.setString('${_preferencesKey}_${entry.key}', entry.value as String);
        } else if (entry.value is bool) {
          await prefs.setBool('${_preferencesKey}_${entry.key}', entry.value as bool);
        } else if (entry.value is int) {
          await prefs.setInt('${_preferencesKey}_${entry.key}', entry.value as int);
        } else if (entry.value is double) {
          await prefs.setDouble('${_preferencesKey}_${entry.key}', entry.value as double);
        } else if (entry.value is List<String>) {
          await prefs.setStringList('${_preferencesKey}_${entry.key}', entry.value as List<String>);
        }
      }
      
      // Invalider le cache des recommandations
      _invalidateRecommendationsCache();
    } catch (e) {
      print('Erreur lors de la sauvegarde des préférences utilisateur: $e');
    }
  }
  
  /// Récupère les préférences utilisateur
  Future<UserPreferences> getUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Créer un objet de préférences avec les valeurs par défaut
      final preferences = UserPreferences(
        preferredLocations: prefs.getStringList('${_preferencesKey}_preferredLocations') ?? [],
        preferredTypes: _getPreferredTypes(prefs),
        minPrice: prefs.getDouble('${_preferencesKey}_minPrice') ?? 0,
        maxPrice: prefs.getDouble('${_preferencesKey}_maxPrice') ?? 1000000,
        minBedrooms: prefs.getInt('${_preferencesKey}_minBedrooms') ?? 0,
        maxBedrooms: prefs.getInt('${_preferencesKey}_maxBedrooms') ?? 10,
        preferFurnished: prefs.getBool('${_preferencesKey}_preferFurnished') ?? false,
        preferAirConditioned: prefs.getBool('${_preferencesKey}_preferAirConditioned') ?? false,
        preferParking: prefs.getBool('${_preferencesKey}_preferParking') ?? false,
        preferSwimmingPool: prefs.getBool('${_preferencesKey}_preferSwimmingPool') ?? false,
        preferSecurity: prefs.getBool('${_preferencesKey}_preferSecurity') ?? true,
      );
      
      return preferences;
    } catch (e) {
      print('Erreur lors de la récupération des préférences utilisateur: $e');
      // Retourner des préférences par défaut en cas d'erreur
      return UserPreferences();
    }
  }
  
  /// Convertit les types préférés à partir des SharedPreferences
  List<ResidenceType> _getPreferredTypes(SharedPreferences prefs) {
    final typeList = prefs.getStringList('${_preferencesKey}_preferredTypes') ?? [];
    
    return typeList.map((type) {
      try {
        return ResidenceType.values.firstWhere(
          (e) => e.toString() == type || e.toString() == 'ResidenceType.$type',
          orElse: () => ResidenceType.apartment
        );
      } catch (e) {
        return ResidenceType.apartment;
      }
    }).toList();
  }
  
  /// Récupère l'historique de consultation des résidences
  Future<List<String>> getViewHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_viewHistoryKey) ?? [];
    } catch (e) {
      print('Erreur lors de la récupération de l\'historique de consultation: $e');
      return [];
    }
  }
  
  /// Récupère l'historique de recherche
  Future<List<String>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_searchHistoryKey) ?? [];
    } catch (e) {
      print('Erreur lors de la récupération de l\'historique de recherche: $e');
      return [];
    }
  }
  
  /// Invalide le cache des recommandations
  void _invalidateRecommendationsCache() {
    _cachedRecommendations = null;
    _lastRecommendationUpdate = null;
  }
  
  /// Génère des recommandations personnalisées
  Future<List<Residence>> _generateRecommendations() async {
    if (!_isInitialized) await initialize();
    
    // Récupérer les données utilisateur
    final viewHistory = await getViewHistory();
    final searchHistory = await getSearchHistory();
    final preferences = await getUserPreferences();
    
    // Récupérer toutes les résidences disponibles
    final allResidences = await _residenceService.getAllResidences();
    
    // Si pas assez de données utilisateur, retourner les résidences mises en avant
    if (viewHistory.isEmpty && searchHistory.isEmpty && 
        preferences.preferredLocations.isEmpty && preferences.preferredTypes.isEmpty) {
      return _residenceService.getFeaturedResidences();
    }
    
    // Créer un scoring pour chaque résidence
    final Map<String, int> residenceScores = {};
    
    for (final residence in allResidences) {
      int score = 0;
      
      // Bonus pour les résidences déjà consultées (mais pas trop récemment vues)
      final viewIndex = viewHistory.indexOf(residence.id);
      if (viewIndex >= 5 && viewIndex < 20) {
        // Les résidences vues il y a un moment (pas trop récemment) ont un bon score
        score += 10;
      } else if (viewIndex >= 0 && viewIndex < 5) {
        // Les résidences très récemment vues ont un score plus faible (déjà vues)
        score += 2;
      }
      
      // Score basé sur les termes de recherche
      for (final term in searchHistory.take(10)) {
        if (residence.title.toLowerCase().contains(term) || 
            residence.description.toLowerCase().contains(term) ||
            _getLocationString(residence.location).toLowerCase().contains(term)) {
          score += 15;
        }
      }
      
      // Score basé sur les préférences de localisation
      for (final location in preferences.preferredLocations) {
        if (_getLocationString(residence.location).toLowerCase().contains(location.toLowerCase())) {
          score += 20;
        }
      }
      
      // Score basé sur les types préférés
      if (preferences.preferredTypes.contains(residence.type)) {
        score += 25;
      }
      
      // Score basé sur le prix
      if (residence.price >= preferences.minPrice && 
          residence.price <= preferences.maxPrice) {
        score += 15;
      }
      
      // Score basé sur le nombre de chambres
      if (residence.bedrooms >= preferences.minBedrooms && 
          residence.bedrooms <= preferences.maxBedrooms) {
        score += 10;
      }
      
      // Score basé sur les commodités (utilisez les propriétés correctes du modèle Residence)
      if (preferences.preferFurnished && residence.amenities.any((a) => a.toLowerCase().contains('meublé'))) {
        score += 8;
      }
      
      if (preferences.preferAirConditioned && residence.amenities.any((a) => a.toLowerCase().contains('climatisation'))) {
        score += 8;
      }
      
      if (preferences.preferParking && residence.amenities.any((a) => a.toLowerCase().contains('parking'))) {
        score += 8;
      }
      
      if (preferences.preferSwimmingPool && residence.hasPool) {
        score += 10;
      }
      
      if (preferences.preferSecurity && residence.amenities.any((a) => a.toLowerCase().contains('sécurité'))) {
        score += 12;
      }
      
      // Bonus pour les résidences récentes
      final now = DateTime.now();
      final daysSinceAdded = residence.createdAt != null ? now.difference(residence.createdAt!).inDays : 0;
      if (daysSinceAdded < 7) {
        score += 10; // Bonus pour les nouvelles résidences
      } else if (residence.isNew) {
        score += 8; // Bonus pour les résidences marquées comme nouvelles
      }
      
      // Enregistrer le score
      residenceScores[residence.id] = score;
    }
    
    // Trier les résidences par score (décroissant)
    allResidences.sort((a, b) {
      final scoreA = residenceScores[a.id] ?? 0;
      final scoreB = residenceScores[b.id] ?? 0;
      return scoreB.compareTo(scoreA);
    });
    
    // Prendre les 15 meilleures recommandations
    final recommendations = allResidences.take(15).toList();
    
    // Ajouter une légère randomisation pour éviter de toujours voir les mêmes résidences
    recommendations.shuffle(Random(DateTime.now().millisecondsSinceEpoch));
    
    return recommendations;
  }
  
  /// Convertit la Map de localisation en chaîne de caractères pour la recherche
  String _getLocationString(Map<String, dynamic> location) {
    if (location.containsKey('formattedAddress')) {
      return location['formattedAddress'] as String;
    }
    
    final parts = <String>[];
    if (location.containsKey('street')) parts.add(location['street'] as String);
    if (location.containsKey('city')) parts.add(location['city'] as String);
    if (location.containsKey('country')) parts.add(location['country'] as String);
    
    return parts.join(', ');
  }
  
  /// Obtenir les recommandations personnalisées pour l'utilisateur
  Future<List<Residence>> getRecommendedResidences({int limit = 10}) async {
    if (!_isInitialized) await initialize();
    
    // Utiliser le cache s'il existe
    final recommendations = _cachedRecommendations ?? await _generateRecommendations();
    
    // Limiter le nombre de résultats
    return recommendations.take(limit).toList();
  }
  
  /// Efface toutes les données de personnalisation
  Future<void> clearAllUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Effacer les historiques et préférences
      await prefs.remove(_viewHistoryKey);
      await prefs.remove(_searchHistoryKey);
      
      // Effacer toutes les clés de préférences
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (key.startsWith('${_preferencesKey}_')) {
          await prefs.remove(key);
        }
      }
      
      // Invalider le cache
      _invalidateRecommendationsCache();
    } catch (e) {
      print('Erreur lors de l\'effacement des données utilisateur: $e');
    }
  }
}
