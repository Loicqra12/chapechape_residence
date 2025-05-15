import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

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

class TransactionResult {
  final List<PaymentModel> transactions;
  final double balance;
  final double monthlyRevenue;
  final double totalWithdrawals;
  
  const TransactionResult({
    required this.transactions,
    required this.balance,
    required this.monthlyRevenue,
    required this.totalWithdrawals,
  });
  
  factory TransactionResult.fromJson(Map<String, dynamic> json) {
    final transactions = (json['transactions'] as List)
        .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
    
    return TransactionResult(
      transactions: transactions,
      balance: (json['balance'] as num).toDouble(),
      monthlyRevenue: (json['monthly_revenue'] as num).toDouble(),
      totalWithdrawals: (json['total_withdrawals'] as num).toDouble(),
    );
  }
}