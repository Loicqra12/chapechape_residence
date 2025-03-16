import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/dashboard/dashboard_data.dart';
import '../../../core/services/api/dashboard_service.dart';

// Events
abstract class DashboardEvent {}

class LoadDashboardData extends DashboardEvent {}
class RefreshDashboardData extends DashboardEvent {}

// States
abstract class DashboardState {}

class DashboardInitial extends DashboardState {}
class DashboardLoading extends DashboardState {}
class DashboardLoaded extends DashboardState {
  final DashboardData data;
  final String revenuePeriod;

  DashboardLoaded({
    required this.data,
    this.revenuePeriod = 'monthly',
  });
}

class DashboardError extends DashboardState {
  final String message;

  DashboardError(this.message);
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardService _dashboardService;

  DashboardBloc(this._dashboardService) : super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<RefreshDashboardData>(_onRefreshDashboardData);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      emit(DashboardLoading());

      // Charger les données du dashboard
      final overview = await _dashboardService.getDashboardOverview();
      final finances = await _dashboardService.getDashboardFinances();
      final realtime = await _dashboardService.getDashboardRealtime();

      // Combiner les données
      final dashboardData = DashboardData(
        performance: PerformanceStats(
          totalResidences: overview.totalResidences,
          totalReservations: overview.bookings['total'] ?? 0,
          occupancyRate: overview.occupancyRate,
          pendingReviews: overview.pendingReviews,
          newMessages: overview.newMessages,
        ),
        revenue: RevenueStats(
          totalRevenue: finances.monthlyRevenue,
          dailyRevenue: finances.dailyRevenue,
          weeklyRevenue: finances.weeklyRevenue,
          monthlyRevenue: finances.monthlyRevenue,
          revenueGrowth: finances.revenueGrowth,
          revenueHistory: [], // À implémenter si nécessaire
          bestResidences: finances.bestPerformingResidences,
          revenueByCategory: finances.revenueByCategory,
        ),
        stats: GeneralStats(
          responseRate: overview.responseRate,
          averageResponseTime: overview.performance['averageResponseTime'] ?? 0,
          rating: overview.performance['averageRating'] ?? 0.0,
          bookingsByStatus: overview.bookings,
        ),
        realtime: realtime,
      );

      emit(DashboardLoaded(data: dashboardData));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onRefreshDashboardData(
    RefreshDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      await _onLoadDashboardData(LoadDashboardData(), emit);
    }
  }
}
