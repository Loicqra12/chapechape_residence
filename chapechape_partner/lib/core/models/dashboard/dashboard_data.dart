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
    return DashboardData(
      performance: PerformanceStats.fromJson(json['performance'] ?? {}),
      revenue: RevenueStats.fromJson(json['revenue'] ?? {}),
      stats: GeneralStats.fromJson(json['stats'] ?? {}),
      realtime: RealtimeStats.fromJson(json['realtime'] ?? {}),
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
      totalResidences: json['total_residences'] ?? 0,
      totalReservations: json['total_reservations'] ?? 0,
      occupancyRate: (json['occupancy_rate'] ?? 0).toDouble(),
      pendingReviews: json['pending_reviews'] ?? 0,
      newMessages: json['new_messages'] ?? 0,
    );
  }
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
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      dailyRevenue: (json['daily_revenue'] ?? 0).toDouble(),
      weeklyRevenue: (json['weekly_revenue'] ?? 0).toDouble(),
      monthlyRevenue: (json['monthly_revenue'] ?? 0).toDouble(),
      revenueGrowth: (json['revenue_growth'] ?? 0).toDouble(),
      revenueHistory: historyList,
      bestResidences: bestResidencesList,
      revenueByCategory: categoryMap,
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
      revenue: (json['revenue'] ?? 0).toDouble(),
      bookings: json['bookings'] ?? 0,
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
      revenue: (json['revenue'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
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
  final Map<String, int> bookingsByStatus;

  GeneralStats({
    required this.responseRate,
    required this.averageResponseTime,
    required this.rating,
    required this.bookingsByStatus,
  });

  factory GeneralStats.fromJson(Map<String, dynamic> json) {
    final bookingsMap = (json['bookings'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, value as int),
        ) ??
        {};

    return GeneralStats(
      responseRate: (json['response_rate'] ?? 0).toDouble(),
      averageResponseTime: json['average_response_time'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      bookingsByStatus: bookingsMap,
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
      activeBookings: json['active_bookings'] ?? 0,
      pendingRequests: json['pending_requests'] ?? 0,
      todayVisits: visitsList,
      recentActivities: activitiesList,
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
      totalResidences: json['total_residences'] ?? 0,
      bookingsByStatus: Map<String, int>.from(json['bookings_by_status'] ?? {}),
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      responseRate: (json['response_rate'] ?? 0).toDouble(),
      occupancyRate: (json['occupancy_rate'] ?? 0).toDouble(),
      monthlyRevenue: (json['monthly_revenue'] ?? 0).toDouble(),
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
      totalBookings: json['total_bookings'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      occupancyRate: (json['occupancy_rate'] ?? 0).toDouble(),
      bookingsByStatus: Map<String, int>.from(json['bookings_by_status'] ?? {}),
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
      growth: (json['growth'] ?? 0).toDouble(),
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
      bookings: json['bookings'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      occupancyRate: (json['occupancy_rate'] ?? 0).toDouble(),
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

  factory EarningsData.fromJson(Map<String, dynamic> json) {
    final earningsList = (json['earnings'] as List?)?.map(
      (period) => EarningPeriod.fromJson(period),
    ).toList() ?? [];

    return EarningsData(
      earnings: earningsList,
      totalEarnings: (json['total_earnings'] ?? 0).toDouble(),
      averagePerPeriod: (json['average_per_period'] ?? 0).toDouble(),
      growth: (json['growth'] ?? 0).toDouble(),
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
    return EarningPeriod(
      date: DateTime.parse(json['date'] ?? ''),
      amount: (json['amount'] ?? 0).toDouble(),
      bookingsCount: json['count'] ?? 0,
    );
  }
}
