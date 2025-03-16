import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chapechape_client/core/blocs/payment/payment_event.dart';
import 'package:chapechape_client/core/blocs/payment/payment_state.dart';
import 'package:chapechape_client/core/models/payment_model.dart';
import 'package:chapechape_client/core/services/payment_service.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentService _paymentService;

  PaymentBloc({required PaymentService paymentService})
      : _paymentService = paymentService,
        super(const PaymentInitial()) {
    on<CreatePaymentIntent>(_onCreatePaymentIntent);
    on<ConfirmPayment>(_onConfirmPayment);
    on<CheckPaymentStatus>(_onCheckPaymentStatus);
    on<LoadPaymentHistory>(_onLoadPaymentHistory);
    on<RequestRefund>(_onRequestRefund);
    on<CancelPayment>(_onCancelPayment);
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
    try {
      emit(const PaymentLoading());

      final payment = await _paymentService.checkPaymentStatus(event.paymentId);
      emit(PaymentStatusChecked(payment));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
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

      emit(PaymentCancelled(event.paymentId));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }
}
