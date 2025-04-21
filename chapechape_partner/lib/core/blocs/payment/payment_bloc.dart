import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/payment/payment_model.dart';
import '../../services/api/payment_service.dart';

// Events
abstract class PaymentEvent {
  const PaymentEvent();
}

class LoadPayments extends PaymentEvent {
  final int page;
  
  const LoadPayments({this.page = 1});
}

class RefreshPayments extends PaymentEvent {
  const RefreshPayments();
}

class RequestWithdrawal extends PaymentEvent {
  final double amount;
  final String method;
  
  const RequestWithdrawal({
    required this.amount,
    this.method = 'bank_transfer',
  });
}

class CancelWithdrawal extends PaymentEvent {
  final String transactionId;
  
  const CancelWithdrawal({required this.transactionId});
}

// States
abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentError extends PaymentState {
  final String message;
  
  PaymentError(this.message);
}

class PaymentsLoaded extends PaymentState {
  final List<PaymentModel> transactions;
  final double balance;
  final double monthlyRevenue;
  final double totalWithdrawals;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoading;
  
  PaymentsLoaded({
    required this.transactions,
    required this.balance,
    required this.monthlyRevenue,
    required this.totalWithdrawals,
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.isLoading = false,
  });
  
  PaymentsLoaded copyWith({
    List<PaymentModel>? transactions,
    double? balance,
    double? monthlyRevenue,
    double? totalWithdrawals,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoading,
  }) {
    return PaymentsLoaded(
      transactions: transactions ?? this.transactions,
      balance: balance ?? this.balance,
      monthlyRevenue: monthlyRevenue ?? this.monthlyRevenue,
      totalWithdrawals: totalWithdrawals ?? this.totalWithdrawals,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PaymentActionSuccess extends PaymentState {
  final String message;
  
  PaymentActionSuccess(this.message);
}

// BLoC
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentService _paymentService;
  
  PaymentBloc({required PaymentService paymentService}) 
      : _paymentService = paymentService,
        super(PaymentInitial()) {
    on<LoadPayments>(_onLoadPayments);
    on<RefreshPayments>(_onRefreshPayments);
    on<RequestWithdrawal>(_onRequestWithdrawal);
    on<CancelWithdrawal>(_onCancelWithdrawal);
  }
  
  Future<void> _onLoadPayments(
    LoadPayments event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      // Si c'est la première page, afficher un loader
      if (event.page == 1) {
        emit(PaymentLoading());
      } else if (state is PaymentsLoaded) {
        // Sinon, marquer comme chargement en cours tout en gardant les données existantes
        final currentState = state as PaymentsLoaded;
        emit(currentState.copyWith(isLoading: true));
      }
      
      final result = await _paymentService.getTransactions(page: event.page);
      
      // Mettre à jour l'état
      if (state is PaymentsLoaded) {
        final currentState = state as PaymentsLoaded;
        emit(currentState.copyWith(
          transactions: event.page == 1
              ? result.transactions
              : [...currentState.transactions, ...result.transactions],
          balance: result.balance,
          monthlyRevenue: result.monthlyRevenue,
          totalWithdrawals: result.totalWithdrawals,
          currentPage: event.page,
          hasReachedMax: result.transactions.isEmpty || result.transactions.length < 10,
          isLoading: false,
        ));
      } else {
        emit(PaymentsLoaded(
          transactions: result.transactions,
          balance: result.balance,
          monthlyRevenue: result.monthlyRevenue,
          totalWithdrawals: result.totalWithdrawals,
          currentPage: event.page,
          hasReachedMax: result.transactions.isEmpty || result.transactions.length < 10,
          isLoading: false,
        ));
      }
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }
  
  Future<void> _onRefreshPayments(
    RefreshPayments event,
    Emitter<PaymentState> emit,
  ) async {
    add(const LoadPayments(page: 1));
  }
  
  Future<void> _onRequestWithdrawal(
    RequestWithdrawal event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      // Vérifier si le solde est suffisant
      if (state is PaymentsLoaded) {
        final currentState = state as PaymentsLoaded;
        if (event.amount > currentState.balance) {
          emit(PaymentError('Le montant demandé dépasse votre solde disponible'));
          emit(currentState);
          return;
        }
      }
      
      // Effectuer la demande de retrait
      final result = await _paymentService.requestWithdrawal(
        amount: event.amount,
        method: event.method,
      );
      
      // Si la demande a réussi, mettre à jour l'état
      if (state is PaymentsLoaded) {
        final currentState = state as PaymentsLoaded;
        
        emit(PaymentActionSuccess('Votre demande de retrait a été enregistrée'));
        
        // Recharger les données pour être sûr d'avoir les informations à jour
        add(const LoadPayments(page: 1));
      }
    } catch (e) {
      emit(PaymentError('Erreur lors de la demande de retrait: ${e.toString()}'));
      
      // Restaurer l'état précédent
      if (state is PaymentsLoaded) {
        final currentState = state as PaymentsLoaded;
        emit(currentState);
      }
    }
  }
  
  Future<void> _onCancelWithdrawal(
    CancelWithdrawal event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      // Annuler le retrait
      await _paymentService.cancelWithdrawal(transactionId: event.transactionId);
      
      // Mettre à jour l'état
      emit(PaymentActionSuccess('Votre demande de retrait a été annulée'));
      
      // Recharger les données
      add(const LoadPayments(page: 1));
    } catch (e) {
      emit(PaymentError('Erreur lors de l\'annulation du retrait: ${e.toString()}'));
      
      // Restaurer l'état précédent
      if (state is PaymentsLoaded) {
        final currentState = state as PaymentsLoaded;
        emit(currentState);
      }
    }
  }
} 