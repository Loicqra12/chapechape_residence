import '../../../core/models/dashboard/dashboard_data.dart';
import '../api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DashboardService extends ApiService {
  final Dio dio;
  final storage = const FlutterSecureStorage();

  DashboardService(this.dio) : super(dio);

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

  // Méthode pour gérer les erreurs
  Exception handleError(dynamic e) {
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

  Future<DashboardOverview> getDashboardOverview() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await dio.get(
        '/partners/dashboard/overview',
        options: Options(headers: headers),
      );
      return DashboardOverview.fromJson(response.data['data']);
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<DashboardFinances> getDashboardFinances() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await dio.get(
        '/partners/dashboard/finances',
        options: Options(headers: headers),
      );
      return DashboardFinances.fromJson(response.data['data']);
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<RealtimeStats> getDashboardRealtime() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await dio.get(
        '/partners/dashboard/realtime',
        options: Options(headers: headers),
      );
      return RealtimeStats.fromJson(response.data['data']);
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<PartnerStats> getPartnerStats() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await dio.get(
        '/partners/stats',
        options: Options(headers: headers),
      );
      return PartnerStats.fromJson(response.data['data']);
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<List<ResidenceStats>> getResidenceStats({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };
      
      final response = await dio.get(
        '/partners/residence-stats',
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      
      final List<dynamic> data = response.data['data'];
      return data.map((json) => ResidenceStats.fromJson(json)).toList();
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<TrendData> getTrends({
    String period = 'monthly',
    String? startDate,
    String? endDate,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = {
        'period': period,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };
      
      final response = await dio.get(
        '/partners/trends',
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      
      return TrendData.fromJson(response.data['data']);
    } catch (e) {
      throw handleError(e);
    }
  }

  Future<EarningsData> getEarnings({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };
      
      final response = await dio.get(
        '/partners/earnings',
        queryParameters: queryParams,
        options: Options(headers: headers),
      );
      
      return EarningsData.fromJson(response.data['data']);
    } catch (e) {
      throw handleError(e);
    }
  }
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
