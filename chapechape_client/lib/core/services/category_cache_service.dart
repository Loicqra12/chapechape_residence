import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/residence_type_enum.dart';
import 'api_service.dart';
import 'logger_service.dart';

class CategoryData {
  final String id;
  final ResidenceType type;
  final String title;
  final List<String> features;
  
  CategoryData({
    required this.id,
    required this.type,
    required this.title,
    required this.features,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString().split('.').last,
    'title': title,
    'features': features,
  };

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      id: json['id'],
      type: ResidenceType.values.firstWhere(
        (type) => type.toString().split('.').last == json['type'],
        orElse: () => ResidenceType.other,
      ),
      title: json['title'],
      features: List<String>.from(json['features']),
    );
  }
}

class CategoryCacheService {
  final ApiService apiService;
  final LoggerService logger;
  static const String _cacheKey = 'categories_cache';
  static const Duration _cacheDuration = Duration(hours: 12);
  
  // Cache interne
  List<CategoryData>? _cachedCategories;
  DateTime? _lastFetchTime;
  
  CategoryCacheService({
    required this.apiService,
    required this.logger,
  });
  
  /// Initialise le service
  Future<void> initialize() async {
    logger.debug('Initialisation du service CategoryCacheService');
    // Chargement initial des catégories
    await getAllCategories();
  }
  
  Future<List<CategoryData>> getAllCategories() async {
    // Si nous avons des données en cache et qu'elles sont encore valides
    if (_cachedCategories != null && _lastFetchTime != null) {
      final now = DateTime.now();
      if (now.difference(_lastFetchTime!) < _cacheDuration) {
        logger.debug('Utilisation des catégories en cache (${_cachedCategories!.length})');
        return _cachedCategories!;
      }
    }
    
    try {
      // Appel à l'API pour récupérer les catégories
      logger.debug('Récupération des catégories depuis l\'API');
      final response = await apiService.get('/categories');
      
      if (response != null) {
        // Convertir la réponse en Map - response est de type Response<dynamic> de Dio
        final Map<String, dynamic> data = response.data as Map<String, dynamic>;
        final List<CategoryData> categories = (data['categories'] as List)
            .map((item) => CategoryData.fromJson(item))
            .toList();
        
        // Mise à jour du cache
        _cachedCategories = categories;
        _lastFetchTime = DateTime.now();
        
        logger.debug('${categories.length} catégories récupérées avec succès');
        return categories;
      } else {
        logger.error('Erreur lors de la récupération des catégories: réponse null');
        // En cas d'erreur, on retourne le cache si disponible ou des données factices
        return _cachedCategories ?? _getFallbackCategories();
      }
    } catch (e) {
      logger.error('Exception lors de la récupération des catégories: $e');
      // En cas d'erreur d'autorisation ou autre, retourner des données factices
      return _cachedCategories ?? _getFallbackCategories();
    }
  }
  
  Future<void> forceRefresh() async {
    logger.debug('Forçage du rafraîchissement des catégories');
    _cachedCategories = null;
    _lastFetchTime = null;
    await getAllCategories();
  }
  
  // Données factices pour quand l'API n'est pas accessible
  List<CategoryData> _getFallbackCategories() {
    logger.debug('Utilisation des catégories factices');
    return [
      CategoryData(
        id: 'apartment',
        type: ResidenceType.apartment,
        title: 'Appartements',
        features: ['Moderne', 'Familial', 'Services inclus'],
      ),
      CategoryData(
        id: 'villa',
        type: ResidenceType.villa,
        title: 'Villas',
        features: ['Spacieux', 'Jardin', 'Piscine'],
      ),
      CategoryData(
        id: 'studio',
        type: ResidenceType.studio,
        title: 'Studios',
        features: ['Compact', 'Économique', 'Pratique'],
      ),
      CategoryData(
        id: 'luxury',
        type: ResidenceType.luxury,
        title: 'Luxe',
        features: ['Premium', 'Services VIP', 'Emplacement exclusif'],
      ),
    ];
  }
} 