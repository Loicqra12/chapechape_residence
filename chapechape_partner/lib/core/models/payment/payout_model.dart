import 'package:equatable/equatable.dart';

/// États possibles d'un payout selon le backend
enum PayoutStatus {
  scheduled,
  pending, 
  success,
  failed,
}

extension PayoutStatusExtension on PayoutStatus {
  String get displayName {
    switch (this) {
      case PayoutStatus.scheduled:
        return 'Programmé';
      case PayoutStatus.pending:
        return 'En cours';
      case PayoutStatus.success:
        return 'Effectué';
      case PayoutStatus.failed:
        return 'Échec';
    }
  }

  String get color {
    switch (this) {
      case PayoutStatus.scheduled:
        return '#FFA726'; // Orange
      case PayoutStatus.pending:
        return '#42A5F5'; // Bleu
      case PayoutStatus.success:
        return '#66BB6A'; // Vert
      case PayoutStatus.failed:
        return '#EF5350'; // Rouge
    }
  }

  static PayoutStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return PayoutStatus.scheduled;
      case 'pending':
        return PayoutStatus.pending;
      case 'success':
        return PayoutStatus.success;
      case 'failed':
        return PayoutStatus.failed;
      default:
        return PayoutStatus.scheduled;
    }
  }
}

/// Modèle représentant un payout/reversement pour un partenaire
/// Compatible avec payout.model.js backend
class PayoutModel extends Equatable {
  final String id;
  final String payoutId; // payout_id unique backend
  final String partnerId;
  final List<String> sourceTransactions; // source_transactions
  final double grossAmount; // gross_amount
  final double commissionAmount; // commission_amount
  final double commissionRate; // commission_rate 
  final double netAmount; // net_amount
  final String currency;
  final PayoutStatus status;
  final DateTime scheduledDate; // scheduled_date
  final DateTime? processedDate; // processed_date
  final String? transactionId; // cinetpay transaction_id
  final String? failureReason;
  final Map<String, dynamic>? cinetpayInfo; // cinetpay_info
  final DateTime createdAt;
  final DateTime updatedAt;

  // Informations enrichies pour l'affichage
  final String? partnerName;
  final String? partnerPhone;
  final List<ReservationInfo>? reservations;

  const PayoutModel({
    required this.id,
    required this.payoutId,
    required this.partnerId,
    required this.sourceTransactions,
    required this.grossAmount,
    required this.commissionAmount,
    required this.commissionRate,
    required this.netAmount,
    required this.currency,
    required this.status,
    required this.scheduledDate,
    this.processedDate,
    this.transactionId,
    this.failureReason,
    this.cinetpayInfo,
    required this.createdAt,
    required this.updatedAt,
    this.partnerName,
    this.partnerPhone,
    this.reservations,
  });

  @override
  List<Object?> get props => [
    id, payoutId, partnerId, sourceTransactions, grossAmount,
    commissionAmount, commissionRate, netAmount, currency, status,
    scheduledDate, processedDate, transactionId, failureReason,
    cinetpayInfo, createdAt, updatedAt, partnerName, partnerPhone,
    reservations,
  ];

  /// Crée une instance depuis JSON (API response backend)
  factory PayoutModel.fromJson(Map<String, dynamic> json) {
    return PayoutModel(
      id: json['_id'] ?? json['id'] ?? '',
      payoutId: json['payout_id'] ?? '',
      partnerId: json['partner'] is String 
          ? json['partner'] 
          : json['partner']?['_id'] ?? '',
      sourceTransactions: (json['source_transactions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      grossAmount: (json['gross_amount'] ?? 0.0).toDouble(),
      commissionAmount: (json['commission_amount'] ?? 0.0).toDouble(),
      commissionRate: (json['commission_rate'] ?? 0.0).toDouble(),
      netAmount: (json['net_amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'XOF',
      status: PayoutStatusExtension.fromString(json['status'] ?? 'scheduled'),
      scheduledDate: DateTime.parse(json['scheduled_date'] ?? json['createdAt']),
      processedDate: json['processed_date'] != null 
          ? DateTime.parse(json['processed_date']) 
          : null,
      transactionId: json['cinetpay_info']?['transaction_id'],
      failureReason: json['failure_reason'],
      cinetpayInfo: json['cinetpay_info'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      partnerName: json['partner'] is Map ? json['partner']['name'] : null,
      partnerPhone: json['partner'] is Map ? json['partner']['phone_number'] : null,
      reservations: json['reservations'] != null
          ? (json['reservations'] as List)
              .map((r) => ReservationInfo.fromJson(r))
              .toList()
          : null,
    );
  }

  /// Convertit en JSON pour les requêtes API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payout_id': payoutId,
      'partner': partnerId,
      'source_transactions': sourceTransactions,
      'gross_amount': grossAmount,
      'commission_amount': commissionAmount,
      'commission_rate': commissionRate,
      'net_amount': netAmount,
      'currency': currency,
      'status': status.name,
      'scheduled_date': scheduledDate.toIso8601String(),
      'processed_date': processedDate?.toIso8601String(),
      'failure_reason': failureReason,
      'cinetpay_info': cinetpayInfo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Copie avec modifications
  PayoutModel copyWith({
    String? id,
    String? payoutId,
    String? partnerId,
    List<String>? sourceTransactions,
    double? grossAmount,
    double? commissionAmount,
    double? commissionRate,
    double? netAmount,
    String? currency,
    PayoutStatus? status,
    DateTime? scheduledDate,
    DateTime? processedDate,
    String? transactionId,
    String? failureReason,
    Map<String, dynamic>? cinetpayInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? partnerName,
    String? partnerPhone,
    List<ReservationInfo>? reservations,
  }) {
    return PayoutModel(
      id: id ?? this.id,
      payoutId: payoutId ?? this.payoutId,
      partnerId: partnerId ?? this.partnerId,
      sourceTransactions: sourceTransactions ?? this.sourceTransactions,
      grossAmount: grossAmount ?? this.grossAmount,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      commissionRate: commissionRate ?? this.commissionRate,
      netAmount: netAmount ?? this.netAmount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      processedDate: processedDate ?? this.processedDate,
      transactionId: transactionId ?? this.transactionId,
      failureReason: failureReason ?? this.failureReason,
      cinetpayInfo: cinetpayInfo ?? this.cinetpayInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      partnerName: partnerName ?? this.partnerName,
      partnerPhone: partnerPhone ?? this.partnerPhone,
      reservations: reservations ?? this.reservations,
    );
  }

  /// Formatage des montants avec devise
  String get formattedGrossAmount => '${grossAmount.toStringAsFixed(0)} $currency';
  String get formattedNetAmount => '${netAmount.toStringAsFixed(0)} $currency';
  String get formattedCommissionAmount => '${commissionAmount.toStringAsFixed(0)} $currency';
  
  /// Pourcentage de commission formaté
  String get formattedCommissionRate => '${(commissionRate * 100).toStringAsFixed(1)}%';

  /// Délai jusqu'à l'exécution (si programmé)
  Duration? get timeUntilExecution {
    if (status != PayoutStatus.scheduled) return null;
    final now = DateTime.now();
    return scheduledDate.isAfter(now) ? scheduledDate.difference(now) : null;
  }

  /// Délai depuis le traitement (si traité)
  Duration? get timeSinceProcessed {
    if (processedDate == null) return null;
    return DateTime.now().difference(processedDate!);
  }
}

/// Informations de réservation associées à un payout
class ReservationInfo extends Equatable {
  final String id;
  final String? clientName;
  final String? residenceName;
  final double amount;
  final DateTime checkIn;
  final DateTime checkOut;

  const ReservationInfo({
    required this.id,
    this.clientName,
    this.residenceName,
    required this.amount,
    required this.checkIn,
    required this.checkOut,
  });

  factory ReservationInfo.fromJson(Map<String, dynamic> json) {
    return ReservationInfo(
      id: json['_id'] ?? json['id'] ?? '',
      clientName: json['clientName'] ?? json['user']?['firstName'],
      residenceName: json['residenceName'] ?? json['residence']?['title'],
      amount: (json['totalPrice'] ?? json['amount'] ?? 0.0).toDouble(),
      checkIn: DateTime.parse(json['checkIn'] ?? json['check_in']),
      checkOut: DateTime.parse(json['checkOut'] ?? json['check_out']),
    );
  }

  @override
  List<Object?> get props => [id, clientName, residenceName, amount, checkIn, checkOut];
}

/// Statistiques des payouts pour un partenaire
class PayoutStats extends Equatable {
  final double totalEarned;
  final double totalPending;
  final double totalCommission;
  final int totalPayouts;
  final int successfulPayouts;
  final int pendingPayouts;
  final int failedPayouts;
  final DateTime? lastPayoutDate;

  const PayoutStats({
    required this.totalEarned,
    required this.totalPending,
    required this.totalCommission,
    required this.totalPayouts,
    required this.successfulPayouts,
    required this.pendingPayouts,
    required this.failedPayouts,
    this.lastPayoutDate,
  });

  factory PayoutStats.fromJson(Map<String, dynamic> json) {
    return PayoutStats(
      totalEarned: (json['totalEarned'] ?? 0.0).toDouble(),
      totalPending: (json['totalPending'] ?? 0.0).toDouble(),
      totalCommission: (json['totalCommission'] ?? 0.0).toDouble(),
      totalPayouts: json['totalPayouts'] ?? 0,
      successfulPayouts: json['successfulPayouts'] ?? 0,
      pendingPayouts: json['pendingPayouts'] ?? 0,
      failedPayouts: json['failedPayouts'] ?? 0,
      lastPayoutDate: json['lastPayoutDate'] != null 
          ? DateTime.parse(json['lastPayoutDate']) 
          : null,
    );
  }

  @override
  List<Object?> get props => [
    totalEarned, totalPending, totalCommission, totalPayouts,
    successfulPayouts, pendingPayouts, failedPayouts, lastPayoutDate,
  ];

  /// Taux de réussite des payouts
  double get successRate {
    if (totalPayouts == 0) return 0.0;
    return successfulPayouts / totalPayouts;
  }

  /// Formatage des montants
  String get formattedTotalEarned => '${totalEarned.toStringAsFixed(0)} XOF';
  String get formattedTotalPending => '${totalPending.toStringAsFixed(0)} XOF';
  String get formattedTotalCommission => '${totalCommission.toStringAsFixed(0)} XOF';
}

/// Résultat paginé des payouts avec métadonnées
class PayoutHistoryResult extends Equatable {
  final List<PayoutModel> payouts;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final PayoutStats? stats;

  const PayoutHistoryResult({
    required this.payouts,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasNextPage,
    required this.hasPreviousPage,
    this.stats,
  });

  factory PayoutHistoryResult.fromJson(Map<String, dynamic> json) {
    return PayoutHistoryResult(
      payouts: (json['payouts'] as List)
          .map((p) => PayoutModel.fromJson(p))
          .toList(),
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalCount: json['totalCount'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPreviousPage: json['hasPreviousPage'] ?? false,
      stats: json['stats'] != null ? PayoutStats.fromJson(json['stats']) : null,
    );
  }

  @override
  List<Object?> get props => [
    payouts, currentPage, totalPages, totalCount,
    hasNextPage, hasPreviousPage, stats,
  ];
}
