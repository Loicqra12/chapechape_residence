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
  
  const PaymentModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.source,
    required this.date,
    required this.status,
    this.sourceId,
  });
  
  @override
  List<Object?> get props => [id, amount, type, source, date, status, sourceId];
  
  PaymentModel copyWith({
    String? id,
    double? amount,
    PaymentType? type,
    String? source,
    DateTime? date,
    String? status,
    String? sourceId,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      source: source ?? this.source,
      date: date ?? this.date,
      status: status ?? this.status,
      sourceId: sourceId ?? this.sourceId,
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