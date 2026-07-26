import 'package:chapechape_partner/core/utils/app_logger.dart';
class DashboardData {
  final PerformanceStats performance;
  final RevenueStats revenue;
  final GeneralStats stats;
  final RealtimeStats realtime;

  DashboardData({
    required this.performance,
    required this.revenue,
    required this.stats,
    required this.realtime,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    try {
      return DashboardData(
        performance: PerformanceStats.fromJson(json['performance'] ?? {}),
        revenue: RevenueStats.fromJson(json['revenue'] ?? {}),
        stats: GeneralStats.fromJson(json['stats'] ?? {}),
        realtime: RealtimeStats.fromJson(json['realtime'] ?? {}),
      );
    } catch (e) {
      AppLogger.d('❌ Erreur lors de la conversion du DashboardData: $e');
      return DashboardData.empty();
    }
  }
  
  factory DashboardData.empty() {
    return DashboardData(
      performance: PerformanceStats.empty(),
      revenue: RevenueStats.empty(),
      stats: GeneralStats.empty(),
      realtime: RealtimeStats.empty(),
    );
  }
  
  DashboardData copyWith({
    PerformanceStats? performance,
    RevenueStats? revenue,
    GeneralStats? stats,
    RealtimeStats? realtime,
  }) {
    return DashboardData(
      performance: performance ?? this.performance,
      revenue: revenue ?? this.revenue,
      stats: stats ?? this.stats,
      realtime: realtime ?? this.realtime,
    );
  }
}

class PerformanceStats {
  final int totalResidences;
  final int totalReservations;
  final double occupancyRate;
  final int pendingReviews;
  final int newMessages;

  PerformanceStats({
    required this.totalResidences,
    required this.totalReservations,
    required this.occupancyRate,
    required this.pendingReviews,
    required this.newMessages,
  });

  factory PerformanceStats.fromJson(Map<String, dynamic> json) {
    return PerformanceStats(
      totalResidences: _parseIntSafely(json['total_residences']),
      totalReservations: _parseIntSafely(json['total_reservations']),
      occupancyRate: _parseDoubleSafely(json['occupancy_rate']),
      pendingReviews: _parseIntSafely(json['pending_reviews']),
      newMessages: _parseIntSafely(json['new_messages']),
    );
  }
  
  factory PerformanceStats.empty() {
    return PerformanceStats(
      totalResidences: 0,
      totalReservations: 0,
      occupancyRate: 0.0,
      pendingReviews: 0,
      newMessages: 0,
    );
  }
}

// Méthode utilitaire pour convertir en sécurité les valeurs numériques
int _parseIntSafely(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    try {
      return int.parse(value);
    } catch (e) {
      return 0;
    }
  }
  return 0;
}

// Méthode utilitaire pour convertir en sécurité les valeurs décimales
double _parseDoubleSafely(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    try {
      return double.parse(value);
    } catch (e) {
      return 0.0;
    }
  }
  return 0.0;
}

class RevenueStats {
  final double totalRevenue;
  final double dailyRevenue;
  final double weeklyRevenue;
  final double monthlyRevenue;
  final double revenueGrowth;
  final List<RevenuePoint> revenueHistory;
  final List<BestPerformingResidence> bestResidences;
  final Map<String, CategoryRevenue> revenueByCategory;

  RevenueStats({
    required this.totalRevenue,
    required this.dailyRevenue,
    required this.weeklyRevenue,
    required this.monthlyRevenue,
    required this.revenueGrowth,
    required this.revenueHistory,
    required this.bestResidences,
    required this.revenueByCategory,
  });

  factory RevenueStats.fromJson(Map<String, dynamic> json) {
    final historyList = (json['revenue_history'] as List?)?.map(
          (point) => RevenuePoint.fromJson(point),
        ).toList() ??
        [];

    final bestResidencesList = (json['best_performing_residences'] as List?)?.map(
          (residence) => BestPerformingResidence.fromJson(residence),
        ).toList() ??
        [];

    final categoryMap = (json['revenue_by_category'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, CategoryRevenue.fromJson(value)),
        ) ??
        {};

    return RevenueStats(
      totalRevenue: _parseDoubleSafely(json['total_revenue']),
      dailyRevenue: _parseDoubleSafely(json['daily_revenue']),
      weeklyRevenue: _parseDoubleSafely(json['weekly_revenue']),
      monthlyRevenue: _parseDoubleSafely(json['monthly_revenue']),
      revenueGrowth: _parseDoubleSafely(json['revenue_growth']),
      revenueHistory: historyList,
      bestResidences: bestResidencesList,
      revenueByCategory: categoryMap,
    );
  }
  
  factory RevenueStats.empty() {
    return RevenueStats(
      totalRevenue: 0.0,
      dailyRevenue: 0.0,
      weeklyRevenue: 0.0,
      monthlyRevenue: 0.0,
      revenueGrowth: 0.0,
      revenueHistory: [],
      bestResidences: [],
      revenueByCategory: {},
    );
  }
  
  RevenueStats copyWith({
    double? totalRevenue,
    double? dailyRevenue,
    double? weeklyRevenue,
    double? monthlyRevenue,
    double? revenueGrowth,
    List<RevenuePoint>? revenueHistory,
    List<BestPerformingResidence>? bestResidences,
    Map<String, CategoryRevenue>? revenueByCategory,
  }) {
    return RevenueStats(
      totalRevenue: totalRevenue ?? this.totalRevenue,
      dailyRevenue: dailyRevenue ?? this.dailyRevenue,
      weeklyRevenue: weeklyRevenue ?? this.weeklyRevenue,
      monthlyRevenue: monthlyRevenue ?? this.monthlyRevenue,
      revenueGrowth: revenueGrowth ?? this.revenueGrowth,
      revenueHistory: revenueHistory ?? this.revenueHistory,
      bestResidences: bestResidences ?? this.bestResidences,
      revenueByCategory: revenueByCategory ?? this.revenueByCategory,
    );
  }
}

class BestPerformingResidence {
  final String id;
  final String name;
  final String? imageUrl;
  final double revenue;
  final int bookings;

  BestPerformingResidence({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.revenue,
    required this.bookings,
  });

  factory BestPerformingResidence.fromJson(Map<String, dynamic> json) {
    return BestPerformingResidence(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'],
      revenue: _parseDoubleSafely(json['revenue']),
      bookings: _parseIntSafely(json['bookings']),
    );
  }
  
  factory BestPerformingResidence.empty() {
    return BestPerformingResidence(
      id: '',
      name: '',
      imageUrl: null,
      revenue: 0.0,
      bookings: 0,
    );
  }
}

class CategoryRevenue {
  final double revenue;
  final int count;

  CategoryRevenue({
    required this.revenue,
    required this.count,
  });

  factory CategoryRevenue.fromJson(Map<String, dynamic> json) {
    return CategoryRevenue(
      revenue: _parseDoubleSafely(json['revenue']),
      count: _parseIntSafely(json['count']),
    );
  }
  
  factory CategoryRevenue.empty() {
    return CategoryRevenue(
      revenue: 0.0,
      count: 0,
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
      amount: _parseDoubleSafely(json['amount']),
    );
  }
  
  factory RevenuePoint.empty() {
    return RevenuePoint(
      date: DateTime.now(),
      amount: 0.0,
    );
  }
}

class GeneralStats {
  final double responseRate;
  final int averageResponseTime;
  final double rating;
  final Map<String, int> bookingsByStatus;

  GeneralStats({
    required this.responseRate,
    required this.averageResponseTime,
    required this.rating,
    required this.bookingsByStatus,
  });

  factory GeneralStats.fromJson(Map<String, dynamic> json) {
    final bookingsMap = (json['bookings'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, _parseIntSafely(value)),
        ) ??
        {};

    return GeneralStats(
      responseRate: _parseDoubleSafely(json['response_rate']),
      averageResponseTime: _parseIntSafely(json['average_response_time']),
      rating: _parseDoubleSafely(json['rating']),
      bookingsByStatus: bookingsMap,
    );
  }
  
  factory GeneralStats.empty() {
    return GeneralStats(
      responseRate: 0.0,
      averageResponseTime: 0,
      rating: 0.0,
      bookingsByStatus: {
        'pending': 0,
        'confirmed': 0,
        'completed': 0,
        'cancelled': 0,
      },
    );
  }
}

class RealtimeStats {
  final int activeBookings;
  final int pendingRequests;
  final List<TodayVisit> todayVisits;
  final List<RecentActivity> recentActivities;

  RealtimeStats({
    required this.activeBookings,
    required this.pendingRequests,
    required this.todayVisits,
    required this.recentActivities,
  });

  factory RealtimeStats.fromJson(Map<String, dynamic> json) {
    final visitsList = (json['today_visits'] as List?)?.map(
          (visit) => TodayVisit.fromJson(visit),
        ).toList() ??
        [];

    final activitiesList = (json['recent_activities'] as List?)?.map(
          (activity) => RecentActivity.fromJson(activity),
        ).toList() ??
        [];

    return RealtimeStats(
      activeBookings: _parseIntSafely(json['active_bookings']),
      pendingRequests: _parseIntSafely(json['pending_requests']),
      todayVisits: visitsList,
      recentActivities: activitiesList,
    );
  }
  
  factory RealtimeStats.empty() {
    return RealtimeStats(
      activeBookings: 0,
      pendingRequests: 0,
      todayVisits: [],
      recentActivities: [],
    );
  }
}

class TodayVisit {
  final String id;
  final String time;
  final ClientInfo client;
  final ResidenceInfo residence;
  final String status;

  TodayVisit({
    required this.id,
    required this.time,
    required this.client,
    required this.residence,
    required this.status,
  });

  factory TodayVisit.fromJson(Map<String, dynamic> json) {
    return TodayVisit(
      id: json['id'] ?? '',
      time: json['time'] ?? '',
      client: ClientInfo.fromJson(json['client'] ?? {}),
      residence: ResidenceInfo.fromJson(json['residence'] ?? {}),
      status: json['status'] ?? '',
    );
  }
  
  factory TodayVisit.empty() {
    return TodayVisit(
      id: '',
      time: '',
      client: ClientInfo.empty(),
      residence: ResidenceInfo.empty(),
      status: '',
    );
  }
}

class ClientInfo {
  final String id;
  final String name;
  final String? avatar;

  ClientInfo({
    required this.id,
    required this.name,
    this.avatar,
  });

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
    );
  }
  
  factory ClientInfo.empty() {
    return ClientInfo(
      id: '',
      name: '',
      avatar: null,
    );
  }
}

class ResidenceInfo {
  final String id;
  final String name;
  final String? imageUrl;

  ResidenceInfo({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  factory ResidenceInfo.fromJson(Map<String, dynamic> json) {
    return ResidenceInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'],
    );
  }
  
  factory ResidenceInfo.empty() {
    return ResidenceInfo(
      id: '',
      name: '',
      imageUrl: null,
    );
  }
}

class RecentActivity {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  RecentActivity({
    required this.type,
    required this.data,
    required this.timestamp,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      type: json['type'] ?? '',
      data: json['data'] ?? {},
      timestamp: DateTime.parse(json['timestamp'] ?? ''),
    );
  }
  
  factory RecentActivity.empty() {
    return RecentActivity(
      type: '',
      data: {},
      timestamp: DateTime.now(),
    );
  }
}

class PartnerStats {
  final int totalResidences;
  final Map<String, int> bookingsByStatus;  // pending, confirmed, cancelled, completed, refunded
  final double averageRating;
  final double responseRate;
  final double occupancyRate;
  final double monthlyRevenue;

  PartnerStats({
    required this.totalResidences,
    required this.bookingsByStatus,
    required this.averageRating,
    required this.responseRate,
    required this.occupancyRate,
    required this.monthlyRevenue,
  });

  factory PartnerStats.fromJson(Map<String, dynamic> json) {
    return PartnerStats(
      totalResidences: _parseIntSafely(json['total_residences']),
      bookingsByStatus: Map<String, int>.from(json['bookings_by_status'] ?? {}),
      averageRating: _parseDoubleSafely(json['average_rating']),
      responseRate: _parseDoubleSafely(json['response_rate']),
      occupancyRate: _parseDoubleSafely(json['occupancy_rate']),
      monthlyRevenue: _parseDoubleSafely(json['monthly_revenue']),
    );
  }
  
  factory PartnerStats.empty() {
    return PartnerStats(
      totalResidences: 0,
      bookingsByStatus: {
        'pending': 0,
        'confirmed': 0,
        'completed': 0,
        'cancelled': 0,
        'refunded': 0,
      },
      averageRating: 0.0,
      responseRate: 0.0,
      occupancyRate: 0.0,
      monthlyRevenue: 0.0,
    );
  }
}

class ResidenceStats {
  final String id;
  final String title;
  final String imageUrl;
  final String status;
  final String displayAddress;
  final int totalBookings;
  final double revenue;
  final double occupancyRate;
  final Map<String, int> bookingsByStatus;

  ResidenceStats({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.status,
    required this.displayAddress,
    required this.totalBookings,
    required this.revenue,
    required this.occupancyRate,
    required this.bookingsByStatus,
  });

  factory ResidenceStats.fromJson(Map<String, dynamic> json) {
    final residence = json['residence'] ?? {};
    final location = residence['location'] ?? {};
    
    return ResidenceStats(
      id: residence['id'] ?? '',
      title: residence['name'] ?? '',
      imageUrl: (residence['images'] as List?)?.firstWhere((img) => img != null, orElse: () => '') ?? '',
      status: residence['is_available'] == true ? 'available' : 'unavailable',
      displayAddress: location['formatted_address'] ?? '',
      totalBookings: _parseIntSafely(json['total_bookings']),
      revenue: _parseDoubleSafely(json['revenue']),
      occupancyRate: _parseDoubleSafely(json['occupancy_rate']),
      bookingsByStatus: Map<String, int>.from(json['bookings_by_status'] ?? {}),
    );
  }
  
  factory ResidenceStats.empty() {
    return ResidenceStats(
      id: '',
      title: '',
      imageUrl: '',
      status: 'unavailable',
      displayAddress: '',
      totalBookings: 0,
      revenue: 0.0,
      occupancyRate: 0.0,
      bookingsByStatus: {
        'pending': 0,
        'confirmed': 0,
        'completed': 0,
        'cancelled': 0,
      },
    );
  }
}

class TrendData {
  final String period;
  final List<TrendPoint> points;
  final double growth;

  TrendData({
    required this.period,
    required this.points,
    required this.growth,
  });

  factory TrendData.fromJson(Map<String, dynamic> json) {
    final pointsList = (json['points'] as List?)?.map(
      (point) => TrendPoint.fromJson(point),
    ).toList() ?? [];

    return TrendData(
      period: json['period'] ?? 'monthly',
      points: pointsList,
      growth: _parseDoubleSafely(json['growth']),
    );
  }
  
  factory TrendData.empty() {
    return TrendData(
      period: 'monthly',
      points: [],
      growth: 0.0,
    );
  }
}

class TrendPoint {
  final DateTime date;
  final int bookings;
  final double revenue;
  final double occupancyRate;

  TrendPoint({
    required this.date,
    required this.bookings,
    required this.revenue,
    required this.occupancyRate,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: DateTime.parse(json['date'] ?? ''),
      bookings: _parseIntSafely(json['bookings']),
      revenue: _parseDoubleSafely(json['revenue']),
      occupancyRate: _parseDoubleSafely(json['occupancy_rate']),
    );
  }
  
  factory TrendPoint.empty() {
    return TrendPoint(
      date: DateTime.now(),
      bookings: 0,
      revenue: 0.0,
      occupancyRate: 0.0,
    );
  }
}

class EarningsData {
  final List<EarningPeriod> earnings;
  final double totalEarnings;
  final double averagePerPeriod;
  final double growth;

  EarningsData({
    required this.earnings,
    required this.totalEarnings,
    required this.averagePerPeriod,
    required this.growth,
  });

  factory EarningsData.fromJson(dynamic json) {
    // Backend historique renvoyait parfois une List brute
    if (json is List) {
      final periods = json
          .whereType<Map>()
          .map((e) => EarningPeriod.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final total = periods.fold<double>(0, (s, p) => s + p.amount);
      return EarningsData(
        earnings: periods,
        totalEarnings: total,
        averagePerPeriod: periods.isEmpty ? 0 : total / periods.length,
        growth: 0,
      );
    }

    final map = json is Map<String, dynamic>
        ? json
        : (json is Map ? Map<String, dynamic>.from(json) : <String, dynamic>{});

    final earningsList = (map['earnings'] as List?)?.map(
      (period) => EarningPeriod.fromJson(
        period is Map<String, dynamic>
            ? period
            : Map<String, dynamic>.from(period as Map),
      ),
    ).toList() ?? [];

    return EarningsData(
      earnings: earningsList,
      totalEarnings: _parseDoubleSafely(map['total_earnings']),
      averagePerPeriod: _parseDoubleSafely(map['average_per_period']),
      growth: _parseDoubleSafely(map['growth']),
    );
  }
  
  factory EarningsData.empty() {
    return EarningsData(
      earnings: [],
      totalEarnings: 0.0,
      averagePerPeriod: 0.0,
      growth: 0.0,
    );
  }
}

class EarningPeriod {
  final DateTime date;
  final double amount;
  final int bookingsCount;

  EarningPeriod({
    required this.date,
    required this.amount,
    required this.bookingsCount,
  });

  factory EarningPeriod.fromJson(Map<String, dynamic> json) {
    DateTime date;
    if (json['date'] != null) {
      date = DateTime.tryParse(json['date'].toString()) ?? DateTime.now();
    } else if (json['_id'] is Map) {
      final id = Map<String, dynamic>.from(json['_id'] as Map);
      date = DateTime(
        (id['year'] as num?)?.toInt() ?? DateTime.now().year,
        (id['month'] as num?)?.toInt() ?? 1,
      );
    } else {
      date = DateTime.now();
    }

    return EarningPeriod(
      date: date,
      amount: _parseDoubleSafely(json['amount'] ?? json['totalEarnings']),
      bookingsCount: _parseIntSafely(json['count']),
    );
  }
  
  factory EarningPeriod.empty() {
    return EarningPeriod(
      date: DateTime.now(),
      amount: 0.0,
      bookingsCount: 0,
    );
  }
}
