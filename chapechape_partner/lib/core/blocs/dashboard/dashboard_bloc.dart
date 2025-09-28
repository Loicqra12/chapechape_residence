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
import '../../config/app_config_manager.dart';

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
  final ResidenceService _residenceService;
  StreamSubscription? _residenceEventSubscription;
  
  DashboardBloc(this._dashboardService) : 
    _residenceService = ResidenceService(baseUrl: AppConfigManager.apiUrl),
    super(DashboardInitial()) {
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

      // Variables pour stocker les données avec valeurs par défaut au cas où une API échoue
      DashboardOverview? overview;
      DashboardFinances? finances;
      RealtimeStats? realtime;
      PartnerStats? partnerStats;
      TrendData? trendData;
      List<ResidenceStats>? residenceStats;
      EarningsData? earningsData;
      
      try {
        // Charger toutes les données en parallèle avec retry automatique sur 429
        final futures = await Future.wait([
          // 1. Dashboard Overview avec retry
          _retryOnRateLimit(() => _dashboardService.getDashboardOverview()).catchError((e) {
            debugPrint('❌ Erreur lors de la récupération du dashboard overview: $e');
            return DashboardOverview(
              totalResidences: 0,
              bookings: {'total': 0, 'pending': 0, 'confirmed': 0, 'cancelled': 0, 'completed': 0},
              occupancyRate: 0.0,
              pendingReviews: 0,
              newMessages: 0,
              performance: {'averageResponseTime': 0, 'averageRating': 0.0},
              responseRate: 0.0
            );
          }),
          
          // 2. Dashboard Finances avec retry
          _retryOnRateLimit(() => _dashboardService.getDashboardFinances()).catchError((e) {
            debugPrint('❌ Erreur lors de la récupération des finances: $e');
            return DashboardFinances(
              monthlyRevenue: 0.0,
              dailyRevenue: 0.0,
              weeklyRevenue: 0.0,
              revenueGrowth: 0.0,
              bestPerformingResidences: [],
              revenueByCategory: {}
            );
          }),
          
          // 3. Dashboard Realtime avec retry
          _retryOnRateLimit(() => _dashboardService.getDashboardRealtime()).catchError((e) {
            debugPrint('❌ Erreur lors de la récupération des statistiques en temps réel: $e');
            return RealtimeStats.empty();
          }),
          
          // 4. Partner Stats avec retry
          _retryOnRateLimit(() => _dashboardService.getPartnerStats()).catchError((e) {
            debugPrint('❌ Erreur lors de la récupération des statistiques du partenaire: $e');
            return PartnerStats.empty();
          }),
          
          // 5. Trends avec retry
          _retryOnRateLimit(() => _dashboardService.getTrends(period: period)).catchError((e) {
            debugPrint('❌ Erreur lors de la récupération des tendances: $e');
            return TrendData.empty();
          }),
          
          // 6. Residence Stats avec retry
          _retryOnRateLimit(() => _dashboardService.getResidenceStats()).catchError((e) {
            debugPrint('❌ Erreur lors de la récupération des statistiques des résidences: $e');
            return <ResidenceStats>[];
          }),
          
          // 7. Earnings avec retry
          _retryOnRateLimit(() => _dashboardService.getEarnings()).catchError((e) {
            debugPrint('❌ Erreur lors de la récupération des revenus: $e');
            return EarningsData.empty();
          }),
        ]);
        
        overview = futures[0] as DashboardOverview?;
        finances = futures[1] as DashboardFinances?;
        realtime = futures[2] as RealtimeStats;
        partnerStats = futures[3] as PartnerStats;
        trendData = futures[4] as TrendData;
        residenceStats = futures[5] as List<ResidenceStats>;
        earningsData = futures[6] as EarningsData;
        
        // Combiner les données des 3 premiers endpoints en DashboardData
        final dashboardData = DashboardData(
          performance: PerformanceStats(
            totalResidences: overview?.totalResidences ?? 0,
            totalReservations: overview?.bookings['total'] ?? 0,
            occupancyRate: overview?.occupancyRate ?? 0.0,
            pendingReviews: overview?.pendingReviews ?? 0,
            newMessages: overview?.newMessages ?? 0,
          ),
          revenue: RevenueStats(
            totalRevenue: finances?.monthlyRevenue ?? 0,
            dailyRevenue: finances?.dailyRevenue ?? 0,
            weeklyRevenue: finances?.weeklyRevenue ?? 0,
            monthlyRevenue: finances?.monthlyRevenue ?? 0,
            revenueGrowth: finances?.revenueGrowth ?? 0.0,
            revenueHistory: trendData.points.map((point) => RevenuePoint(
              date: point.date,
              amount: point.revenue,
            )).toList(),
            bestResidences: finances?.bestPerformingResidences ?? [],
            revenueByCategory: finances?.revenueByCategory ?? {},
          ),
          stats: GeneralStats(
            responseRate: overview?.responseRate ?? 0.0,
            averageResponseTime: overview?.performance['averageResponseTime'] ?? 0,
            rating: overview?.performance['averageRating'] ?? 0.0,
            bookingsByStatus: overview?.bookings ?? {},
          ),
          realtime: realtime,
        );
        
        // Si le nombre de résidences est 0, essayons de récupérer les résidences directement
        // via le ResidenceService - cela fonctionnera même si l'API statistics est inaccessible
        if (partnerStats.totalResidences == 0) {
          try {
            debugPrint('🔍 Tentative de récupération des résidences via ResidenceService...');
            final residences = await _residenceService.getPartnerResidences();
            
            // Si nous avons réussi à obtenir des résidences, mettre à jour les statistiques
            if (residences.isNotEmpty) {
              debugPrint('✅ ${residences.length} résidences récupérées directement!');
              
              // Créer un nouveau PartnerStats avec les informations des résidences
              partnerStats = PartnerStats(
                totalResidences: residences.length,
                bookingsByStatus: partnerStats.bookingsByStatus,
                averageRating: partnerStats.averageRating,
                responseRate: partnerStats.responseRate,
                occupancyRate: partnerStats.occupancyRate,
                monthlyRevenue: partnerStats.monthlyRevenue,
              );
              
              // Mettre à jour également les données du tableau de bord si elles existent
              if (overview != null) {
                // Créer un nouvel objet overview avec les informations mises à jour
                final Map<String, int> existingBookings = overview.bookings;
                final Map<String, dynamic> existingPerformance = overview.performance;
                
                // Créer un nouvel objet du même type avec les données mises à jour
                overview = DashboardOverview(
                  totalResidences: residences.length,
                  bookings: existingBookings,
                  occupancyRate: overview.occupancyRate,
                  pendingReviews: overview.pendingReviews, 
                  newMessages: overview.newMessages,
                  performance: existingPerformance,
                  responseRate: overview.responseRate
                );
              }
            }
          } catch (e) {
            debugPrint('❌ Erreur lors de la récupération directe des résidences: $e');
          }
        }
        
        emit(DashboardLoaded(
          dashboardData: dashboardData,
          partnerStats: partnerStats ?? PartnerStats.empty(),
          residenceStats: residenceStats,
          trendData: trendData,
          earningsData: earningsData,
          period: period,
        ));
      } catch (e) {
        debugPrint('⚠️ Erreur lors du chargement des statistiques, utilisation de fallback: $e');
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

  /// Méthode utilitaire pour retry automatique sur rate limiting (429)
  Future<T> _retryOnRateLimit<T>(Future<T> Function() operation) async {
    const maxRetries = 3;
    const baseDelay = Duration(milliseconds: 500);
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        // Vérifier si c'est une erreur 429 (rate limiting)
        bool isRateLimited = e.toString().contains('429') || 
                            e.toString().toLowerCase().contains('too many requests');
        
        if (isRateLimited && attempt < maxRetries - 1) {
          // Attendre avec backoff exponentiel
          final delay = Duration(milliseconds: baseDelay.inMilliseconds * (attempt + 1));
          print('🔄 Rate limit détecté, retry #${attempt + 1} dans ${delay.inMilliseconds}ms...');
          await Future.delayed(delay);
          continue;
        }
        
        // Si ce n'est pas du rate limiting, ou si on a épuisé les retries, relancer l'exception
        rethrow;
      }
    }
    
    // Ne devrait jamais arriver, mais au cas où
    throw Exception('Échec après $maxRetries tentatives');
  }

  /// Gestion des changements de période
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
