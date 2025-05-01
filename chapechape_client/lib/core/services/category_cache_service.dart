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
    
    // NOTE: Le rôle client n'est pas autorisé à accéder à la route '/categories'
    // On utilise directement les catégories factices pour éviter l'erreur d'autorisation
    logger.debug('Utilisation des catégories factices pour l\'application client');
    final categories = _getFallbackCategories();
    
    // Mise à jour du cache
    _cachedCategories = categories;
    _lastFetchTime = DateTime.now();
    
    logger.debug('${categories.length} catégories factices chargées');
    return categories;
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