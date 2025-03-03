import 'package:dio/dio.dart';
import '../../models/dashboard/dashboard_data.dart';

class DashboardService {
  final Dio _dio;

  DashboardService(this._dio);

  Future<DashboardData> getDashboardData() async {
    try {
      final response = await _dio.get('/dashboard');
      return DashboardData.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load dashboard data');
    }
  }

  Future<RevenueStats> getRevenueStats(String period) async {
    try {
      final response = await _dio.get('/dashboard/revenue', queryParameters: {
        'period': period,
      });
      return RevenueStats.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load revenue stats');
    }
  }
}
