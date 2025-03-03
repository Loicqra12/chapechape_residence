import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/dashboard/dashboard_data.dart';
import '../../services/api/dashboard_service.dart';

// Events
abstract class DashboardEvent {}

class LoadDashboardData extends DashboardEvent {}

class UpdateRevenuePeriod extends DashboardEvent {
  final String period;
  UpdateRevenuePeriod(this.period);
}

// States
abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardData data;
  final String revenuePeriod;

  DashboardLoaded({
    required this.data,
    this.revenuePeriod = 'month',
  });
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}

// Bloc
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardService _dashboardService;

  DashboardBloc(this._dashboardService) : super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<UpdateRevenuePeriod>(_onUpdateRevenuePeriod);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final data = await _dashboardService.getDashboardData();
      emit(DashboardLoaded(data: data));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> _onUpdateRevenuePeriod(
    UpdateRevenuePeriod event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      emit(DashboardLoading());
      try {
        final revenueStats = await _dashboardService.getRevenueStats(event.period);
        emit(DashboardLoaded(
          data: DashboardData(
            performance: currentState.data.performance,
            revenue: revenueStats,
            stats: currentState.data.stats,
          ),
          revenuePeriod: event.period,
        ));
      } catch (e) {
        emit(DashboardError(e.toString()));
      }
    }
  }
}
