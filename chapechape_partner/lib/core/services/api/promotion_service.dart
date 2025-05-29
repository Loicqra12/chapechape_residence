import 'package:dio/dio.dart';
import '../../models/promotion/promotion_model.dart';
import '../../models/residence/residence.dart';
import 'api_service.dart';

/// Service pour la gestion des promotions et offres spéciales
class PromotionService {
  final ApiService _apiService;
  final Dio _dio;
  
  // Suppression du constructeur problématique qui crée sa propre instance d'ApiService
  // Utilisation uniquement du constructeur qui accepte une instance existante
  PromotionService({required ApiService apiService}) 
      : _apiService = apiService,
        _dio = apiService.dio;
  
  /// Récupère toutes les promotions disponibles
  /// 
  /// [type] : Filtrer par type de promotion
  /// [exclusive] : Filtrer par promotions exclusives uniquement
  /// [residenceId] : Filtrer par ID de résidence
  /// [active] : Filtrer par promotions actives uniquement
  Future<List<PromotionModel>> getPromotions({
    PromotionType? type,
    bool? exclusive,
    String? residenceId,
    bool? active,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      
      if (type != null) {
        queryParams['type'] = type.value;
      }
      
      if (exclusive != null) {
        queryParams['exclusive'] = exclusive.toString();
      }
      
      if (residenceId != null) {
        queryParams['residence'] = residenceId;
      }
      
      if (active != null) {
        queryParams['active'] = active.toString();
      }
      
      // Suppression complète du préfixe pour éviter la duplication avec l'URL de base qui contient déjà /api
      // Suppression du slash initial pour éviter la duplication avec l'URL de base qui contient déjà /api
      // Ajouter un slash après /api pour former /api/promotions
      // Suppression du slash initial pour correspondre à la configuration de l'API
      // Ajouter un slash pour séparer /api et promotions
      // Ajouter /api/ manuellement pour contourner le problème d'URL de base sans slash final
      // Suppression du préfixe /api pour éviter la duplication
      // Utiliser directement Dio comme dans MessageService qui fonctionne
      final response = await _dio.get(
        '/api/promotions',
        queryParameters: queryParams,
      );
      
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => PromotionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Impossible de récupérer les promotions: $e');
    }
  }
  
  /// Récupère les promotions actives uniquement
  Future<List<PromotionModel>> getActivePromotions() async {
    try {
      final response = await _dio.get('/api/promotions/active');
      
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => PromotionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Impossible de récupérer les promotions actives: $e');
    }
  }
  
  /// Récupère les promotions exclusives uniquement
  Future<List<PromotionModel>> getExclusivePromotions() async {
    try {
      final response = await _dio.get('/api/promotions/exclusive');
      
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => PromotionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Impossible de récupérer les promotions exclusives: $e');
    }
  }
  
  /// Récupère les promotions pour une résidence spécifique
  /// 
  /// [residenceId] : ID de la résidence
  Future<List<PromotionModel>> getResidencePromotions(String residenceId) async {
    try {
      final response = await _dio.get('/api/promotions/residence/$residenceId');
      
      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((json) => PromotionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Impossible de récupérer les promotions pour cette résidence: $e');
    }
  }
  
  /// Récupère une promotion spécifique par son ID
  /// 
  /// [promotionId] : ID de la promotion
  Future<PromotionModel> getPromotion(String promotionId) async {
    try {
      final response = await _dio.get('/api/promotions/$promotionId');
      
      return PromotionModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Impossible de récupérer cette promotion: $e');
    }
  }
  
  /// Crée une nouvelle promotion
  /// 
  /// [promotion] : Données de la promotion à créer
  Future<PromotionModel> createPromotion(PromotionModel promotion) async {
    try {
      final response = await _dio.post(
        '/api/promotions',
        data: promotion.toJson(),
      );
      
      return PromotionModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Impossible de créer la promotion: $e');
    }
  }
  
  /// Met à jour une promotion existante
  /// 
  /// [promotionId] : ID de la promotion à mettre à jour
  /// [promotion] : Nouvelles données de la promotion
  Future<PromotionModel> updatePromotion(
    String promotionId, 
    PromotionModel promotion
  ) async {
    try {
      final response = await _dio.put(
        '/api/promotions/$promotionId',
        data: promotion.toJson(),
      );
      
      return PromotionModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Impossible de mettre à jour la promotion: $e');
    }
  }
  
  /// Supprime une promotion
  /// 
  /// [promotionId] : ID de la promotion à supprimer
  Future<void> deletePromotion(String promotionId) async {
    try {
      await _dio.delete('/api/promotions/$promotionId');
    } catch (e) {
      throw Exception('Impossible de supprimer la promotion: $e');
    }
  }
  
  /// Vérifie la validité d'un code promotionnel
  /// 
  /// [code] : Code promotionnel à vérifier
  Future<PromotionModel?> validatePromotionCode(String code) async {
    try {
      final response = await _dio.post(
        '/api/promotions/validate',
        data: {'code': code},
      );
      
      if (response.statusCode == 200) {
        return PromotionModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      return null; // Code invalide ou erreur
    }
  }
}
