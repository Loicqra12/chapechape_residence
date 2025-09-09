import 'package:equatable/equatable.dart';
import 'package:chapechape_client/core/models/payment_model.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

// État initial
class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

// État lorsque le paiement est préparé
class PaymentPrepared extends PaymentState {
  final String reservationId;
  final PaymentMethod method;
  final double amount;

  const PaymentPrepared({
    required this.reservationId,
    required this.method,
    required this.amount,
  });

  @override
  List<Object> get props => [reservationId, method];
}

// État de chargement
class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

// État lorsqu'une intention de paiement est créée
class PaymentIntentCreated extends PaymentState {
  final PaymentIntent paymentIntent;

  const PaymentIntentCreated(this.paymentIntent);

  @override
  List<Object?> get props => [paymentIntent];
}

// État lorsqu'un paiement est confirmé avec succès
class PaymentConfirmed extends PaymentState {
  final Payment payment;

  const PaymentConfirmed(this.payment);

  @override
  List<Object?> get props => [payment];
}

// État lorsqu'un paiement est en attente de confirmation (ex: 3DS, OTP, etc.)
class PaymentPending extends PaymentState {
  final String paymentId;
  final String message;
  final String? redirectUrl;

  const PaymentPending({
    required this.paymentId,
    required this.message,
    this.redirectUrl,
  });

  @override
  List<Object?> get props => [paymentId, message, redirectUrl];
}

// État lorsqu'on vérifie le statut d'un paiement
class PaymentStatusChecked extends PaymentState {
  final Payment payment;

  const PaymentStatusChecked(this.payment);

  @override
  List<Object?> get props => [payment];
}

// État lorsque l'historique des paiements est chargé
class PaymentHistoryLoaded extends PaymentState {
  final List<Payment> payments;

  const PaymentHistoryLoaded(this.payments);

  @override
  List<Object?> get props => [payments];
}

// État lorsqu'un remboursement est demandé
class RefundRequested extends PaymentState {
  final String paymentId;
  final bool isFullRefund;
  final double? amount;

  const RefundRequested({
    required this.paymentId,
    required this.isFullRefund,
    this.amount,
  });

  @override
  List<Object?> get props => [paymentId, isFullRefund, amount];
}

// État lorsqu'un paiement est annulé
class PaymentCancelled extends PaymentState {
  final Payment payment;
  final String? reason;

  const PaymentCancelled({
    required this.payment,
    this.reason,
  });

  @override
  List<Object?> get props => [payment, reason];
}

class PaymentExternalLaunched extends PaymentState {
  final String method;
  final String paymentUrl;
  final String transactionId;
  final DateTime expiresAt;
  final String? phoneNumber;

  const PaymentExternalLaunched({
    required this.method,
    required this.paymentUrl,
    required this.transactionId,
    required this.expiresAt,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [method, paymentUrl, transactionId, expiresAt, phoneNumber];
}

// État d'erreur de paiement
class PaymentError extends PaymentState {
  final String message;
  final String? code;
  final String? declineCode;

  const PaymentError({
    required this.message,
    this.code,
    this.declineCode,
  });

  @override
  List<Object?> get props => [message, code, declineCode];
}
