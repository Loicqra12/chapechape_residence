import 'package:equatable/equatable.dart';
import 'package:chapechape_client/core/models/payment_model.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

// Événement pour créer une intention de paiement
class CreatePaymentIntent extends PaymentEvent {
  final String reservationId;
  final double amount;
  final PaymentMethod method;
  final String? phoneNumber;

  const CreatePaymentIntent({
    required this.reservationId,
    required this.amount,
    required this.method,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [reservationId, amount, method, phoneNumber];
}

// Événement pour confirmer un paiement
class ConfirmPayment extends PaymentEvent {
  final String paymentIntentId;
  final Map<String, dynamic> paymentData;

  const ConfirmPayment({
    required this.paymentIntentId,
    required this.paymentData,
  });

  @override
  List<Object> get props => [paymentIntentId, paymentData];
}

// Événement pour vérifier le statut d'un paiement
class CheckPaymentStatus extends PaymentEvent {
  final String paymentId;

  const CheckPaymentStatus({required this.paymentId});

  @override
  List<Object> get props => [paymentId];
}

// Événement pour charger l'historique des paiements
class LoadPaymentHistory extends PaymentEvent {
  final String? reservationId;

  const LoadPaymentHistory({this.reservationId});

  @override
  List<Object?> get props => [reservationId];
}

// Événement pour demander un remboursement
class RequestRefund extends PaymentEvent {
  final String paymentId;
  final String? reason;
  final double? amount; // Null pour un remboursement total

  const RequestRefund({
    required this.paymentId,
    this.reason,
    this.amount,
  });

  @override
  List<Object?> get props => [paymentId, reason, amount];
}

// Événement pour annuler un paiement en attente
class CancelPayment extends PaymentEvent {
  final String paymentId;
  final String? reason;

  const CancelPayment({
    required this.paymentId,
    this.reason,
  });

  @override
  List<Object?> get props => [paymentId, reason];
}

class InitiateExternalPayment extends PaymentEvent {
  final String method;
  final String reservationId;
  final String phoneNumber;
  final double amount;

  const InitiateExternalPayment({
    required this.method,
    required this.reservationId,
    required this.phoneNumber,
    required this.amount,
  });

  @override
  List<Object?> get props => [method, reservationId, phoneNumber, amount];
}

// Vérifier si l'événement PreparePayment existe et le créer si nécessaire
class PreparePayment extends PaymentEvent {
  final String reservationId;
  final PaymentMethod method;

  const PreparePayment({
    required this.reservationId,
    required this.method,
  });

  @override
  List<Object> get props => [reservationId, method];
}
