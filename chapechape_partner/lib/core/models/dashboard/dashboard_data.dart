class DashboardData {
  final PerformanceStats performance;
  final RevenueStats revenue;
  final GeneralStats stats;

  DashboardData({
    required this.performance,
    required this.revenue,
    required this.stats,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      performance: PerformanceStats.fromJson(json['performance'] ?? {}),
      revenue: RevenueStats.fromJson(json['revenue'] ?? {}),
      stats: GeneralStats.fromJson(json['stats'] ?? {}),
    );
  }
}

class PerformanceStats {
  final int totalResidences;
  final int totalReservations;
  final double occupancyRate;

  PerformanceStats({
    required this.totalResidences,
    required this.totalReservations,
    required this.occupancyRate,
  });

  factory PerformanceStats.fromJson(Map<String, dynamic> json) {
    return PerformanceStats(
      totalResidences: json['total_residences'] ?? 0,
      totalReservations: json['total_reservations'] ?? 0,
      occupancyRate: (json['occupancy_rate'] ?? 0).toDouble(),
    );
  }
}

class RevenueStats {
  final double totalRevenue;
  final double averageDailyRevenue;
  final List<RevenuePoint> revenueHistory;

  RevenueStats({
    required this.totalRevenue,
    required this.averageDailyRevenue,
    required this.revenueHistory,
  });

  factory RevenueStats.fromJson(Map<String, dynamic> json) {
    final historyList = (json['revenue_history'] as List?)?.map(
          (point) => RevenuePoint.fromJson(point),
        ).toList() ??
        [];

    return RevenueStats(
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      averageDailyRevenue: (json['average_daily_revenue'] ?? 0).toDouble(),
      revenueHistory: historyList,
    );
  }
}

class RevenuePoint {
  final DateTime date;
  final double amount;

  RevenuePoint({
    required this.date,
    required this.amount,
  });

  factory RevenuePoint.fromJson(Map<String, dynamic> json) {
    return RevenuePoint(
      date: DateTime.parse(json['date'] ?? ''),
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}

class GeneralStats {
  final double responseRate;
  final int averageResponseTime;
  final double rating;

  GeneralStats({
    required this.responseRate,
    required this.averageResponseTime,
    required this.rating,
  });

  factory GeneralStats.fromJson(Map<String, dynamic> json) {
    return GeneralStats(
      responseRate: (json['response_rate'] ?? 0).toDouble(),
      averageResponseTime: json['average_response_time'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
    );
  }
}
