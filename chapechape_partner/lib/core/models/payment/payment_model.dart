import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart' show Colors, Color;

/// Énumération des méthodes de paiement disponibles (harmonisée avec client)
enum PaymentMethod {
  mobileMoney,
  orangeMoney,
  moovMoney,
  mtnMoney,
  wave,
  visa,
  mastercard,
  creditCard,
  bankTransfer,
  paypal,
  stripe,
  cash,
  cinetpayTransfer, // Spécifique aux transferts partenaires
  other
}

/// Énumération des statuts de paiement (harmonisée avec client)
enum PaymentStatus {
  pending,
  processing,
  succeeded,
  failed,
  refunded,
  cancelled
}

enum PaymentType { credit, withdrawal }

class PaymentModel extends Equatable {
  final String id;
  final double amount;
  final PaymentType type;
  final String source;
  final DateTime date;
  final String status; // 'pending', 'completed', 'cancelled', 'failed'
  final String? sourceId; // ID de la réservation associée, si applicable
  final double? commissionRate; // Taux de commission appliqué (ex: 0.10 pour 10%)
  final double? commissionAmount; // Montant de la commission
  final double? originalAmount; // Montant avant commission
  
  const PaymentModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.source,
    required this.date,
    required this.status,
    this.sourceId,
    this.commissionRate,
    this.commissionAmount,
    this.originalAmount,
  });
  
  @override
  List<Object?> get props => [
    id, amount, type, source, date, status, 
    sourceId, commissionRate, commissionAmount, originalAmount
  ];
  
  PaymentModel copyWith({
    String? id,
    double? amount,
    PaymentType? type,
    String? source,
    DateTime? date,
    String? status,
    String? sourceId,
    double? commissionRate,
    double? commissionAmount,
    double? originalAmount,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      source: source ?? this.source,
      date: date ?? this.date,
      status: status ?? this.status,
      sourceId: sourceId ?? this.sourceId,
      commissionRate: commissionRate ?? this.commissionRate,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      originalAmount: originalAmount ?? this.originalAmount,
    );
  }
  
  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] == 'credit' ? PaymentType.credit : PaymentType.withdrawal,
      source: json['source'] as String,
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String,
      sourceId: json['source_id'] as String?,
      commissionRate: json['commission_rate'] != null 
          ? (json['commission_rate'] as num).toDouble() 
          : null,
      commissionAmount: json['commission_amount'] != null 
          ? (json['commission_amount'] as num).toDouble() 
          : null,
      originalAmount: json['original_amount'] != null 
          ? (json['original_amount'] as num).toDouble() 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type == PaymentType.credit ? 'credit' : 'withdrawal',
      'source': source,
      'date': date.toIso8601String(),
      'status': status,
      'source_id': sourceId,
      if (commissionRate != null) 'commission_rate': commissionRate,
      if (commissionAmount != null) 'commission_amount': commissionAmount,
      if (originalAmount != null) 'original_amount': originalAmount,
    };
  }
  
  String get formattedAmount {
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    
    return formatter.format(amount);
  }
  
  String get formattedDate {
    final formatter = DateFormat('dd/MM/yyyy', 'fr_FR');
    return formatter.format(date);
  }
  
  String get fullFormattedDate {
    final formatter = DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR');
    return formatter.format(date);
  }
  
  // Formatage du montant original (avant commission)
  String get formattedOriginalAmount {
    if (originalAmount == null) return formattedAmount;
    
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    
    return formatter.format(originalAmount);
  }
  
  // Formatage du montant de la commission
  String get formattedCommissionAmount {
    if (commissionAmount == null) return '';
    
    final formatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    
    return formatter.format(commissionAmount);
  }
  
  // Formatage du pourcentage de la commission
  String get formattedCommissionRate {
    if (commissionRate == null) return '';
    return '${(commissionRate! * 100).toStringAsFixed(0)}%';
  }
  
  // Vérifier si une commission a été appliquée
  bool get hasCommission => commissionRate != null && commissionAmount != null;
  
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isFailed => status == 'failed';
}

/// Extensions harmonisées pour PaymentMethod (cohérent avec client)
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
      case PaymentMethod.cinetpayTransfer:
        return 'CinetPay Transfer';
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
      case PaymentMethod.cinetpayTransfer:
        return 'assets/icons/cinetpay.png';
      case PaymentMethod.other:
        return 'assets/icons/payment.png';
    }
  }
}

/// Extensions harmonisées pour PaymentStatus (cohérent avec client)
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

/// Classe harmonisée pour la commission de paiement (cohérent avec client)
class PaymentCommission extends Equatable {
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

  @override
  List<Object?> get props => [rate, totalAmount, commissionAmount, partnerAmount];
}

/// Fonctions utilitaires pour parser les énumérations depuis des chaînes
PaymentMethod parsePaymentMethod(String value) {
  switch (value.toLowerCase()) {
    case 'mobilemoney':
    case 'momo':
      return PaymentMethod.mobileMoney;
    case 'orangemoney':
    case 'orange_money':
      return PaymentMethod.orangeMoney;
    case 'moovmoney':
    case 'moov_money':
      return PaymentMethod.moovMoney;
    case 'mtnmoney':
    case 'mtn_money':
      return PaymentMethod.mtnMoney;
    case 'wave':
      return PaymentMethod.wave;
    case 'visa':
      return PaymentMethod.visa;
    case 'mastercard':
      return PaymentMethod.mastercard;
    case 'creditcard':
    case 'credit_card':
      return PaymentMethod.creditCard;
    case 'banktransfer':
    case 'bank_transfer':
      return PaymentMethod.bankTransfer;
    case 'paypal':
      return PaymentMethod.paypal;
    case 'stripe':
      return PaymentMethod.stripe;
    case 'cash':
      return PaymentMethod.cash;
    case 'cinetpaytransfer':
    case 'cinetpay_transfer':
      return PaymentMethod.cinetpayTransfer;
    default:
      return PaymentMethod.other;
  }
}

PaymentStatus parsePaymentStatus(String value) {
  switch (value.toLowerCase()) {
    case 'pending':
      return PaymentStatus.pending;
    case 'processing':
      return PaymentStatus.processing;
    case 'succeeded':
    case 'completed':
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

class TransactionResult {
  final List<PaymentModel> transactions;
  final double balance;
  final double monthlyRevenue;
  final double totalWithdrawals;
  final bool hasReachedMax;
  
  const TransactionResult({
    required this.transactions,
    required this.balance,
    required this.monthlyRevenue,
    required this.totalWithdrawals,
    this.hasReachedMax = false,
  });
  
  factory TransactionResult.fromJson(Map<String, dynamic> json) {
    // Le backend retourne {"success": true, "data": [...]}
    // Adapter pour cette structure
    final dataList = json['data'] ?? json['transactions'] ?? [];
    final transactions = (dataList as List)
        .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
    
    return TransactionResult(
      transactions: transactions,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      monthlyRevenue: (json['monthly_revenue'] as num?)?.toDouble() ?? 0.0,
      totalWithdrawals: (json['total_withdrawals'] as num?)?.toDouble() ?? 0.0,
      hasReachedMax: json['has_reached_max'] as bool? ?? transactions.isEmpty,
    );
  }
}