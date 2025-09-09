import '../../../core/models/dashboard/dashboard_data.dart';
import '../api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'residence_service.dart';
import 'package:flutter/foundation.dart';
import '../../exceptions/api_exception.dart';
import '../../../core/services/event_bus/residence_event_bus.dart' as event_bus;
import '../../../core/config/app_config.dart';

class DashboardService extends ApiService {
  final storage = const FlutterSecureStorage();
  
  // Cache local pour stocker les dernières réponses
  final Map<String, dynamic> _responseCache = {};
  final event_bus.ResidenceEventBus _eventBus = event_bus.ResidenceEventBus();

  DashboardService(Dio dio) : super(dio) {
    // Configurer un timeout plus long pour éviter les erreurs de timeout
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.sendTimeout = const Duration(seconds: 30);
    
    // Logger les configurations pour le débogage
    debugPrint('🔧 Dashboard Service - Timeouts configurés: 30s');
  }
  
  // Construit un endpoint API correct avec le préfixe /api selon l'environnement
  String _ep(String path) => AppConfig.getApiEndpoint(path);
  
  // Méthode de journalisation qui remplace print()
  void _log(String message) {
    // En production, ces logs pourraient être envoyés à un service de télémétrie
    // Pour l'instant, on les désactive simplement
    // print(message);
  }

  // Méthode pour s'assurer que le token est ajouté aux requêtes
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await storage.read(key: 'token');
    if (token == null) {
      throw Exception('Token d\'authentification non trouvé');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // Override de la méthode handleError de ApiService
  @override
  Exception handleError(dynamic e) {
    if (e is DioException && e.response?.statusCode == 304) {
      return Exception('NOT_MODIFIED');
    }
    
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout) {
        return Exception('Connexion au serveur impossible');
      } else if (e.response?.statusCode == 401) {
        return Exception('Non autorisé à accéder à cette ressource');
      } else if (e.response?.statusCode == 403) {
        return Exception('Accès refusé à cette ressource');
      } else if (e.response?.statusCode == 404) {
        return Exception('Ressource non trouvée');
      } else {
        return Exception(e.response?.data?['message'] ?? 'Une erreur est survenue');
      }
    }
    return Exception('Une erreur inattendue est survenue');
  }
  
  // Méthode privée pour gérer spécifiquement les erreurs liées au cache
  Exception _handleCacheError(dynamic e, String cacheKey) {
    if (e is DioException && e.response?.statusCode == 304) {
      if (_responseCache.containsKey(cacheKey)) {
        return Exception('NOT_MODIFIED');
      }
    }
    return handleError(e);
  }

  /// Récupère les statistiques globales du partenaire
  Future<PartnerStats> getPartnerStats() async {
    const cacheKey = 'partner_stats';
    try {
      final headers = await _getAuthHeaders();
      final response = await dio.get(
        _ep('partners/stats'),
        options: Options(headers: headers),
      );
      
      // Mettre à jour le cache avec la nouvelle réponse
      _responseCache[cacheKey] = response.data['data'];
      
      return PartnerStats.fromJson(response.data['data']);
    } catch (e) {
      final error = _handleCacheError(e, cacheKey);
      
      // Si c'est une réponse 304, utiliser le cache
      if (error.toString().contains('NOT_MODIFIED')) {
        if (_responseCache.containsKey(cacheKey)) {
          _log('Utilisation des données en cache pour: $cacheKey');
          return PartnerStats.fromJson(_responseCache[cacheKey]);
        }
      }
      
      throw error;
    }
  }

  /// Récupère les tendances pour une période donnée
  Future<TrendData> getTrends({
    String period = 'monthly',
    String? startDate,
    String? endDate,
  }) async {
    final cacheKey = 'trends_${period}_${startDate ?? ''}_${endDate ?? ''}';
    try {
      final headers = await _getAuthHeaders();
      final queryParams = {
        'period': period,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };
      
      final response = await dio.get(
        _ep('partners/stats/trends'),
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      
      // Mettre à jour le cache avec la nouvelle réponse
      _responseCache[cacheKey] = response.data['data'];
      
      return TrendData.fromJson(response.data['data']);
    } catch (e) {
      final error = _handleCacheError(e, cacheKey);
      
      // Si c'est une réponse 304, utiliser le cache
      if (error.toString().contains('NOT_MODIFIED')) {
        if (_responseCache.containsKey(cacheKey)) {
          _log('Utilisation des données en cache pour: $cacheKey');
          return TrendData.fromJson(_responseCache[cacheKey]);
        }
      }
      
      throw error;
    }
  }

  /// Récupère les statistiques pour chaque résidence du partenaire
  Future<List<ResidenceStats>> getResidenceStats({
    String? startDate,
    String? endDate,
  }) async {
    final cacheKey = 'residence_stats_${startDate ?? ''}_${endDate ?? ''}';
    try {
      // Forcer le rafraîchissement des données en vidant le cache
      _responseCache.remove(cacheKey);
      
      // Utiliser ResidenceService pour les résidences au lieu de notre propre endpoint
      try {
        // Importer de manière dynamique pour éviter les dépendances circulaires
        final residenceService = await _getResidenceService();
        final residences = await residenceService.getMyResidences();
        
        _log('DashboardService: Résidences trouvées via ResidenceService: ${residences.length}');
        
        // Filtrer explicitement les résidences supprimées (si le filtre du service ne l'a pas déjà fait)
        final filteredResidences = residences.where((residence) => 
          residence.deleted != true
        ).toList();
        
        if (filteredResidences.length != residences.length) {
          print('🧹 Résidences filtrées par getResidenceStats: ${residences.length - filteredResidences.length} supprimées');
        }
        
        // Convertir les résidences en ResidenceStats
        List<ResidenceStats> stats = filteredResidences.map((residence) => 
          ResidenceStats(
            id: residence.id,
            title: residence.name,
            imageUrl: residence.images.isNotEmpty ? residence.images.first : '',
            status: residence.isAvailable ? 'available' : 'unavailable',
            displayAddress: '${residence.address}, ${residence.city}',
            totalBookings: 0, // Valeurs par défaut pour les statistiques
            occupancyRate: 0,
            revenue: 0,
            bookingsByStatus: {
              'pending': 0,
              'confirmed': 0,
              'completed': 0,
              'cancelled': 0,
            }
          )
        ).toList();
        
        // Mettre en cache les statistiques
        // Nous ne pouvons pas utiliser toJson() directement car la méthode n'est pas définie
        // Nous allons donc serialiser manuellement les objets
        _responseCache[cacheKey] = stats.map((stat) => {
          'residence': {
            'id': stat.id,
            'name': stat.title,
            'images': [stat.imageUrl],
            'is_available': stat.status == 'available',
            'location': {
              'formatted_address': stat.displayAddress
            }
          },
          'total_bookings': stat.totalBookings,
          'revenue': stat.revenue,
          'occupancy_rate': stat.occupancyRate,
          'bookings_by_status': stat.bookingsByStatus
        }).toList();
        
        return stats;
      } catch (e) {
        _log('Erreur lors de l\'utilisation de ResidenceService: $e');
        // Si ResidenceService échoue, continuer avec l'implémentation originale
      }

      final headers = await _getAuthHeaders();
      final queryParams = {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };
      
      final response = await dio.get(
        _ep('partners/stats/residences'),
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      
      // Mettre à jour le cache avec la nouvelle réponse
      _responseCache[cacheKey] = response.data['data'];
      
      final List<dynamic> data = response.data['data'];
      return data.map((json) => ResidenceStats.fromJson(json)).toList();
    } catch (e) {
      final error = _handleCacheError(e, cacheKey);
      
      // Si c'est une réponse 304, utiliser le cache
      if (error.toString().contains('NOT_MODIFIED')) {
        if (_responseCache.containsKey(cacheKey)) {
          _log('Utilisation des données en cache pour: $cacheKey');
          final List<dynamic> data = _responseCache[cacheKey];
          return data.map((json) => ResidenceStats.fromJson(json)).toList();
        }
      }
      
      throw error;
    }
  }

  /// Récupère les revenus regroupés par période
  Future<EarningsData> getEarnings({
    String? startDate,
    String? endDate,
  }) async {
    final cacheKey = 'earnings_${startDate ?? ''}_${endDate ?? ''}';
    try {
      final headers = await _getAuthHeaders();
      final queryParams = {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };
      
      final response = await dio.get(
        _ep('partners/earnings'),
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      
      // Mettre à jour le cache avec la nouvelle réponse
      _responseCache[cacheKey] = response.data['data'];
      
      return EarningsData.fromJson(response.data['data']);
    } catch (e) {
      final error = _handleCacheError(e, cacheKey);
      
      // Si c'est une réponse 304, utiliser le cache
      if (error.toString().contains('NOT_MODIFIED')) {
        if (_responseCache.containsKey(cacheKey)) {
          _log('Utilisation des données en cache pour: $cacheKey');
          return EarningsData.fromJson(_responseCache[cacheKey]);
        }
      }
      
      throw error;
    }
  }

  Future<DashboardOverview> getDashboardOverview() async {
    const cacheKey = 'dashboard_overview';
    try {
      final headers = await _getAuthHeaders();
      final response = await dio.get(
        _ep('partners/dashboard/overview'),
        options: Options(headers: headers),
      );
      
      // Log détaillé pour le débogage
      print('🔍 Dashboard Overview - Status code: ${response.statusCode}');
      print('🔍 Dashboard Overview - Réponse brute: ${response.data}');
      
      // Mettre à jour le cache avec la nouvelle réponse
      _responseCache[cacheKey] = response.data['data'];
      
      return DashboardOverview.fromJson(response.data['data']);
    } catch (e) {
      print('❌ Erreur détaillée dashboard overview: $e');
      
      // Essayer d'utiliser le cache si disponible
      if (_responseCache.containsKey(cacheKey)) {
        print('🔄 Utilisation des données en cache pour: $cacheKey');
        return DashboardOverview.fromJson(_responseCache[cacheKey]);
      }
      
      // Fournir un objet par défaut en cas d'erreur
      print('⚠️ Utilisation des données par défaut pour dashboard overview');
      return DashboardOverview(
        totalResidences: 0,
        bookings: {'total': 0, 'pending': 0, 'confirmed': 0, 'completed': 0, 'cancelled': 0},
        occupancyRate: 0.0,
        pendingReviews: 0,
        newMessages: 0,
        responseRate: 100.0,
        performance: {'total_revenue': 0, 'average_rating': 0.0},
      );
    }
  }

  Future<DashboardFinances> getDashboardFinances() async {
    const cacheKey = 'dashboard_finances';
    try {
      final headers = await _getAuthHeaders();
      final response = await dio.get(
        _ep('partners/dashboard/finances'),
        options: Options(headers: headers),
      );
      
      // Log détaillé pour le débogage
      print('🔍 Dashboard Finances - Status code: ${response.statusCode}');
      print('🔍 Dashboard Finances - Réponse brute: ${response.data}');
      
      // Mettre à jour le cache avec la nouvelle réponse
      _responseCache[cacheKey] = response.data['data'];
      
      return DashboardFinances.fromJson(response.data['data']);
    } catch (e) {
      print('❌ Erreur détaillée dashboard finances: $e');
      
      // Essayer d'utiliser le cache si disponible
      if (_responseCache.containsKey(cacheKey)) {
        print('🔄 Utilisation des données en cache pour: $cacheKey');
        return DashboardFinances.fromJson(_responseCache[cacheKey]);
      }
      
      // Fournir un objet par défaut en cas d'erreur
      print('⚠️ Utilisation des données par défaut pour dashboard finances');
      return DashboardFinances(
        dailyRevenue: 0,
        weeklyRevenue: 0,
        monthlyRevenue: 0,
        revenueGrowth: 0,
        bestPerformingResidences: [],
        revenueByCategory: {},
      );
    }
  }

  Future<RealtimeStats> getDashboardRealtime() async {
    const cacheKey = 'dashboard_realtime';
    try {
      final headers = await _getAuthHeaders();
      final response = await dio.get(
        _ep('partners/dashboard/realtime'),
        options: Options(headers: headers),
      );
      
      // Log détaillé pour le débogage
      print('🔍 Dashboard Realtime - Status code: ${response.statusCode}');
      print('🔍 Dashboard Realtime - Réponse brute: ${response.data}');
      
      // Mettre à jour le cache avec la nouvelle réponse
      _responseCache[cacheKey] = response.data['data'];
      
      return RealtimeStats.fromJson(response.data['data']);
    } catch (e) {
      print('❌ Erreur détaillée dashboard realtime: $e');
      
      // Essayer d'utiliser le cache si disponible
      if (_responseCache.containsKey(cacheKey)) {
        print('🔄 Utilisation des données en cache pour: $cacheKey');
        return RealtimeStats.fromJson(_responseCache[cacheKey]);
      }
      
      // Fournir un objet par défaut en cas d'erreur
      print('⚠️ Utilisation des données par défaut pour dashboard realtime');
      return RealtimeStats(
        activeBookings: 0,
        pendingRequests: 0,
        todayVisits: [],
        recentActivities: [],
      );
    }
  }

  // Méthode privée pour obtenir une instance de ResidenceService
  Future<ResidenceService> _getResidenceService() async {
    try {
      // Utiliser l'API Config central au lieu d'une URL codée en dur
      final baseUrl = AppConfig.apiUrl;
      
      // Récupérer l'instance depuis le DI plutôt que d'en créer une nouvelle
      // Utiliser l'instance existante de ResidenceService si possible
      return ResidenceService(baseUrl: baseUrl, storage: const FlutterSecureStorage());
    } catch (e) {
      _log('Erreur lors de l\'initialisation de ResidenceService: $e');
      throw Exception('Impossible d\'initialiser ResidenceService');
    }
  }

  // Getter pour le stream d'événements liés aux résidences
  Stream<event_bus.ResidenceEventType> get residenceEventStream => _eventBus.stream;
}

class DashboardOverview {
  final int totalResidences;
  final Map<String, int> bookings;
  final double occupancyRate;
  final int pendingReviews;
  final int newMessages;
  final double responseRate;
  final Map<String, dynamic> performance;

  DashboardOverview({
    required this.totalResidences,
    required this.bookings,
    required this.occupancyRate,
    required this.pendingReviews,
    required this.newMessages,
    required this.responseRate,
    required this.performance,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      totalResidences: json['total_residences'] ?? 0,
      bookings: Map<String, int>.from(json['bookings'] ?? {}),
      occupancyRate: (json['occupancy_rate'] ?? 0).toDouble(),
      pendingReviews: json['pending_reviews'] ?? 0,
      newMessages: json['new_messages'] ?? 0,
      responseRate: (json['response_rate'] ?? 0).toDouble(),
      performance: json['performance'] ?? {},
    );
  }
}

class DashboardFinances {
  final double monthlyRevenue;
  final double dailyRevenue;
  final double weeklyRevenue;
  final double revenueGrowth;
  final List<BestPerformingResidence> bestPerformingResidences;
  final Map<String, CategoryRevenue> revenueByCategory;

  DashboardFinances({
    required this.monthlyRevenue,
    required this.dailyRevenue,
    required this.weeklyRevenue,
    required this.revenueGrowth,
    required this.bestPerformingResidences,
    required this.revenueByCategory,
  });

  factory DashboardFinances.fromJson(Map<String, dynamic> json) {
    final bestResidencesList = (json['best_performing_residences'] as List?)?.map(
          (residence) => BestPerformingResidence.fromJson(residence),
        ).toList() ??
        [];

    final categoryMap = (json['revenue_by_category'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, CategoryRevenue.fromJson(value)),
        ) ??
        {};

    return DashboardFinances(
      monthlyRevenue: (json['monthly_revenue'] ?? 0).toDouble(),
      dailyRevenue: (json['daily_revenue'] ?? 0).toDouble(),
      weeklyRevenue: (json['weekly_revenue'] ?? 0).toDouble(),
      revenueGrowth: (json['revenue_growth'] ?? 0).toDouble(),
      bestPerformingResidences: bestResidencesList,
      revenueByCategory: categoryMap,
    );
  }
}
