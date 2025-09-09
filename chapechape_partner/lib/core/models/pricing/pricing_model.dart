/// Modèle pour la tarification dynamique ChapeChape
class PricingModel {
  final double basePrice;
  final double totalClientPrice;
  final double partnerNetAmount;
  final double chapeChapeRevenue;
  final String paymentMethod;
  final PricingOptimization? optimization;
  final PricingBreakdown breakdown;

  const PricingModel({
    required this.basePrice,
    required this.totalClientPrice,
    required this.partnerNetAmount,
    required this.chapeChapeRevenue,
    required this.paymentMethod,
    this.optimization,
    required this.breakdown,
  });

  factory PricingModel.fromJson(Map<String, dynamic> json) {
    return PricingModel(
      basePrice: (json['basePrice'] as num).toDouble(),
      totalClientPrice: (json['totalClientPrice'] as num).toDouble(),
      partnerNetAmount: (json['partnerNetAmount'] as num).toDouble(),
      chapeChapeRevenue: (json['chapeChapeRevenue'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      optimization: json['optimization'] != null
          ? PricingOptimization.fromJson(json['optimization'])
          : null,
      breakdown: PricingBreakdown.fromJson(json['breakdown']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'basePrice': basePrice,
      'totalClientPrice': totalClientPrice,
      'partnerNetAmount': partnerNetAmount,
      'chapeChapeRevenue': chapeChapeRevenue,
      'paymentMethod': paymentMethod,
      'optimization': optimization?.toJson(),
      'breakdown': breakdown.toJson(),
    };
  }

  /// Calculer le pourcentage d'économie par rapport au prix le plus cher
  double get savingsPercentage {
    if (optimization?.savingsVsExpensive == null) return 0.0;
    return (optimization!.savingsVsExpensive / totalClientPrice) * 100;
  }

  /// Vérifier si cette méthode est optimisée
  bool get isOptimized => optimization?.isOptimized ?? false;

  /// Obtenir le nom d'affichage de la méthode de paiement
  String get paymentMethodDisplayName {
    switch (paymentMethod) {
      case 'mtn_money':
        return 'MTN Money';
      case 'orange_money':
        return 'Orange Money';
      case 'wave':
        return 'Wave';
      case 'moov_money':
        return 'Moov Money';
      case 'card':
        return 'Carte bancaire';
      default:
        return paymentMethod;
    }
  }

  @override
  String toString() {
    return 'PricingModel(basePrice: $basePrice, totalClientPrice: $totalClientPrice, paymentMethod: $paymentMethod)';
  }
}

/// Informations d'optimisation du pricing
class PricingOptimization {
  final bool isOptimized;
  final double savingsVsExpensive;
  final String? recommendedMethod;
  final String optimizationReason;

  const PricingOptimization({
    required this.isOptimized,
    required this.savingsVsExpensive,
    this.recommendedMethod,
    required this.optimizationReason,
  });

  factory PricingOptimization.fromJson(Map<String, dynamic> json) {
    return PricingOptimization(
      isOptimized: json['isOptimized'] as bool,
      savingsVsExpensive: (json['savingsVsExpensive'] as num).toDouble(),
      recommendedMethod: json['recommendedMethod'] as String?,
      optimizationReason: json['optimizationReason'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isOptimized': isOptimized,
      'savingsVsExpensive': savingsVsExpensive,
      'recommendedMethod': recommendedMethod,
      'optimizationReason': optimizationReason,
    };
  }
}

/// Détail des frais et calculs
class PricingBreakdown {
  final double payinFee;
  final double payoutFee;
  final double serviceFee;
  final double partnerCommission;
  final double totalFees;

  const PricingBreakdown({
    required this.payinFee,
    required this.payoutFee,
    required this.serviceFee,
    required this.partnerCommission,
    required this.totalFees,
  });

  factory PricingBreakdown.fromJson(Map<String, dynamic> json) {
    return PricingBreakdown(
      payinFee: (json['payinFee'] as num).toDouble(),
      payoutFee: (json['payoutFee'] as num).toDouble(),
      serviceFee: (json['serviceFee'] as num).toDouble(),
      partnerCommission: (json['partnerCommission'] as num).toDouble(),
      totalFees: (json['totalFees'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payinFee': payinFee,
      'payoutFee': payoutFee,
      'serviceFee': serviceFee,
      'partnerCommission': partnerCommission,
      'totalFees': totalFees,
    };
  }
}

/// Méthode de paiement avec informations de coût
class PaymentMethodInfo {
  final String method;
  final String displayName;
  final double totalCost;
  final bool isRecommended;
  final int priority;

  const PaymentMethodInfo({
    required this.method,
    required this.displayName,
    required this.totalCost,
    required this.isRecommended,
    required this.priority,
  });

  factory PaymentMethodInfo.fromJson(Map<String, dynamic> json) {
    return PaymentMethodInfo(
      method: json['method'] as String,
      displayName: json['displayName'] as String,
      totalCost: (json['totalCost'] as num).toDouble(),
      isRecommended: json['isRecommended'] as bool,
      priority: json['priority'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'displayName': displayName,
      'totalCost': totalCost,
      'isRecommended': isRecommended,
      'priority': priority,
    };
  }
}

/// Analyse des économies potentielles
class SavingsAnalysis {
  final double basePrice;
  final PaymentMethodInfo cheapestMethod;
  final PaymentMethodInfo mostExpensiveMethod;
  final double maxSavings;
  final double maxSavingsPercentage;
  final List<PricingModel> detailedComparisons;

  const SavingsAnalysis({
    required this.basePrice,
    required this.cheapestMethod,
    required this.mostExpensiveMethod,
    required this.maxSavings,
    required this.maxSavingsPercentage,
    required this.detailedComparisons,
  });

  factory SavingsAnalysis.fromJson(Map<String, dynamic> json) {
    return SavingsAnalysis(
      basePrice: (json['basePrice'] as num).toDouble(),
      cheapestMethod: PaymentMethodInfo.fromJson(json['cheapestMethod']),
      mostExpensiveMethod: PaymentMethodInfo.fromJson(json['mostExpensiveMethod']),
      maxSavings: (json['maxSavings'] as num).toDouble(),
      maxSavingsPercentage: (json['maxSavingsPercentage'] as num).toDouble(),
      detailedComparisons: (json['detailedComparisons'] as Map<String, dynamic>)
          .values
          .map((item) => PricingModel.fromJson(item))
          .toList(),
    );
  }
}

/// Statistiques de pricing pour un partner
class PricingStats {
  final int totalReservations;
  final double totalRevenue;
  final double totalSavings;
  final int optimizationRate;
  final Map<String, MethodStats> methodStats;
  final double avgRevenuePerReservation;

  const PricingStats({
    required this.totalReservations,
    required this.totalRevenue,
    required this.totalSavings,
    required this.optimizationRate,
    required this.methodStats,
    required this.avgRevenuePerReservation,
  });

  factory PricingStats.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> methodStatsJson = json['methodStats'] ?? {};
    final Map<String, MethodStats> methodStats = {};
    
    methodStatsJson.forEach((key, value) {
      methodStats[key] = MethodStats.fromJson(value);
    });

    return PricingStats(
      totalReservations: json['totalReservations'] as int,
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalSavings: (json['totalSavings'] as num).toDouble(),
      optimizationRate: json['optimizationRate'] as int,
      methodStats: methodStats,
      avgRevenuePerReservation: (json['avgRevenuePerReservation'] as num).toDouble(),
    );
  }
}

/// Statistiques par méthode de paiement
class MethodStats {
  final int count;
  final double revenue;

  const MethodStats({
    required this.count,
    required this.revenue,
  });

  factory MethodStats.fromJson(Map<String, dynamic> json) {
    return MethodStats(
      count: json['count'] as int,
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}
