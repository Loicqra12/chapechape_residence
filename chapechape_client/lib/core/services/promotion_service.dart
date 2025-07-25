import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/promotion_model.dart';
import 'api_service.dart';
import 'cache_service.dart';
import 'residence_service.dart';

class PromotionService {
  final ApiService _apiService;
  final CacheService _cacheService;
  final ResidenceService _residenceService;
  static PromotionService? _instance;

  PromotionService._({
    required ApiService apiService,
    required CacheService cacheService,
    required ResidenceService residenceService,
  }) : 
    _apiService = apiService,
    _cacheService = cacheService,
    _residenceService = residenceService;

  static Future<PromotionService> initialize() async {
    if (_instance != null) return _instance!;

    // Initialiser les services requis
    final apiService = await ApiService.initialize();
    final cacheService = CacheService.getInstance();
    final residenceService = await ResidenceService.initialize();
    
    // S'assurer que CacheService est initialisé
    await cacheService.ensureInitialized();

    final instance = PromotionService._(
      apiService: apiService,
      cacheService: cacheService,
      residenceService: residenceService,
    );
    _instance = instance;
    return instance;
  }

  /// Récupère toutes les promotions actives
  Future<List<Promotion>> getActivePromotions({bool forceRefresh = false}) async {
    final cacheKey = 'promotions_active';
    
    try {
      // Vérifier si on a des données en cache
      if (!forceRefresh) {
        final cachedData = await _cacheService.get(cacheKey);
        if (cachedData != null && cachedData is List) {
          return List<Promotion>.from(
            cachedData.map((item) => Promotion.fromJson(item))
          );
        }
      }
      
      // Sinon, récupérer les données
      try {
        final response = await _apiService.get('/promotions/active');
        
        final promotions = (response.data['data'] as List)
            .map((json) => Promotion.fromJson(json))
            .toList();
            
        // Mettre en cache pour 15 minutes
        await _cacheService.put(cacheKey, 
            promotions.map((p) => p.toJson()).toList(), 
            expiryInMinutes: 15);
        
        return promotions;
      } on DioException catch (e) {
        // Si l'API n'est pas encore disponible, retourner des données fictives
        if (e.response?.statusCode == 404 || e.type == DioExceptionType.connectionTimeout) {
          debugPrint('API des promotions non disponible, utilisation de données fictives');
          final mockData = await _getMockPromotions();
          await _cacheService.put(cacheKey, 
              mockData.map((p) => p.toJson()).toList(), 
              expiryInMinutes: 60);
          return mockData;
        }
        
        rethrow;
      }
    } catch (e) {
      // En cas d'erreur imprévue, retourner une liste vide et logger l'erreur
      debugPrint('Erreur lors de la récupération des promotions actives: $e');
      return [];
    }
  }

  /// Récupère les promotions exclusives
  Future<List<Promotion>> getExclusivePromotions({bool forceRefresh = false}) async {
    final cacheKey = 'promotions_exclusive';
    
    try {
      // Vérifier si on a des données en cache
      if (!forceRefresh) {
        final cachedData = await _cacheService.get(cacheKey);
        if (cachedData != null && cachedData is List) {
          return List<Promotion>.from(
            cachedData.map((item) => Promotion.fromJson(item))
          );
        }
      }
      
      // Sinon, récupérer les données
      try {
        final response = await _apiService.get('/promotions/exclusive');
        
        final promotions = (response.data['data'] as List)
            .map((json) => Promotion.fromJson(json))
            .toList();
            
        // Mettre en cache pour 30 minutes
        await _cacheService.put(cacheKey, 
            promotions.map((p) => p.toJson()).toList(), 
            expiryInMinutes: 30);
        
        return promotions;
      } on DioException catch (e) {
        // Si l'API n'est pas encore disponible, filtrer les données fictives
        if (e.response?.statusCode == 404 || e.type == DioExceptionType.connectionTimeout) {
          debugPrint('API des promotions exclusives non disponible, utilisation de données fictives');
          final allPromotions = await _getMockPromotions();
          final exclusivePromotions = allPromotions.where((p) => p.isExclusive).toList();
          await _cacheService.put(cacheKey, 
              exclusivePromotions.map((p) => p.toJson()).toList(), 
              expiryInMinutes: 60);
          return exclusivePromotions;
        }
        
        rethrow;
      }
    } catch (e) {
      // En cas d'erreur imprévue, retourner une liste vide et logger l'erreur
      debugPrint('Erreur lors de la récupération des promotions exclusives: $e');
      return [];
    }
  }

  /// Récupère les promotions pour une résidence spécifique
  Future<List<Promotion>> getPromotionsForResidence(String residenceId, {bool forceRefresh = false}) async {
    final cacheKey = 'promotions_residence_$residenceId';
    
    try {
      // Vérifier si on a des données en cache
      if (!forceRefresh) {
        final cachedData = await _cacheService.get(cacheKey);
        if (cachedData != null && cachedData is List) {
          return List<Promotion>.from(
            cachedData.map((item) => Promotion.fromJson(item))
          );
        }
      }
      
      // Sinon, récupérer les données
      try {
        final response = await _apiService.get('/promotions/residence/$residenceId');
        
        final promotions = (response.data['data'] as List)
            .map((json) => Promotion.fromJson(json))
            .toList();
            
        // Mettre en cache pour 30 minutes
        await _cacheService.put(cacheKey, 
            promotions.map((p) => p.toJson()).toList(), 
            expiryInMinutes: 30);
        
        return promotions;
      } on DioException catch (e) {
        // Si l'API n'est pas encore disponible, filtrer les données fictives
        if (e.response?.statusCode == 404 || e.type == DioExceptionType.connectionTimeout) {
          debugPrint('API des promotions par résidence non disponible, utilisation de données fictives');
          final allPromotions = await _getMockPromotions();
          final residencePromotions = allPromotions.where((p) => p.residenceId == residenceId).toList();
          await _cacheService.put(cacheKey, 
              residencePromotions.map((p) => p.toJson()).toList(), 
              expiryInMinutes: 60);
          return residencePromotions;
        }
        
        rethrow;
      }
    } catch (e) {
      // En cas d'erreur imprévue, retourner une liste vide et logger l'erreur
      debugPrint('Erreur lors de la récupération des promotions pour la résidence $residenceId: $e');
      return [];
    }
  }

  /// Récupère les détails complets d'une promotion, incluant la résidence associée
  Future<Promotion> getPromotionDetails(String promotionId, {bool forceRefresh = false}) async {
    final cacheKey = 'promotion_details_$promotionId';
    
    try {
      // Vérifier si on a des données en cache
      if (!forceRefresh) {
        final cachedData = await _cacheService.get(cacheKey);
        if (cachedData != null) {
          return Promotion.fromJson(cachedData);
        }
      }
      
      // Sinon, récupérer les données
      try {
        final response = await _apiService.get('/promotions/$promotionId');
        final promotionData = response.data;
        
        // Récupérer la résidence associée
        final residenceId = promotionData['residenceId'];
        final residence = await _residenceService.getResidenceById(residenceId);
        
        // Construire l'objet promotion avec la résidence
        promotionData['residence'] = residence?.toJson();
        final promotion = Promotion.fromJson(promotionData);
        
        // Mettre en cache pour 30 minutes
        await _cacheService.put(cacheKey, promotion.toJson(), expiryInMinutes: 30);
        
        return promotion;
      } on DioException catch (e) {
        // Si l'API n'est pas encore disponible, rechercher dans les données fictives
        if (e.response?.statusCode == 404 || e.type == DioExceptionType.connectionTimeout) {
          debugPrint('API des détails de promotion non disponible, utilisation de données fictives');
          final allPromotions = await _getMockPromotions();
          
          try {
            final promotion = allPromotions.firstWhere(
              (p) => p.id == promotionId,
            );
            
            // Récupérer la résidence associée
            final residence = await _residenceService.getResidenceById(promotion.residenceId);
            final completePromotion = promotion.copyWith(residence: residence);
            
            await _cacheService.put(cacheKey, completePromotion.toJson(), expiryInMinutes: 60);
            return completePromotion;
          } catch (e) {
            throw Exception('Promotion non trouvée');
          }
        }
        
        rethrow;
      }
    } catch (e) {
      // En cas d'erreur imprévue, créer une promotion par défaut et logger l'erreur
      debugPrint('Erreur lors de la récupération des détails de la promotion $promotionId: $e');
      
      // Créer une promotion factice avec les champs requis
      return Promotion(
        id: 'error-$promotionId',
        title: 'Promotion non disponible',
        description: 'Impossible de charger les détails de cette promotion. Veuillez réessayer plus tard.',
        discountPercentage: 0,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 1)),
        imageUrl: 'assets/images/placeholders/promotion.jpg',
        residenceId: '',
      );
    }
  }

  /// Génère des données fictives pour le développement et les tests
  Future<List<Promotion>> _getMockPromotions() async {
    // Générer quelques promotions de test
    return [
      Promotion(
        id: 'promo1',
        title: 'Week-end luxueux à -30%',
        description: 'Profitez d\'un séjour de luxe avec une réduction exclusive de 30% sur nos suites premium.',
        discountPercentage: 30,
        discountCode: 'WEEKEND30',
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        imageUrl: 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=800&q=80',
        residenceId: 'res1',
        badge: 'PROMO FLASH',
        isExclusive: true,
        type: PromotionType.flash,
        termsAndConditions: 'Offre valable pour les réservations de plus de 2 nuits, non cumulable avec d\'autres promotions.',
      ),
      Promotion(
        id: 'promo2',
        title: 'Offre Famille - Chambres connectées',
        description: 'Réservez un séjour en famille et profitez de chambres connectées avec réduction de 15% sur la seconde chambre.',
        discountPercentage: 15,
        discountCode: 'FAMILLE15',
        startDate: DateTime.now().subtract(const Duration(days: 10)),
        endDate: DateTime.now().add(const Duration(days: 20)),
        imageUrl: 'https://images.unsplash.com/photo-1612320583354-02dd0cf04612?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=800&q=80',
        residenceId: 'res2',
        badge: 'OFFRE FAMILLE',
        isExclusive: false,
        type: PromotionType.discount,
      ),
      Promotion(
        id: 'promo3',
        title: 'Séjour longue durée -25%',
        description: 'Pour tout séjour de plus de 14 nuits, bénéficiez d\'une remise de 25% sur le prix total de votre réservation.',
        discountPercentage: 25,
        discountCode: 'LONG25',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 30)),
        imageUrl: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=800&q=80',
        residenceId: 'res3',
        badge: null,
        isExclusive: false,
        type: PromotionType.discount,
        termsAndConditions: 'Séjour minimum de 14 nuits. Non cumulable avec d\'autres offres ou promotions en cours.',
      ),
      Promotion(
        id: 'promo4',
        title: 'Offre Dernière Minute',
        description: 'Réservez dans les 24h et économisez 40% sur votre séjour cette semaine. Nombre de chambres limité!',
        discountPercentage: 40,
        discountCode: 'LAST40',
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(hours: 20)),
        imageUrl: 'https://images.unsplash.com/photo-1520250390503-548150dfae19?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=800&q=80',
        residenceId: 'res4',
        badge: 'DERNIÈRE MINUTE',
        isExclusive: true,
        type: PromotionType.flash,
      ),
      Promotion(
        id: 'promo5',
        title: 'Forfait Romance',
        description: 'Séjour romantique incluant petit-déjeuner au lit, bouteille de champagne et late check-out à 15h.',
        discountPercentage: 10,
        discountCode: 'ROMANCE10',
        startDate: DateTime.now().subtract(const Duration(days: 15)),
        endDate: DateTime.now().add(const Duration(days: 45)),
        imageUrl: 'https://images.unsplash.com/photo-1544161513-0179fe746fd5?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=800&q=80',
        residenceId: 'res5',
        badge: 'ROMANCE',
        isExclusive: false,
        type: PromotionType.bundle,
      ),
    ];
  }
}
