import 'package:dio/dio.dart';
import '../../models/pricing/pricing_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// Service pour l'intégration du système de pricing dynamique
class PricingService {
  final ApiService _apiService;

  PricingService() : _apiService = ApiService();
  
  // Alternative constructor
  PricingService.withApiService({required ApiService apiService}) 
      : _apiService = apiService;
  
  // Getter pour accéder au Dio si nécessaire
  Dio get dio => _apiService.dio;

  /// Calculer le pricing optimal pour un prix de base donné
  /// 
  /// [basePrice] - Prix de base de la résidence
  /// [paymentMethod] - Méthode de paiement optionnelle (si null, calcule l'optimal)
  /// [payoutMethod] - Méthode de payout optionnelle
  Future<PricingModel> calculateOptimalPricing({
    required double basePrice,
    String? paymentMethod,
    String? payoutMethod,
  }) async {
    try {
      final response = await _apiService.post(
        '/pricing/calculate',
        data: {
          'basePrice': basePrice,
          if (paymentMethod != null) 'paymentMethod': paymentMethod,
          if (payoutMethod != null) 'payoutMethod': payoutMethod,
        },
      );
      
      return PricingModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Impossible de calculer le pricing optimal: $e');
    }
  }

  /// Obtenir toutes les méthodes de paiement ordonnées par coût
  Future<List<PaymentMethodInfo>> getOptimizedPaymentMethods() async {
    try {
      final response = await _apiService.get('/pricing/payment-methods');
      
      final List methodsList = response.data['data'] as List;
      return methodsList
          .map((method) => PaymentMethodInfo.fromJson(method))
          .toList();
    } catch (e) {
      throw Exception('Impossible de récupérer les méthodes de paiement optimisées: $e');
    }
  }

  /// Analyser les économies potentielles pour un prix donné
  Future<SavingsAnalysis> calculateSavingsAnalysis({
    required double basePrice,
  }) async {
    try {
      final response = await _apiService.get(
        '/pricing/savings-analysis',
        queryParameters: {
          'basePrice': basePrice.toString(),
        },
      );
      
      return SavingsAnalysis.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Impossible d\'analyser les économies: $e');
    }
  }

  /// Obtenir les statistiques de pricing pour le partner connecté
  Future<PricingStats> getPartnerPricingStats() async {
    try {
      // Récupérer l'ID du partner connecté depuis AuthService
      final partnerId = await _getCurrentPartnerId();
      final response = await _apiService.get('/pricing/partner/$partnerId/stats');
      
      return PricingStats.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Impossible de récupérer les statistiques de pricing: $e');
    }
  }

  /// Récupère l'ID du partner connecté
  Future<String> _getCurrentPartnerId() async {
    try {
      final AuthService authService = AuthService(_apiService.dio);
      final partner = await authService.getProfile();
      return partner.id;
    } catch (e) {
      throw Exception('Impossible de récupérer l\'ID du partner connecté: $e');
    }
  }

  /// Obtenir les statistiques de pricing pour un partner spécifique (admin only)
  Future<PricingStats> getPartnerPricingStatsById(String partnerId) async {
    try {
      final response = await _apiService.get('/pricing/partner/$partnerId/stats');
      
      return PricingStats.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Impossible de récupérer les statistiques de pricing pour le partner $partnerId: $e');
    }
  }

  /// Valider une configuration de pricing (admin only)
  Future<PricingModel> validatePricingConfig({
    required double basePrice,
    required String paymentMethod,
  }) async {
    try {
      final response = await _apiService.post(
        '/pricing/validate',
        data: {
          'basePrice': basePrice,
          'paymentMethod': paymentMethod,
        },
      );
      
      return PricingModel.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Impossible de valider la configuration pricing: $e');
    }
  }

  /// Simuler l'impact d'un changement de tarification (admin only)
  Future<PricingSimulation> simulatePricingChanges({
    required List<double> currentPrices,
    double? newCommissionRate,
  }) async {
    try {
      final response = await _apiService.post(
        '/pricing/simulate',
        data: {
          'currentPrices': currentPrices,
          if (newCommissionRate != null) 'newCommissionRate': newCommissionRate,
        },
      );
      
      return PricingSimulation.fromJson(response.data['data']);
    } catch (e) {
      throw Exception('Impossible de simuler les changements de pricing: $e');
    }
  }

  /// Calculer le pricing pour plusieurs méthodes à la fois
  Future<Map<String, PricingModel>> calculateMultiMethodPricing({
    required double basePrice,
    List<String>? methods,
  }) async {
    try {
      final targetMethods = methods ?? [
        'mtn_money',
        'orange_money', 
        'wave',
        'moov_money',
        'card'
      ];
      
      final Map<String, PricingModel> results = {};
      
      // Calculer en parallèle pour toutes les méthodes
      final futures = targetMethods.map((method) async {
        final pricing = await calculateOptimalPricing(
          basePrice: basePrice,
          paymentMethod: method,
        );
        return MapEntry(method, pricing);
      });
      
      final entries = await Future.wait(futures);
      results.addEntries(entries);
      
      return results;
    } catch (e) {
      throw Exception('Impossible de calculer le pricing multi-méthodes: $e');
    }
  }

  /// Obtenir la méthode de paiement recommandée pour un prix donné
  Future<String> getRecommendedPaymentMethod(double basePrice) async {
    try {
      final pricing = await calculateOptimalPricing(basePrice: basePrice);
      return pricing.paymentMethod;
    } catch (e) {
      throw Exception('Impossible de déterminer la méthode recommandée: $e');
    }
  }

  /// Calculer l'économie réalisée en utilisant la méthode optimale vs une méthode donnée
  Future<double> calculateSavingsVsMethod({
    required double basePrice,
    required String comparisonMethod,
  }) async {
    try {
      final optimal = await calculateOptimalPricing(basePrice: basePrice);
      final comparison = await calculateOptimalPricing(
        basePrice: basePrice,
        paymentMethod: comparisonMethod,
      );
      
      return comparison.totalClientPrice - optimal.totalClientPrice;
    } catch (e) {
      throw Exception('Impossible de calculer les économies comparatives: $e');
    }
  }
}

/// Résultat de simulation de pricing
class PricingSimulation {
  final List<SimulationItem> simulations;
  final SimulationSummary summary;

  const PricingSimulation({
    required this.simulations,
    required this.summary,
  });

  factory PricingSimulation.fromJson(Map<String, dynamic> json) {
    return PricingSimulation(
      simulations: (json['simulations'] as List)
          .map((item) => SimulationItem.fromJson(item))
          .toList(),
      summary: SimulationSummary.fromJson(json['summary']),
    );
  }
}

/// Item de simulation individuel
class SimulationItem {
  final double basePrice;
  final SimulationPricing current;
  final SimulationPricing optimized;
  final SimulationImprovements improvements;

  const SimulationItem({
    required this.basePrice,
    required this.current,
    required this.optimized,
    required this.improvements,
  });

  factory SimulationItem.fromJson(Map<String, dynamic> json) {
    return SimulationItem(
      basePrice: (json['basePrice'] as num).toDouble(),
      current: SimulationPricing.fromJson(json['current']),
      optimized: SimulationPricing.fromJson(json['optimized']),
      improvements: SimulationImprovements.fromJson(json['improvements']),
    );
  }
}

/// Pricing dans la simulation
class SimulationPricing {
  final double clientPays;
  final double partnerReceives;
  final double chapeChapeRevenue;

  const SimulationPricing({
    required this.clientPays,
    required this.partnerReceives,
    required this.chapeChapeRevenue,
  });

  factory SimulationPricing.fromJson(Map<String, dynamic> json) {
    return SimulationPricing(
      clientPays: (json['clientPays'] as num).toDouble(),
      partnerReceives: (json['partnerReceives'] as num).toDouble(),
      chapeChapeRevenue: (json['chapeChapeRevenue'] as num).toDouble(),
    );
  }
}

/// Améliorations dans la simulation
class SimulationImprovements {
  final double clientSavings;
  final double chapeChapeGain;
  final double partnerImpact;

  const SimulationImprovements({
    required this.clientSavings,
    required this.chapeChapeGain,
    required this.partnerImpact,
  });

  factory SimulationImprovements.fromJson(Map<String, dynamic> json) {
    return SimulationImprovements(
      clientSavings: (json['clientSavings'] as num).toDouble(),
      chapeChapeGain: (json['chapeChapeGain'] as num).toDouble(),
      partnerImpact: (json['partnerImpact'] as num).toDouble(),
    );
  }
}

/// Résumé de la simulation
class SimulationSummary {
  final double totalClientSavings;
  final double totalRevenueGain;
  final double avgOptimization;

  const SimulationSummary({
    required this.totalClientSavings,
    required this.totalRevenueGain,
    required this.avgOptimization,
  });

  factory SimulationSummary.fromJson(Map<String, dynamic> json) {
    return SimulationSummary(
      totalClientSavings: (json['totalClientSavings'] as num).toDouble(),
      totalRevenueGain: (json['totalRevenueGain'] as num).toDouble(),
      avgOptimization: (json['avgOptimization'] as num).toDouble(),
    );
  }
}
