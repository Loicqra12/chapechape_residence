import 'package:dio/dio.dart';
import '../../models/review/review_model.dart';
import 'api_service.dart';

/// Service pour la gestion des avis et évaluations
class ReviewService {
  final ApiService _apiService;
  final Dio _dio;
  
  ReviewService(Dio dio) 
      : _dio = dio,
        _apiService = ApiService(authBloc: null);
  
  // Alternative constructor
  ReviewService.withApiService({required ApiService apiService}) 
      : _apiService = apiService,
        _dio = apiService.dio;
  
  /// Récupère les avis pour une résidence spécifique
  /// 
  /// [residenceId] : ID de la résidence
  /// [page] : Numéro de page pour la pagination
  /// [limit] : Nombre d'avis par page
  Future<List<ReviewModel>> getResidenceReviews(
    String residenceId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/reviews/residence/$residenceId',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );
      
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => ReviewModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Impossible de récupérer les avis: $e');
    }
  }
  
  /// Récupère un avis spécifique par son ID
  /// 
  /// [reviewId] : ID de l'avis
  Future<ReviewModel> getReview(String reviewId) async {
    try {
      final response = await _apiService.get('/api/reviews/$reviewId');
      
      return ReviewModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Impossible de récupérer cet avis: $e');
    }
  }
  
  /// Répond à un avis
  /// 
  /// [reviewId] : ID de l'avis auquel répondre
  /// [response] : Texte de la réponse
  Future<ReviewModel> respondToReview(String reviewId, String response) async {
    try {
      final apiResponse = await _apiService.post(
        '/api/reviews/$reviewId/respond',
        data: {'response': response},
      );
      
      return ReviewModel.fromJson(apiResponse.data['data']);
    } catch (e) {
      throw Exception('Impossible de répondre à cet avis: $e');
    }
  }
  
  /// Récupère les statistiques d'avis pour une résidence
  /// 
  /// [residenceId] : ID de la résidence
  Future<Map<String, dynamic>> getReviewStats(String residenceId) async {
    try {
      final response = await _apiService.get('/api/reviews/stats/$residenceId');
      
      return response.data['stats'] ?? {};
    } catch (e) {
      throw Exception('Impossible de récupérer les statistiques d\'avis: $e');
    }
  }
  
  /// Signale un avis inapproprié
  /// 
  /// [reviewId] : ID de l'avis à signaler
  /// [reason] : Raison du signalement
  Future<void> reportReview(String reviewId, String reason) async {
    try {
      await _apiService.post(
        '/api/reviews/$reviewId/report',
        data: {'reason': reason},
      );
    } catch (e) {
      throw Exception('Impossible de signaler cet avis: $e');
    }
  }
  
  /// Récupère les avis les plus récents pour les résidences du partenaire
  /// 
  /// [limit] : Nombre d'avis à récupérer
  Future<List<ReviewModel>> getRecentPartnerReviews({int limit = 5}) async {
    try {
      final response = await _apiService.get(
        '/api/reviews/partner/recent',
        queryParameters: {
          'limit': limit.toString(),
        },
      );
      
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => ReviewModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Impossible de récupérer les avis récents: $e');
    }
  }
  
  /// Récupère le nombre total d'avis pour les résidences du partenaire
  Future<int> getTotalPartnerReviewsCount() async {
    try {
      final response = await _apiService.get('/api/reviews/partner/count');
      
      return response.data['count'] ?? 0;
    } catch (e) {
      return 0; // En cas d'erreur, retourner 0
    }
  }
  
  /// Récupère la note moyenne globale pour les résidences du partenaire
  Future<double> getAveragePartnerRating() async {
    try {
      final response = await _apiService.get('/api/reviews/partner/average');
      
      return response.data['average']?.toDouble() ?? 0.0;
    } catch (e) {
      return 0.0; // En cas d'erreur, retourner 0
    }
  }
}
