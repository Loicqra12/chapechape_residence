import 'package:flutter/material.dart' show IconData, Icons, Color, Colors;

/// Énumération des méthodes de paiement africaines disponibles
enum AfricanPaymentMethod {
  wave,
  orangeMoney,
  mtnMoney,
  moovMoney,
  cash,
  bankCard,
  bankTransfer,
  visa,
  mastercard,
  paypal,
  stripe
}

/// Énumération des catégories de méthodes de paiement
enum PaymentMethodCategory {
  mobileMoney,
  card,
  bank,
  cash,
  other
}

/// Extension pour ajouter des propriétés et méthodes aux méthodes de paiement africaines
extension AfricanPaymentMethodExtension on AfricanPaymentMethod {
  /// Retourne le nom d'affichage de la méthode de paiement
  String get displayName {
    switch (this) {
      case AfricanPaymentMethod.wave:
        return 'Wave';
      case AfricanPaymentMethod.orangeMoney:
        return 'Orange Money';
      case AfricanPaymentMethod.mtnMoney:
        return 'MTN Money';
      case AfricanPaymentMethod.moovMoney:
        return 'Moov Money';
      case AfricanPaymentMethod.cash:
        return 'Espèces';
      case AfricanPaymentMethod.bankCard:
        return 'Carte bancaire';
      case AfricanPaymentMethod.bankTransfer:
        return 'Virement bancaire';
      case AfricanPaymentMethod.visa:
        return 'Visa';
      case AfricanPaymentMethod.mastercard:
        return 'Mastercard';
      case AfricanPaymentMethod.paypal:
        return 'PayPal';
      case AfricanPaymentMethod.stripe:
        return 'Stripe';
    }
  }

  /// Retourne la description de la méthode de paiement
  String get description {
    switch (this) {
      case AfricanPaymentMethod.wave:
        return 'Paiement via l\'application Wave';
      case AfricanPaymentMethod.orangeMoney:
        return 'Paiement via Orange Money';
      case AfricanPaymentMethod.mtnMoney:
        return 'Paiement via MTN Mobile Money';
      case AfricanPaymentMethod.moovMoney:
        return 'Paiement via Moov Money';
      case AfricanPaymentMethod.cash:
        return 'Paiement en espèces';
      case AfricanPaymentMethod.bankCard:
        return 'Paiement par carte bancaire';
      case AfricanPaymentMethod.bankTransfer:
        return 'Paiement par virement bancaire';
      case AfricanPaymentMethod.visa:
        return 'Paiement par carte Visa';
      case AfricanPaymentMethod.mastercard:
        return 'Paiement par carte Mastercard';
      case AfricanPaymentMethod.paypal:
        return 'Paiement via PayPal';
      case AfricanPaymentMethod.stripe:
        return 'Paiement via Stripe';
    }
  }

  /// Retourne la catégorie de la méthode de paiement
  PaymentMethodCategory get category {
    switch (this) {
      case AfricanPaymentMethod.wave:
      case AfricanPaymentMethod.orangeMoney:
      case AfricanPaymentMethod.mtnMoney:
      case AfricanPaymentMethod.moovMoney:
        return PaymentMethodCategory.mobileMoney;
      case AfricanPaymentMethod.bankCard:
      case AfricanPaymentMethod.visa:
      case AfricanPaymentMethod.mastercard:
        return PaymentMethodCategory.card;
      case AfricanPaymentMethod.bankTransfer:
        return PaymentMethodCategory.bank;
      case AfricanPaymentMethod.cash:
        return PaymentMethodCategory.cash;
      case AfricanPaymentMethod.paypal:
      case AfricanPaymentMethod.stripe:
        return PaymentMethodCategory.other;
    }
  }

  /// Retourne une icône représentant la méthode de paiement
  IconData get icon {
    switch (this) {
      case AfricanPaymentMethod.wave:
      case AfricanPaymentMethod.orangeMoney:
      case AfricanPaymentMethod.mtnMoney:
      case AfricanPaymentMethod.moovMoney:
        return Icons.phone_android;
      case AfricanPaymentMethod.cash:
        return Icons.money;
      case AfricanPaymentMethod.bankCard:
      case AfricanPaymentMethod.visa:
      case AfricanPaymentMethod.mastercard:
        return Icons.credit_card;
      case AfricanPaymentMethod.bankTransfer:
        return Icons.account_balance;
      case AfricanPaymentMethod.paypal:
      case AfricanPaymentMethod.stripe:
        return Icons.payment;
    }
  }

  /// Retourne la couleur associée à la méthode de paiement
  Color get color {
    switch (this) {
      case AfricanPaymentMethod.wave:
        return Colors.blue;
      case AfricanPaymentMethod.orangeMoney:
        return Colors.orange;
      case AfricanPaymentMethod.mtnMoney:
        return Colors.yellow[800]!;
      case AfricanPaymentMethod.moovMoney:
        return Colors.deepOrange;
      case AfricanPaymentMethod.cash:
        return Colors.green;
      case AfricanPaymentMethod.bankCard:
        return Colors.purple;
      case AfricanPaymentMethod.visa:
        return Colors.blue[900]!;
      case AfricanPaymentMethod.mastercard:
        return Colors.red[700]!;
      case AfricanPaymentMethod.paypal:
        return Colors.blueAccent;
      case AfricanPaymentMethod.stripe:
        return Colors.purple[800]!;
      case AfricanPaymentMethod.bankTransfer:
        return Colors.indigo;
    }
  }

  /// Retourne le chemin de l'asset contenant le logo
  String? get logoAsset {
    switch (this) {
      case AfricanPaymentMethod.wave:
        return 'assets/images/payment/wave_money.png';
      case AfricanPaymentMethod.orangeMoney:
        return 'assets/images/payment/orange_money.png';
      case AfricanPaymentMethod.mtnMoney:
        return 'assets/images/payment/mtn_money.png';
      case AfricanPaymentMethod.moovMoney:
        return 'assets/images/payment/moov_money.png';
      case AfricanPaymentMethod.visa:
        return 'assets/images/payment/visa.png';
      case AfricanPaymentMethod.mastercard:
        return 'assets/images/payment/mastercard.png';
      case AfricanPaymentMethod.paypal:
        return 'assets/images/payment/paypal.png';
      // Images manquantes - retourner null pour utiliser des icônes à la place
      case AfricanPaymentMethod.cash:
      case AfricanPaymentMethod.bankCard:
      case AfricanPaymentMethod.stripe:
      case AfricanPaymentMethod.bankTransfer:
        return null;
    }
  }

  /// Retourne si la méthode nécessite un numéro de téléphone
  bool get requiresPhoneNumber {
    switch (this) {
      case AfricanPaymentMethod.wave:
      case AfricanPaymentMethod.orangeMoney:
      case AfricanPaymentMethod.mtnMoney:
      case AfricanPaymentMethod.moovMoney:
        return true;
      default:
        return false;
    }
  }
  
  /// Vérifie si la méthode de paiement a un logo disponible
  bool get hasLogo => logoAsset != null;

  /// Retourne si la méthode nécessite des informations bancaires
  bool get requiresBankDetails {
    switch (this) {
      case AfricanPaymentMethod.bankTransfer:
        return true;
      default:
        return false;
    }
  }
}

/// Modèle représentant les détails d'une méthode de paiement mobile
class MobileMoneyDetails {
  final String phoneNumber;
  final String? email;
  final String provider; // "wave", "orange", "mtn", "moov"
  
  const MobileMoneyDetails({
    required this.phoneNumber,
    this.email,
    required this.provider,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      if (email != null) 'email': email,
      'provider': provider,
    };
  }
  
  factory MobileMoneyDetails.fromJson(Map<String, dynamic> json) {
    return MobileMoneyDetails(
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      provider: json['provider'],
    );
  }
}

/// Modèle représentant les détails d'une carte bancaire
class BankCardDetails {
  final String holderName;
  final String lastFourDigits;
  final String cardType; // "visa", "mastercard", etc.
  
  const BankCardDetails({
    required this.holderName,
    required this.lastFourDigits,
    required this.cardType,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'holderName': holderName,
      'lastFourDigits': lastFourDigits,
      'cardType': cardType,
    };
  }
  
  factory BankCardDetails.fromJson(Map<String, dynamic> json) {
    return BankCardDetails(
      holderName: json['holderName'],
      lastFourDigits: json['lastFourDigits'],
      cardType: json['cardType'],
    );
  }
}

/// Modèle représentant les détails d'un virement bancaire
class BankTransferDetails {
  final String bankName;
  final String accountNumber;
  final String accountName;
  
  const BankTransferDetails({
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountName': accountName,
    };
  }
  
  factory BankTransferDetails.fromJson(Map<String, dynamic> json) {
    return BankTransferDetails(
      bankName: json['bankName'],
      accountNumber: json['accountNumber'],
      accountName: json['accountName'],
    );
  }
}

/// Interface pour les callbacks de paiement
abstract class PaymentResultCallback {
  void onPaymentSuccess(PaymentTransactionResult result);
  void onPaymentError(String errorMessage, String? errorCode);
  void onPaymentCancelled();
}

/// Modèle représentant le résultat d'une transaction de paiement
class PaymentTransactionResult {
  final String transactionId;
  final double amount;
  final AfricanPaymentMethod method;
  final String status;
  final DateTime timestamp;
  final Map<String, dynamic>? additionalData;
  
  const PaymentTransactionResult({
    required this.transactionId,
    required this.amount,
    required this.method,
    required this.status,
    required this.timestamp,
    this.additionalData,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'amount': amount,
      'method': method.toString().split('.').last,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      if (additionalData != null) 'additionalData': additionalData,
    };
  }
  
  factory PaymentTransactionResult.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionResult(
      transactionId: json['transactionId'],
      amount: json['amount'].toDouble(),
      method: _parsePaymentMethod(json['method']),
      status: json['status'],
      timestamp: DateTime.parse(json['timestamp']),
      additionalData: json['additionalData'],
    );
  }
  
  static AfricanPaymentMethod _parsePaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'wave':
        return AfricanPaymentMethod.wave;
      case 'orangemoney':
        return AfricanPaymentMethod.orangeMoney;
      case 'mtnmoney':
        return AfricanPaymentMethod.mtnMoney;
      case 'moovmoney':
        return AfricanPaymentMethod.moovMoney;
      case 'cash':
        return AfricanPaymentMethod.cash;
      case 'bankcard':
        return AfricanPaymentMethod.bankCard;
      case 'banktransfer':
        return AfricanPaymentMethod.bankTransfer;
      default:
        throw Exception('Invalid payment method: $method');
    }
  }
}
