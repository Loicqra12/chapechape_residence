import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/models/dashboard/dashboard_data.dart';
import '../../../core/services/api/dashboard_service.dart';
import '../../../core/services/api/residence_service.dart';
import '../../../core/services/api/reservation_service.dart';
import '../../../core/services/api/api_service.dart';
import '../../../core/services/event_bus/residence_event_bus.dart' as event_bus;

// Events
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadDashboardData extends DashboardEvent {}

class RefreshDashboardData extends DashboardEvent {}

class ChangePeriod extends DashboardEvent {
  final String period;
  final String? startDate;
  final String? endDate;
  
  const ChangePeriod({
    required this.period,
    this.startDate,
    this.endDate,
  });
  
  @override
  List<Object?> get props => [period, startDate, endDate];
}

// Événement interne pour synchroniser avec les résidences
class _SyncWithResidences extends DashboardEvent {
  final event_bus.ResidenceEventType eventType;
  
  const _SyncWithResidences(this.eventType);
  
  @override
  List<Object?> get props => [eventType];
}

// States
abstract class DashboardState extends Equatable {
  const DashboardState();
  
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardData dashboardData;
  final PartnerStats partnerStats;
  final List<ResidenceStats> residenceStats;
  final TrendData trendData;
  final EarningsData earningsData;
  final String period;
  final String? startDate;
  final String? endDate;
  
  const DashboardLoaded({
    required this.dashboardData,
    required this.partnerStats,
    required this.residenceStats,
    required this.trendData,
    required this.earningsData,
    this.period = 'monthly',
    this.startDate,
    this.endDate,
  });
  
  @override
  List<Object?> get props => [
    dashboardData, 
    partnerStats, 
    residenceStats, 
    trendData, 
    earningsData, 
    period, 
    startDate, 
    endDate
  ];
  
  DashboardLoaded copyWith({
    DashboardData? dashboardData,
    PartnerStats? partnerStats,
    List<ResidenceStats>? residenceStats,
    TrendData? trendData,
    EarningsData? earningsData,
    String? period,
    String? startDate,
    String? endDate,
  }) {
    return DashboardLoaded(
      dashboardData: dashboardData ?? this.dashboardData,
      partnerStats: partnerStats ?? this.partnerStats,
      residenceStats: residenceStats ?? this.residenceStats,
      trendData: trendData ?? this.trendData,
      earningsData: earningsData ?? this.earningsData,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

class DashboardError extends DashboardState {
  final String message;
  
  const DashboardError(this.message);
  
  @override
  List<Object> get props => [message];
}

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardService _dashboardService;
  StreamSubscription? _residenceEventSubscription;
  
  DashboardBloc(this._dashboardService) : super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
    on<RefreshDashboardData>(_onRefreshDashboardData);
    on<ChangePeriod>(_onChangePeriod);
    on<_SyncWithResidences>(_onSyncWithResidences);
    
    // Configurer l'écouteur d'événements pour les résidences
    _setupResidenceEventListener();
  }
  
  void _setupResidenceEventListener() {
    _residenceEventSubscription = _dashboardService.residenceEventStream.listen((eventType) {
      debugPrint('🔔 DashboardBloc: Événement résidence reçu: $eventType');
      add(_SyncWithResidences(eventType));
    });
  }
  
  @override
  Future<void> close() {
    _residenceEventSubscription?.cancel();
    return super.close();
  }
  
  Future<void> _onSyncWithResidences(
    _SyncWithResidences event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      // Ne pas perturber l'interface si le tableau de bord est déjà en cours de chargement
      if (state is DashboardLoading) return;
      
      debugPrint('📊 DashboardBloc: Synchronisation avec les résidences (${event.eventType})');
      
      // Si le tableau de bord est déjà chargé, mettre à jour uniquement les données nécessaires
      if (state is DashboardLoaded) {
        final currentState = state as DashboardLoaded;
        
        // Récupérer les nouvelles statistiques de résidence
        final updatedResidenceStats = await _dashboardService.getResidenceStats(
          startDate: currentState.startDate,
          endDate: currentState.endDate,
        );
        
        // Mettre à jour le nombre de résidences dans les performances
        final existingDashboard = currentState.dashboardData;
        final updatedPerformance = PerformanceStats(
          totalResidences: updatedResidenceStats.length,
          totalReservations: existingDashboard.performance.totalReservations,
          occupancyRate: existingDashboard.performance.occupancyRate,
          pendingReviews: existingDashboard.performance.pendingReviews,
          newMessages: existingDashboard.performance.newMessages,
        );
        
        final updatedDashboard = DashboardData(
          performance: updatedPerformance,
          revenue: existingDashboard.revenue,
          stats: existingDashboard.stats,
          realtime: existingDashboard.realtime,
        );
        
        // Émettre le nouvel état avec les données mises à jour
        emit(currentState.copyWith(
          dashboardData: updatedDashboard,
          residenceStats: updatedResidenceStats,
        ));
      } else {
        // Si aucune donnée n'est chargée, charger le tableau de bord complet
        add(LoadDashboardData());
      }
    } catch (e) {
      debugPrint('📊 DashboardBloc: Erreur lors de la synchronisation: $e');
      // Ne pas émettre d'erreur pour ne pas perturber l'interface
    }
  }
  
  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      emit(DashboardLoading());
      
      // Définir la période par défaut
      final String period = 'monthly';

      try {
        // Charger toutes les données en parallèle
        final futures = await Future.wait([
          // 1. Dashboard Overview (Endpoint 5)
          _dashboardService.getDashboardOverview(),
          
          // 2. Dashboard Finances (Endpoint 6)
          _dashboardService.getDashboardFinances(),
          
          // 3. Dashboard Realtime (Endpoint 7)
          _dashboardService.getDashboardRealtime(),
          
          // 4. Partner Stats (Endpoint 1)
          _dashboardService.getPartnerStats(),
          
          // 5. Trends (Endpoint 2)
          _dashboardService.getTrends(period: period),
          
          // 6. Residence Stats (Endpoint 3)
          _dashboardService.getResidenceStats(),
          
          // 7. Earnings (Endpoint 4)
          _dashboardService.getEarnings(),
        ]);
        
        final overview = futures[0] as DashboardOverview;
        final finances = futures[1] as DashboardFinances;
        final realtime = futures[2] as RealtimeStats;
        final partnerStats = futures[3] as PartnerStats;
        final trendData = futures[4] as TrendData;
        final residenceStats = futures[5] as List<ResidenceStats>;
        final earningsData = futures[6] as EarningsData;
        
        // Combiner les données des 3 premiers endpoints en DashboardData
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
            revenueHistory: trendData.points.map((point) => RevenuePoint(
              date: point.date,
              amount: point.revenue,
            )).toList(),
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
        
        emit(DashboardLoaded(
          dashboardData: dashboardData,
          partnerStats: partnerStats,
          residenceStats: residenceStats,
          trendData: trendData,
          earningsData: earningsData,
          period: period,
        ));
      } catch (serviceError) {
        // Gérer le cas d'erreur du service ou l'absence de données en utilisant des objets vides
        debugPrint('Erreur du service dashboard: $serviceError');
        debugPrint('Initialisation avec des données vides par défaut');
        
        // Créer des objets vides pour le chargement mais avec le nombre correct de résidences
        try {
          // Essayer de récupérer juste les résidences si c'est la seule chose qui fonctionne
          final residences = await _dashboardService.getResidenceStats();
          
          // Filtrer explicitement les résidences problématiques
          final filteredResidences = residences.where((residence) => 
            residence.id != '67e2ecd94408a95a7b598b0d' && // Ignorer l'ID connu comme problématique
            residence.title.isNotEmpty // Ignorer les résidences sans titre
          ).toList();
          
          final residenceCount = filteredResidences.length;
          
          debugPrint('Récupération de secours: $residenceCount résidences valides trouvées après filtrage');
          
          // Vérifier le contenu des résidences filtrées
          for (var residence in filteredResidences) {
            debugPrint('Résidence de secours valide - ID: ${residence.id}, Titre: ${residence.title}, Status: ${residence.status}');
          }
          
          // Créer un dashboard avec le nombre correct de résidences
          final dashboardData = DashboardData.empty();
          final performance = dashboardData.performance;
          // Mettre à jour le nombre de résidences
          final updatedPerformance = PerformanceStats(
            totalResidences: residenceCount,
            totalReservations: performance.totalReservations,
            occupancyRate: performance.occupancyRate,
            pendingReviews: performance.pendingReviews,
            newMessages: performance.newMessages,
          );
          
          final updatedDashboardData = dashboardData.copyWith(
            performance: updatedPerformance,
          );
          
          emit(DashboardLoaded(
            dashboardData: updatedDashboardData,
            partnerStats: PartnerStats.empty(),
            residenceStats: filteredResidences,
            trendData: TrendData.empty(),
            earningsData: EarningsData.empty(),
            period: period,
          ));
          
          return;
        } catch (e) {
          debugPrint('Échec de la récupération de secours des résidences: $e');
        }
        
        // Si même la récupération de secours échoue, initialiser avec des données complètement vides
        final dashboardData = DashboardData.empty();
        final partnerStats = PartnerStats.empty();
        final List<ResidenceStats> residenceStats = [];
        final trendData = TrendData.empty();
        final earningsData = EarningsData.empty();
        
        emit(DashboardLoaded(
          dashboardData: dashboardData,
          partnerStats: partnerStats,
          residenceStats: residenceStats,
          trendData: trendData,
          earningsData: earningsData,
          period: period,
        ));
      }
    } catch (e) {
      debugPrint('Erreur globale du dashboard: $e');
      emit(DashboardError('Une erreur est survenue, veuillez réessayer.'));
    }
  }
  
  Future<void> _onRefreshDashboardData(
    RefreshDashboardData event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final loadedState = state as DashboardLoaded;
      await _loadDataWithPeriod(
        emit, 
        loadedState.period, 
        loadedState.startDate, 
        loadedState.endDate
      );
    } else {
      await _onLoadDashboardData(LoadDashboardData(), emit);
    }
  }
  
  Future<void> _onChangePeriod(
    ChangePeriod event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      await _loadDataWithPeriod(emit, event.period, event.startDate, event.endDate);
    }
  }
  
  Future<void> _loadDataWithPeriod(
    Emitter<DashboardState> emit,
    String period,
    String? startDate,
    String? endDate,
  ) async {
    // Ne pas émettre DashboardLoading pour éviter le spinner infini
    // emit(DashboardLoading());
    
    if (state is DashboardLoaded) {
      // Récupérer l'état actuel pour pouvoir réutiliser les données existantes
      final currentState = state as DashboardLoaded;
      
      try {
        // Mettre à jour immédiatement la période dans l'UI
        emit(currentState.copyWith(
          period: period,
          startDate: startDate,
          endDate: endDate,
        ));
        
        // Charger uniquement les données qui dépendent de la période
        final futures = await Future.wait([
          // 1. Trends (Endpoint 2)
          _dashboardService.getTrends(
            period: period, 
            startDate: startDate, 
            endDate: endDate
          ),
          
          // 2. Residence Stats (Endpoint 3)
          _dashboardService.getResidenceStats(
            startDate: startDate, 
            endDate: endDate
          ),
          
          // 3. Earnings (Endpoint 4)
          _dashboardService.getEarnings(
            startDate: startDate, 
            endDate: endDate
          ),
        ]);
        
        final trendData = futures[0] as TrendData;
        final residenceStats = futures[1] as List<ResidenceStats>;
        final earningsData = futures[2] as EarningsData;
        
        // Mettre à jour avec les nouvelles données
        emit(currentState.copyWith(
          trendData: trendData,
          residenceStats: residenceStats,
          earningsData: earningsData,
          period: period,
          startDate: startDate,
          endDate: endDate,
        ));
      } catch (e) {
        debugPrint('Erreur lors du changement de période: $e');
        
        // En cas d'erreur, garder les données existantes avec la nouvelle période
        emit(currentState.copyWith(
          period: period,
          startDate: startDate, 
          endDate: endDate,
        ));
      }
    }
  }
}

// Redéfinir l'enum pour être compatible avec le code existant
// Cela permettra d'éviter des erreurs de compilation
enum ResidenceEventType { created, updated, deleted }

class ResidenceEventBus {
  static final ResidenceEventBus _instance = ResidenceEventBus._internal();
  factory ResidenceEventBus() => _instance;
  ResidenceEventBus._internal();
  
  final _controller = StreamController<ResidenceEventType>.broadcast();
  
  Stream<ResidenceEventType> get stream => _controller.stream;
  
  void emit(ResidenceEventType event) {
    _controller.add(event);
  }
  
  void dispose() {
    _controller.close();
  }
}
