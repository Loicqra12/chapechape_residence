import 'package:flutter/material.dart' show Colors, Color;

/// Énumération des méthodes de paiement disponibles
enum PaymentMethod {
  mobileMoney,
  visa,
  mastercard,
  wave,
  paypal,
  stripe,
  cash,
  other
}

/// Énumération des statuts de paiement
enum PaymentStatus {
  pending,
  processing,
  succeeded,
  failed,
  refunded,
  cancelled
}

/// Extension pour obtenir un label d'affichage pour les méthodes de paiement
extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.visa:
        return 'Visa';
      case PaymentMethod.mastercard:
        return 'Mastercard';
      case PaymentMethod.wave:
        return 'Wave';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.stripe:
        return 'Carte de crédit';
      case PaymentMethod.cash:
        return 'Espèces';
      case PaymentMethod.other:
        return 'Autre';
    }
  }

  String get iconPath {
    switch (this) {
      case PaymentMethod.mobileMoney:
        return 'assets/icons/momo.png';
      case PaymentMethod.visa:
        return 'assets/icons/visa.png';
      case PaymentMethod.mastercard:
        return 'assets/icons/mastercard.png';
      case PaymentMethod.wave:
        return 'assets/icons/wave.png';
      case PaymentMethod.paypal:
        return 'assets/icons/paypal.png';
      case PaymentMethod.stripe:
        return 'assets/icons/stripe.png';
      case PaymentMethod.cash:
        return 'assets/icons/cash.png';
      case PaymentMethod.other:
        return 'assets/icons/payment.png';
    }
  }
}

/// Extension pour obtenir un label d'affichage pour les statuts de paiement
extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'En attente';
      case PaymentStatus.processing:
        return 'En cours';
      case PaymentStatus.succeeded:
        return 'Réussi';
      case PaymentStatus.failed:
        return 'Échoué';
      case PaymentStatus.refunded:
        return 'Remboursé';
      case PaymentStatus.cancelled:
        return 'Annulé';
    }
  }

  Color get color {
    switch (this) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.processing:
        return Colors.blue;
      case PaymentStatus.succeeded:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.purple;
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
  }
}

class Payment {
  final String id;
  final String bookingId;
  final String userId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? transactionId; // ID de transaction externe
  final String? receiptUrl; // URL du reçu
  final Map<String, dynamic>? metadata; // Données supplémentaires
  final bool isRefundable;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? bookingResidenceName; // Propriété manquante pour le nom de la résidence
  
  // Getter pour garantir la compatibilité avec les nouveaux noms
  String get reservationId => bookingId;
  
  const Payment({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    this.receiptUrl,
    this.metadata,
    this.isRefundable = false,
    this.paidAt,
    required this.createdAt,
    this.updatedAt,
    this.bookingResidenceName,
  });
  
  // Méthode copyWith pour créer une copie modifiée
  Payment copyWith({
    String? id,
    String? bookingId,
    String? userId,
    double? amount,
    PaymentMethod? method,
    PaymentStatus? status,
    String? transactionId,
    String? receiptUrl,
    Map<String, dynamic>? metadata,
    bool? isRefundable,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? bookingResidenceName,
  }) {
    return Payment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      metadata: metadata ?? this.metadata,
      isRefundable: isRefundable ?? this.isRefundable,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bookingResidenceName: bookingResidenceName ?? this.bookingResidenceName,
    );
  }
  
  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      method: _parsePaymentMethod(json['method']),
      status: _parsePaymentStatus(json['status']),
      transactionId: json['transactionId'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isRefundable: json['isRefundable'] as bool? ?? false,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      bookingResidenceName: json['bookingResidenceName'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'userId': userId,
      'amount': amount,
      'method': method.toString().split('.').last,
      'status': status.toString().split('.').last,
      if (transactionId != null) 'transactionId': transactionId,
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
      if (metadata != null) 'metadata': metadata,
      'isRefundable': isRefundable,
      if (paidAt != null) 'paidAt': paidAt!.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (bookingResidenceName != null) 'bookingResidenceName': bookingResidenceName,
    };
  }
}

class PaymentIntent {
  final String id;
  final String bookingId;
  final String userId;
  final double amount;
  final PaymentMethod method;
  final String clientSecret; // Secret client pour les SDK de paiement
  final String? publicKey; // Clé publique (pour certains fournisseurs)
  final Map<String, dynamic>? paymentParams; // Paramètres spécifiques
  final bool isTest;
  final DateTime expiresAt;
  final DateTime createdAt;
  
  // Getter pour garantir la compatibilité avec les nouveaux noms
  String get reservationId => bookingId;
  
  const PaymentIntent({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.method,
    required this.clientSecret,
    this.publicKey,
    this.paymentParams,
    this.isTest = false,
    required this.expiresAt,
    required this.createdAt,
  });
  
  factory PaymentIntent.fromJson(Map<String, dynamic> json) {
    return PaymentIntent(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      method: _parsePaymentMethod(json['method']),
      clientSecret: json['clientSecret'] as String,
      publicKey: json['publicKey'] as String?,
      paymentParams: json['paymentParams'] as Map<String, dynamic>?,
      isTest: json['isTest'] as bool? ?? false,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'userId': userId,
      'amount': amount,
      'method': method.toString().split('.').last,
      'clientSecret': clientSecret,
      if (publicKey != null) 'publicKey': publicKey,
      if (paymentParams != null) 'paymentParams': paymentParams,
      'isTest': isTest,
      'expiresAt': expiresAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class MobileMoneyPaymentDetails {
  final String phoneNumber;
  final String provider; // Orange, MTN, Moov, etc.
  final String? countryCode;
  final String? reference;
  
  const MobileMoneyPaymentDetails({
    required this.phoneNumber,
    required this.provider,
    this.countryCode,
    this.reference,
  });
  
  factory MobileMoneyPaymentDetails.fromJson(Map<String, dynamic> json) {
    return MobileMoneyPaymentDetails(
      phoneNumber: json['phoneNumber'] as String,
      provider: json['provider'] as String,
      countryCode: json['countryCode'] as String?,
      reference: json['reference'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'provider': provider,
      if (countryCode != null) 'countryCode': countryCode,
      if (reference != null) 'reference': reference,
    };
  }
}

class CardPaymentDetails {
  final String last4;
  final String brand; // visa, mastercard, etc.
  final String expiryMonth;
  final String expiryYear;
  final String? country;
  final String? cardholderName;
  
  const CardPaymentDetails({
    required this.last4,
    required this.brand,
    required this.expiryMonth,
    required this.expiryYear,
    this.country,
    this.cardholderName,
  });
  
  factory CardPaymentDetails.fromJson(Map<String, dynamic> json) {
    return CardPaymentDetails(
      last4: json['last4'] as String,
      brand: json['brand'] as String,
      expiryMonth: json['expiryMonth'] as String,
      expiryYear: json['expiryYear'] as String,
      country: json['country'] as String?,
      cardholderName: json['cardholderName'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'last4': last4,
      'brand': brand,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      if (country != null) 'country': country,
      if (cardholderName != null) 'cardholderName': cardholderName,
    };
  }
}

// Fonctions utilitaires pour parser les énumérations depuis des chaînes
PaymentMethod _parsePaymentMethod(String value) {
  switch (value) {
    case 'mobileMoney':
    case 'momo':
      return PaymentMethod.mobileMoney;
    case 'visa':
      return PaymentMethod.visa;
    case 'mastercard':
      return PaymentMethod.mastercard;
    case 'wave':
      return PaymentMethod.wave;
    case 'paypal':
      return PaymentMethod.paypal;
    case 'stripe':
      return PaymentMethod.stripe;
    case 'cash':
      return PaymentMethod.cash;
    default:
      return PaymentMethod.other;
  }
}

PaymentStatus _parsePaymentStatus(String value) {
  switch (value) {
    case 'pending':
      return PaymentStatus.pending;
    case 'processing':
      return PaymentStatus.processing;
    case 'succeeded':
      return PaymentStatus.succeeded;
    case 'failed':
      return PaymentStatus.failed;
    case 'refunded':
      return PaymentStatus.refunded;
    case 'cancelled':
      return PaymentStatus.cancelled;
    default:
      return PaymentStatus.pending;
  }
}
