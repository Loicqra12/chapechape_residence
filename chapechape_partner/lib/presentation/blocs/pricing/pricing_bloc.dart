import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/models/pricing/pricing_model.dart';
import '../../../core/services/api/pricing_service.dart';

// ===============================
// EVENTS
// ===============================

abstract class PricingEvent extends Equatable {
  const PricingEvent();

  @override
  List<Object?> get props => [];
}

class LoadPricingStatsEvent extends PricingEvent {}

class CalculatePricingEvent extends PricingEvent {
  final double basePrice;
  final String? paymentMethod;

  const CalculatePricingEvent({
    required this.basePrice,
    this.paymentMethod,
  });

  @override
  List<Object?> get props => [basePrice, paymentMethod];
}

class LoadPaymentMethodsEvent extends PricingEvent {}

class CalculateSavingsAnalysisEvent extends PricingEvent {
  final double basePrice;

  const CalculateSavingsAnalysisEvent({required this.basePrice});

  @override
  List<Object?> get props => [basePrice];
}

// ===============================
// STATES
// ===============================

abstract class PricingState extends Equatable {
  const PricingState();

  @override
  List<Object?> get props => [];
}

class PricingInitial extends PricingState {}

class PricingLoading extends PricingState {}

class PricingStatsLoading extends PricingState {}

class PricingCalculationLoading extends PricingState {}

class PricingError extends PricingState {
  final String message;

  const PricingError({required this.message});

  @override
  List<Object?> get props => [message];
}

class PricingStatsError extends PricingState {
  final String message;

  const PricingStatsError({required this.message});

  @override
  List<Object?> get props => [message];
}

class PricingStatsLoaded extends PricingState {
  final PricingStats stats;

  const PricingStatsLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

class PricingCalculated extends PricingState {
  final PricingModel pricing;

  const PricingCalculated({required this.pricing});

  @override
  List<Object?> get props => [pricing];
}

class PaymentMethodsLoaded extends PricingState {
  final List<PaymentMethodInfo> methods;

  const PaymentMethodsLoaded({required this.methods});

  @override
  List<Object?> get props => [methods];
}

class SavingsAnalysisLoaded extends PricingState {
  final SavingsAnalysis analysis;

  const SavingsAnalysisLoaded({required this.analysis});

  @override
  List<Object?> get props => [analysis];
}

class PricingMultiStateLoaded extends PricingState {
  final PricingStats? stats;
  final List<PaymentMethodInfo>? paymentMethods;
  final SavingsAnalysis? savingsAnalysis;
  final PricingModel? currentPricing;

  const PricingMultiStateLoaded({
    this.stats,
    this.paymentMethods,
    this.savingsAnalysis,
    this.currentPricing,
  });

  @override
  List<Object?> get props => [stats, paymentMethods, savingsAnalysis, currentPricing];

  PricingMultiStateLoaded copyWith({
    PricingStats? stats,
    List<PaymentMethodInfo>? paymentMethods,
    SavingsAnalysis? savingsAnalysis,
    PricingModel? currentPricing,
  }) {
    return PricingMultiStateLoaded(
      stats: stats ?? this.stats,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      savingsAnalysis: savingsAnalysis ?? this.savingsAnalysis,
      currentPricing: currentPricing ?? this.currentPricing,
    );
  }
}

// ===============================
// BLOC
// ===============================

class PricingBloc extends Bloc<PricingEvent, PricingState> {
  final PricingService _pricingService;

  PricingBloc({required PricingService pricingService})
      : _pricingService = pricingService,
        super(PricingInitial()) {
    
    on<LoadPricingStatsEvent>(_onLoadPricingStats);
    on<CalculatePricingEvent>(_onCalculatePricing);
    on<LoadPaymentMethodsEvent>(_onLoadPaymentMethods);
    on<CalculateSavingsAnalysisEvent>(_onCalculateSavingsAnalysis);
  }

  Future<void> _onLoadPricingStats(
    LoadPricingStatsEvent event,
    Emitter<PricingState> emit,
  ) async {
    emit(PricingStatsLoading());
    
    try {
      final stats = await _pricingService.getPartnerPricingStats();
      emit(PricingStatsLoaded(stats: stats));
    } catch (e) {
      emit(PricingStatsError(message: e.toString()));
    }
  }

  Future<void> _onCalculatePricing(
    CalculatePricingEvent event,
    Emitter<PricingState> emit,
  ) async {
    emit(PricingCalculationLoading());
    
    try {
      final pricing = await _pricingService.calculateOptimalPricing(
        basePrice: event.basePrice,
        paymentMethod: event.paymentMethod,
      );
      emit(PricingCalculated(pricing: pricing));
    } catch (e) {
      emit(PricingError(message: e.toString()));
    }
  }

  Future<void> _onLoadPaymentMethods(
    LoadPaymentMethodsEvent event,
    Emitter<PricingState> emit,
  ) async {
    emit(PricingLoading());
    
    try {
      final methods = await _pricingService.getOptimizedPaymentMethods();
      emit(PaymentMethodsLoaded(methods: methods));
    } catch (e) {
      emit(PricingError(message: e.toString()));
    }
  }

  Future<void> _onCalculateSavingsAnalysis(
    CalculateSavingsAnalysisEvent event,
    Emitter<PricingState> emit,
  ) async {
    emit(PricingLoading());
    
    try {
      final analysis = await _pricingService.calculateSavingsAnalysis(
        basePrice: event.basePrice,
      );
      emit(SavingsAnalysisLoaded(analysis: analysis));
    } catch (e) {
      emit(PricingError(message: e.toString()));
    }
  }

  /// Charger toutes les données pricing en une fois (pour dashboard)
  Future<void> loadAllPricingData({double? basePrice}) async {
    emit(PricingLoading());
    
    try {
      // Charger en parallèle toutes les données
      final futures = <Future>[
        _pricingService.getPartnerPricingStats(),
        _pricingService.getOptimizedPaymentMethods(),
      ];
      
      if (basePrice != null) {
        futures.add(_pricingService.calculateSavingsAnalysis(basePrice: basePrice));
        futures.add(_pricingService.calculateOptimalPricing(basePrice: basePrice));
      }
      
      final results = await Future.wait(futures);
      
      emit(PricingMultiStateLoaded(
        stats: results[0] as PricingStats,
        paymentMethods: results[1] as List<PaymentMethodInfo>,
        savingsAnalysis: basePrice != null ? results[2] as SavingsAnalysis : null,
        currentPricing: basePrice != null ? results[3] as PricingModel : null,
      ));
    } catch (e) {
      emit(PricingError(message: e.toString()));
    }
  }

  /// Calculer le pricing pour multiple méthodes
  Future<void> calculateMultiMethodPricing(double basePrice) async {
    emit(PricingCalculationLoading());
    
    try {
      final multiPricing = await _pricingService.calculateMultiMethodPricing(
        basePrice: basePrice,
      );
      
      // Convertir en format utilisable pour l'UI
      final methodInfos = multiPricing.entries.map((entry) {
        return PaymentMethodInfo(
          method: entry.key,
          displayName: entry.value.paymentMethodDisplayName,
          totalCost: entry.value.totalClientPrice,
          isRecommended: entry.value.isOptimized,
          priority: _getMethodPriority(entry.key),
        );
      }).toList();
      
      // Trier par coût
      methodInfos.sort((a, b) => a.totalCost.compareTo(b.totalCost));
      
      emit(PaymentMethodsLoaded(methods: methodInfos));
    } catch (e) {
      emit(PricingError(message: e.toString()));
    }
  }

  int _getMethodPriority(String method) {
    switch (method) {
      case 'mtn_money':
        return 1;
      case 'wave':
        return 2;
      case 'orange_money':
        return 3;
      case 'moov_money':
        return 4;
      case 'card':
        return 5;
      default:
        return 6;
    }
  }
}
