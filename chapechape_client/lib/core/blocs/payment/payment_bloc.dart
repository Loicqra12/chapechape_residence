import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chapechape_client/core/services/payment_service.dart';
import 'package:chapechape_client/core/services/booking_service.dart';
import 'package:chapechape_client/core/models/payment_model.dart';
import 'package:chapechape_client/core/blocs/payment/payment_event.dart';
import 'package:chapechape_client/core/blocs/payment/payment_state.dart';
import 'package:flutter/foundation.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentService _paymentService;
  final Map<String, DateTime> _lastCheckTimes = {};
  final Map<String, bool> _checkingStatus = {};
  final Map<String, int> _checkAttempts = {};
  static const Duration _checkCooldown = Duration(seconds: 3);
  static const int _maxAttempts = 10;
  static const Duration _maxPollingDuration = Duration(minutes: 5);

  PaymentBloc({
    required PaymentService paymentService,
  })  : _paymentService = paymentService,
        super(PaymentInitial()) {
    on<PreparePayment>(_onPreparePayment);
    on<CreatePaymentIntent>(_onCreatePaymentIntent);
    on<ConfirmPayment>(_onConfirmPayment);
    on<CheckPaymentStatus>(_onCheckPaymentStatus);
    on<LoadPaymentHistory>(_onLoadPaymentHistory);
    on<CancelPayment>(_onCancelPayment);
    on<InitiateExternalPayment>(_onInitiateExternalPayment);
  }

  Future<void> _onPreparePayment(
    PreparePayment event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(const PaymentLoading());
      
      // Récupérer le montant réel depuis la réservation
      try {
        final bookingService = await BookingService.initialize();
        final booking = await bookingService.getBookingById(event.reservationId);
        final amount = booking.totalPrice;
        
        emit(PaymentPrepared(
          reservationId: event.reservationId,
          method: event.method,
          amount: amount,
        ));
      } catch (bookingError) {
        // Fallback: utiliser un montant par défaut si impossible de récupérer la réservation
        if (kDebugMode) {
          print('⚠️ Impossible de récupérer le prix de la réservation: $bookingError');
        }
        double amount = 5000.0; // Montant par défaut réduit
        
        emit(PaymentPrepared(
          reservationId: event.reservationId,
          method: event.method,
          amount: amount,
        ));
      }
    } catch (e) {
      emit(PaymentError(message: 'Erreur lors de la préparation du paiement: ${e.toString()}'));
    }
  }

  Future<void> _onCreatePaymentIntent(
    CreatePaymentIntent event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(const PaymentLoading());

      final paymentIntent = await _paymentService.createPaymentIntent(
        bookingId: event.reservationId,
        amount: event.amount,
        method: event.method,
        phoneNumber: event.phoneNumber, // Ajout du paramètre phoneNumber
      );

      emit(PaymentIntentCreated(paymentIntent));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onConfirmPayment(
    ConfirmPayment event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(const PaymentLoading());

      final paymentData = event.paymentData ?? {};
      late Payment payment;

      // Déterminer le type de paiement basé sur les données
      if (paymentData.containsKey('phoneNumber') && paymentData.containsKey('provider')) {
        // Paiement Mobile Money
        payment = await _paymentService.confirmMobileMoneyPayment(
          paymentIntentId: event.paymentIntentId,
          phoneNumber: paymentData['phoneNumber'],
          provider: paymentData['provider'],
        );
      } else if (paymentData.containsKey('cardDetails')) {
        // Paiement par carte bancaire
        payment = await _paymentService.confirmCardPayment(
          paymentIntentId: event.paymentIntentId,
          cardDetails: paymentData['cardDetails'],
        );
      } else {
        throw Exception('Données de paiement invalides ou incomplètes');
      }

      // Vérifier le statut du paiement
      if (payment.status == PaymentStatus.pending) {
        // Paiement en attente de confirmation (par exemple redirection 3D Secure)
        emit(PaymentPending(
          paymentId: payment.id,
          message: 'Paiement en attente de confirmation',
          redirectUrl: paymentData['redirectUrl'],
        ));
      } else if (payment.status == PaymentStatus.succeeded) {
        // Paiement réussi
        emit(PaymentConfirmed(payment));
      } else {
        // Autres statuts (échec, etc.)
        emit(PaymentError(
          message: 'Le paiement a échoué: ${payment.status.displayName}',
          code: payment.status.toString(),
        ));
      }
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onCheckPaymentStatus(
    CheckPaymentStatus event,
    Emitter<PaymentState> emit,
  ) async {
    final paymentId = event.paymentId;
    
    // Vérifier si une vérification est déjà en cours
    if (_checkingStatus[paymentId] == true) {
      if (kDebugMode) {
        print('⚠️ Vérification déjà en cours pour $paymentId - ignorée');
      }
      return;
    }
    
    // Vérifier le nombre de tentatives
    final attempts = _checkAttempts[paymentId] ?? 0;
    if (attempts >= _maxAttempts) {
      if (kDebugMode) {
        print('🚫 Limite de tentatives atteinte pour $paymentId ($attempts/$_maxAttempts)');
      }
      emit(PaymentError(
        message: 'Délai d\'attente dépassé. Veuillez vérifier manuellement le statut du paiement.',
        code: 'POLLING_TIMEOUT'
      ));
      return;
    }
    
    // Vérifier la durée totale de polling
    final firstCheck = _lastCheckTimes[paymentId];
    if (firstCheck != null) {
      final totalPollingTime = DateTime.now().difference(firstCheck);
      if (totalPollingTime > _maxPollingDuration) {
        if (kDebugMode) {
          print('⏰ Durée maximale de polling dépassée pour $paymentId (${totalPollingTime.inMinutes}min)');
        }
        emit(PaymentError(
          message: 'Vérification du paiement interrompue après ${_maxPollingDuration.inMinutes} minutes.',
          code: 'POLLING_DURATION_EXCEEDED'
        ));
        return;
      }
    }
    
    // Vérifier le cooldown
    final lastCheck = _lastCheckTimes[paymentId];
    if (lastCheck != null) {
      final timeSinceLastCheck = DateTime.now().difference(lastCheck);
      if (timeSinceLastCheck < _checkCooldown) {
        if (kDebugMode) {
          print('🕰️ Cooldown actif pour $paymentId - attendre ${_checkCooldown.inSeconds - timeSinceLastCheck.inSeconds}s');
        }
        return;
      }
    }
    
    try {
      _checkingStatus[paymentId] = true;
      _lastCheckTimes[paymentId] ??= DateTime.now(); // Première fois seulement
      _checkAttempts[paymentId] = attempts + 1;
      
      if (kDebugMode) {
        print('🔍 Tentative ${_checkAttempts[paymentId]}/$_maxAttempts pour $paymentId');
      }
      
      emit(const PaymentLoading());

      final payment = await _paymentService.checkPaymentStatus(paymentId);
      emit(PaymentStatusChecked(payment));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    } finally {
      _checkingStatus[paymentId] = false;
    }
  }

  Future<void> _onLoadPaymentHistory(
    LoadPaymentHistory event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(const PaymentLoading());

      final payments = await _paymentService.getPaymentHistory(
        bookingId: event.reservationId,
      );

      emit(PaymentHistoryLoaded(payments));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onRequestRefund(
    RequestRefund event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(const PaymentLoading());

      final payment = await _paymentService.requestRefund(
        paymentId: event.paymentId,
        amount: event.amount,
        reason: event.reason,
      );

      final isFullRefund = event.amount == null;
      emit(RefundRequested(
        paymentId: payment.id,
        isFullRefund: isFullRefund,
        amount: event.amount,
      ));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onCancelPayment(
    CancelPayment event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(const PaymentLoading());

      await _paymentService.cancelPayment(
        paymentId: event.paymentId,
        reason: event.reason,
      );

      // Créer un paiement factice pour l'état annulé
      final cancelledPayment = Payment(
        id: event.paymentId,
        bookingId: 'unknown',
        userId: 'unknown',
        method: PaymentMethod.other,
        status: PaymentStatus.cancelled,
        amount: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      emit(PaymentCancelled(payment: cancelledPayment));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onInitiateExternalPayment(
    InitiateExternalPayment event,
    Emitter<PaymentState> emit,
  ) async {
    try {
      emit(const PaymentLoading());
      
      switch (event.method) {
        case 'wave':
          final result = await _paymentService.initiateWavePayment(
            reservationId: event.reservationId,
            amount: event.amount,
            phoneNumber: event.phoneNumber,
          );
          
          // Lancer Wave directement
          await _paymentService.launchWavePaymentInBrowser(result.paymentUrl ?? '');
          
          emit(PaymentExternalLaunched(
            method: 'wave',
            paymentUrl: result.paymentUrl ?? '',
            transactionId: result.transactionId ?? '',
            expiresAt: result.expiresAt ?? DateTime.now().add(Duration(minutes: 30)),
            phoneNumber: event.phoneNumber,
          ));
          break;
          
        case 'orange_money':
        case 'mtn_money':
        case 'moov_money':
          final result = await _paymentService.initiateCinetPayPayment(
            reservationId: event.reservationId,
            amount: event.amount,
            paymentMethod: event.method,
            phoneNumber: event.phoneNumber,
          );
          
          emit(PaymentExternalLaunched(
            method: event.method,
            paymentUrl: result.paymentUrl ?? '',
            transactionId: result.transactionId ?? '',
            expiresAt: result.expiresAt ?? DateTime.now().add(Duration(minutes: 30)),
            phoneNumber: event.phoneNumber,
          ));
          break;
          
        default:
          emit(const PaymentError(message: 'Méthode de paiement non supportée'));
      }
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }
}
