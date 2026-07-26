import 'package:flutter/material.dart' show Colors, Color;

/// Énumération des méthodes de paiement disponibles
enum PaymentMethod {
  mobileMoney,
  orangeMoney,   // Nouveau: Orange Money
  moovMoney,     // Nouveau: Moov Money
  mtnMoney,      // Nouveau: MTN Money
  wave,
  visa,
  mastercard,
  creditCard,    // Nouveau: Carte de crédit générique
  bankTransfer,  // Nouveau: Virement bancaire
  paypal,
  stripe,
  cash,
  other
}

/// Exception spécifique CinetPay
class CinetPayException implements Exception {
  final String message;
  final String? code;

  CinetPayException(this.message, [this.code]);

  @override
  String toString() => 'CinetPayException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Résultat de l'initiation d'un paiement Wave
class WavePaymentResult {
  final bool success;
  final String? transactionId;
  final String? paymentUrl;
  final String? paymentToken;
  final String? errorMessage;
  final DateTime? expiresAt;

  WavePaymentResult({
    required this.success,
    this.transactionId,
    this.paymentUrl,
    this.paymentToken,
    this.errorMessage,
    this.expiresAt,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// Statut d'un paiement Wave
class WavePaymentStatus {
  final String transactionId;
  final PaymentStatus status;
  final double? amount;
  final String? currency;
  final String? message;
  final DateTime? processedAt;

  WavePaymentStatus({
    required this.transactionId,
    required this.status,
    this.amount,
    this.currency,
    this.message,
    this.processedAt,
  });

  bool get isPaid => status == PaymentStatus.succeeded;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isPending => status == PaymentStatus.pending;
}

/// Exception spécifique Wave
class WaveException implements Exception {
  final String message;
  final String? code;

  WaveException(this.message, [this.code]);

  @override
  String toString() => 'WaveException: $message${code != null ? ' (Code: $code)' : ''}';
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
      case PaymentMethod.orangeMoney:
        return 'Orange Money';
      case PaymentMethod.moovMoney:
        return 'Moov Money';
      case PaymentMethod.mtnMoney:
        return 'MTN Money';
      case PaymentMethod.wave:
        return 'Wave';
      case PaymentMethod.visa:
        return 'Visa';
      case PaymentMethod.mastercard:
        return 'Mastercard';
      case PaymentMethod.creditCard:
        return 'Carte de crédit';
      case PaymentMethod.bankTransfer:
        return 'Virement bancaire';
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
      case PaymentMethod.orangeMoney:
        return 'assets/icons/orange_money.png';
      case PaymentMethod.moovMoney:
        return 'assets/icons/moov_money.png';
      case PaymentMethod.mtnMoney:
        return 'assets/icons/mtn_money.png';
      case PaymentMethod.wave:
        return 'assets/icons/wave.png';
      case PaymentMethod.visa:
        return 'assets/icons/visa.png';
      case PaymentMethod.mastercard:
        return 'assets/icons/mastercard.png';
      case PaymentMethod.creditCard:
        return 'assets/icons/credit_card.png';
      case PaymentMethod.bankTransfer:
        return 'assets/icons/bank_transfer.png';
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

/// Modèle pour la commission de paiement
class PaymentCommission {
  /// Taux de commission (par défaut 10%)
  final double rate;
  
  /// Montant total de la transaction
  final double totalAmount;
  
  /// Montant de la commission calculé
  final double commissionAmount;
  
  /// Montant que recevra le partenaire
  final double partnerAmount;
  
  /// Constructeur avec calcul automatique des montants
  PaymentCommission({
    this.rate = 0.10,
    required this.totalAmount,
  }) : 
    commissionAmount = totalAmount * rate,
    partnerAmount = totalAmount * (1 - rate);
  
  /// Constructeur avec tous les champs
  const PaymentCommission.withAmounts({
    required this.rate,
    required this.totalAmount,
    required this.commissionAmount,
    required this.partnerAmount,
  });
  
  /// Création depuis un objet JSON
  factory PaymentCommission.fromJson(Map<String, dynamic> json) {
    return PaymentCommission.withAmounts(
      rate: (json['rate'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      commissionAmount: (json['commissionAmount'] as num).toDouble(),
      partnerAmount: (json['partnerAmount'] as num).toDouble(),
    );
  }
  
  /// Conversion en JSON
  Map<String, dynamic> toJson() {
    return {
      'rate': rate,
      'totalAmount': totalAmount,
      'commissionAmount': commissionAmount,
      'partnerAmount': partnerAmount,
    };
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
  
  // Nouvelle propriété pour la commission
  final PaymentCommission? commission;
  
  // Getters pour garantir la compatibilité avec les nouveaux noms
  String get reservationId => bookingId;
  
  // Getters pour la commission avec valeurs par défaut
  double get commissionRate => commission?.rate ?? 0.10;
  double get commissionAmount => commission?.commissionAmount ?? (amount * commissionRate);
  double get partnerAmount => commission?.partnerAmount ?? (amount - commissionAmount);
  
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
    this.commission,
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
    PaymentCommission? commission,
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
      commission: commission ?? this.commission,
    );
  }
  
  /// Calcule une commission en fonction du taux spécifié
  PaymentCommission calculateCommission({double? rate}) {
    final effectiveRate = rate ?? commissionRate;
    return PaymentCommission(
      rate: effectiveRate,
      totalAmount: amount,
    );
  }
  
  /// Crée un paiement à partir d'un objet JSON
  factory Payment.fromJson(Map<String, dynamic> json) {
    final bookingRaw = json['bookingId'] ?? json['reservationId'];
    final bookingId = bookingRaw?.toString() ?? '';
    final userId = json['userId']?.toString() ?? 'unknown';
    final methodRaw = (json['method'] ?? json['paymentMethod'])?.toString();
    return Payment(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      bookingId: bookingId,
      userId: userId,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      method: _parsePaymentMethod(methodRaw ?? ''),
      status: _parsePaymentStatus(json['status']),
      transactionId: json['transactionId'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isRefundable: json['isRefundable'] as bool? ?? false,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      bookingResidenceName: json['bookingResidenceName'] as String?,
      commission: json['commission'] != null 
          ? PaymentCommission.fromJson(json['commission'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Crée un paiement à partir de la réponse backend
  factory Payment.fromBackendJson(Map<String, dynamic> json) {
    final reservationRaw = json['reservation'];
    String bookingId = '';
    if (reservationRaw is String) {
      bookingId = reservationRaw;
    } else if (reservationRaw is Map<String, dynamic>) {
      bookingId = reservationRaw['_id']?.toString() ?? '';
    } else if (reservationRaw is Map) {
      bookingId = reservationRaw['_id']?.toString() ?? '';
    }

    final userRaw = json['user'];
    final reservationUserRaw = reservationRaw is Map ? reservationRaw['user'] : null;
    final userId = userRaw?.toString() ?? reservationUserRaw?.toString() ?? 'unknown';
    final methodRaw = (json['paymentMethod'] ?? json['method'])?.toString();
    return Payment(
      id: json['_id']?.toString() ?? json['paymentId']?.toString() ?? '',
      bookingId: bookingId,
      userId: userId,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      method: _parsePaymentMethod(methodRaw ?? ''),
      status: _parsePaymentStatus(json['status']),
      transactionId: json['transactionId'] as String?,
      receiptUrl: json['receiptUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      isRefundable: json['isRefundable'] as bool? ?? false,
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      bookingResidenceName: json['bookingResidenceName'] as String?,
      commission: json['commission'] != null 
          ? PaymentCommission.fromJson(json['commission'] as Map<String, dynamic>)
          : null,
    );
  }
  
  /// Convertit le paiement en objet JSON
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
      if (commission != null) 'commission': commission!.toJson(),
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

  /// Crée un PaymentIntent à partir de la réponse backend
  factory PaymentIntent.fromBackendJson(Map<String, dynamic> json) {
    return PaymentIntent(
      id: json['_id'] ?? json['paymentId'] as String,
      bookingId: json['reservation'] as String,
      userId: json['user'] ?? 'unknown',
      amount: (json['amount'] as num).toDouble(),
      method: _parsePaymentMethod(json['paymentMethod'] ?? json['method']),
      clientSecret: json['transactionId'] ?? json['paymentToken'] ?? '',
      publicKey: json['publicKey'] as String?,
      paymentParams: {
        'paymentUrl': json['paymentUrl'],
        'paymentToken': json['paymentToken'],
        'transactionId': json['transactionId'],
        'provider': json['paymentProvider'],
        'providerResponse': json['providerResponse'],
      },
      isTest: json['isTest'] as bool? ?? false,
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt'] as String)
          : DateTime.now().add(Duration(hours: 1)),
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
    case 'orangeMoney':
    case 'orange_money':
      return PaymentMethod.orangeMoney;
    case 'moovMoney':
    case 'moov_money':
      return PaymentMethod.moovMoney;
    case 'mtnMoney':
    case 'mtn_money':
      return PaymentMethod.mtnMoney;
    case 'wave':
      return PaymentMethod.wave;
    case 'visa':
      return PaymentMethod.visa;
    case 'mastercard':
      return PaymentMethod.mastercard;
    case 'creditCard':
    case 'credit_card':
      return PaymentMethod.creditCard;
    case 'bankTransfer':
    case 'bank_transfer':
      return PaymentMethod.bankTransfer;
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

PaymentStatus _parsePaymentStatus(String? value) {
  switch (value?.toLowerCase()) {
    case 'paid':
    case 'completed':
    case 'succeeded':
    case 'success':
      return PaymentStatus.succeeded;
    case 'processing':
      return PaymentStatus.processing;
    case 'failed':
    case 'error':
    case 'rejected':
      return PaymentStatus.failed;
    case 'refunded':
      return PaymentStatus.refunded;
    case 'cancelled':
    case 'canceled':
      return PaymentStatus.cancelled;
    case 'pending':
    default:
      return PaymentStatus.pending;
  }
}
