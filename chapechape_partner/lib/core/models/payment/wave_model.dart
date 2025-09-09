import 'package:equatable/equatable.dart';

/// États possibles d'un transfert Wave selon le backend
enum WaveTransferStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

extension WaveTransferStatusExtension on WaveTransferStatus {
  String get displayName {
    switch (this) {
      case WaveTransferStatus.pending:
        return 'En attente';
      case WaveTransferStatus.processing:
        return 'En cours';
      case WaveTransferStatus.completed:
        return 'Effectué';
      case WaveTransferStatus.failed:
        return 'Échec';
      case WaveTransferStatus.cancelled:
        return 'Annulé';
    }
  }

  String get color {
    switch (this) {
      case WaveTransferStatus.pending:
        return '#FFA726'; // Orange
      case WaveTransferStatus.processing:
        return '#42A5F5'; // Bleu
      case WaveTransferStatus.completed:
        return '#66BB6A'; // Vert
      case WaveTransferStatus.failed:
        return '#EF5350'; // Rouge
      case WaveTransferStatus.cancelled:
        return '#9E9E9E'; // Gris
    }
  }

  static WaveTransferStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return WaveTransferStatus.pending;
      case 'processing':
      case 'in_progress':
        return WaveTransferStatus.processing;
      case 'completed':
      case 'success':
        return WaveTransferStatus.completed;
      case 'failed':
      case 'error':
        return WaveTransferStatus.failed;
      case 'cancelled':
      case 'canceled':
        return WaveTransferStatus.cancelled;
      default:
        return WaveTransferStatus.pending;
    }
  }
}

/// Modèle représentant un transfert Wave
class WaveTransferModel extends Equatable {
  final String id;
  final String waveId; // ID Wave (pt-xxx)
  final double amount;
  final String currency;
  final String mobile;
  final String name;
  final String clientReference;
  final String paymentReason;
  final WaveTransferStatus status;
  final DateTime timestamp;
  final double? fee;
  final String? errorCode;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const WaveTransferModel({
    required this.id,
    required this.waveId,
    required this.amount,
    required this.currency,
    required this.mobile,
    required this.name,
    required this.clientReference,
    required this.paymentReason,
    required this.status,
    required this.timestamp,
    this.fee,
    this.errorCode,
    this.errorMessage,
    this.metadata,
  });

  @override
  List<Object?> get props => [
    id, waveId, amount, currency, mobile, name, clientReference,
    paymentReason, status, timestamp, fee, errorCode, errorMessage, metadata,
  ];

  /// Crée une instance depuis JSON (API response backend)
  factory WaveTransferModel.fromJson(Map<String, dynamic> json) {
    return WaveTransferModel(
      id: json['id'] ?? '',
      waveId: json['wave_id'] ?? json['waveId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'XOF',
      mobile: json['mobile'] ?? '',
      name: json['name'] ?? '',
      clientReference: json['client_reference'] ?? json['clientReference'] ?? '',
      paymentReason: json['payment_reason'] ?? json['paymentReason'] ?? '',
      status: WaveTransferStatusExtension.fromString(json['status'] ?? 'pending'),
      timestamp: DateTime.parse(json['timestamp'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      fee: json['fee']?.toDouble(),
      errorCode: json['payout_error']?['error_code'] ?? json['error_code'],
      errorMessage: json['payout_error']?['error_message'] ?? json['error_message'],
      metadata: json['metadata'],
    );
  }

  /// Convertit en JSON pour les requêtes API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wave_id': waveId,
      'amount': amount,
      'currency': currency,
      'mobile': mobile,
      'name': name,
      'client_reference': clientReference,
      'payment_reason': paymentReason,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'fee': fee,
      'error_code': errorCode,
      'error_message': errorMessage,
      'metadata': metadata,
    };
  }

  /// Copie avec modifications
  WaveTransferModel copyWith({
    String? id,
    String? waveId,
    double? amount,
    String? currency,
    String? mobile,
    String? name,
    String? clientReference,
    String? paymentReason,
    WaveTransferStatus? status,
    DateTime? timestamp,
    double? fee,
    String? errorCode,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return WaveTransferModel(
      id: id ?? this.id,
      waveId: waveId ?? this.waveId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      mobile: mobile ?? this.mobile,
      name: name ?? this.name,
      clientReference: clientReference ?? this.clientReference,
      paymentReason: paymentReason ?? this.paymentReason,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      fee: fee ?? this.fee,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Formatage des montants avec devise
  String get formattedAmount => '${amount.toStringAsFixed(0)} $currency';
  String get formattedFee => fee != null ? '${fee!.toStringAsFixed(0)} $currency' : '0 $currency';
  
  /// Montant net (montant - frais)
  double get netAmount => amount - (fee ?? 0);
  String get formattedNetAmount => '${netAmount.toStringAsFixed(0)} $currency';

  /// Vérifications de statut
  bool get isCompleted => status == WaveTransferStatus.completed;
  bool get isFailed => status == WaveTransferStatus.failed;
  bool get isPending => status == WaveTransferStatus.pending || status == WaveTransferStatus.processing;
  bool get isCancelled => status == WaveTransferStatus.cancelled;
  bool get hasError => errorCode != null || errorMessage != null;
}

/// Modèle pour un batch de transferts Wave
class WaveBatchModel extends Equatable {
  final String batchId;
  final String status;
  final List<WaveTransferModel> payouts;
  final DateTime createdAt;
  final int totalTransfers;
  final int successfulTransfers;
  final int failedTransfers;

  const WaveBatchModel({
    required this.batchId,
    required this.status,
    required this.payouts,
    required this.createdAt,
    required this.totalTransfers,
    required this.successfulTransfers,
    required this.failedTransfers,
  });

  @override
  List<Object?> get props => [
    batchId, status, payouts, createdAt, totalTransfers,
    successfulTransfers, failedTransfers,
  ];

  factory WaveBatchModel.fromJson(Map<String, dynamic> json) {
    return WaveBatchModel(
      batchId: json['batch_id'] ?? '',
      status: json['status'] ?? 'pending',
      payouts: (json['payouts'] as List<dynamic>?)
          ?.map((p) => WaveTransferModel.fromJson(p))
          .toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      totalTransfers: json['total_transfers'] ?? json['payouts']?.length ?? 0,
      successfulTransfers: json['successful_transfers'] ?? 0,
      failedTransfers: json['failed_transfers'] ?? 0,
    );
  }

  /// Taux de réussite du batch
  double get successRate {
    if (totalTransfers == 0) return 0.0;
    return successfulTransfers / totalTransfers;
  }

  /// Formatage du taux de réussite
  String get formattedSuccessRate => '${(successRate * 100).toStringAsFixed(1)}%';

  /// Statut du batch
  bool get isComplete => status == 'complete';
  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
}

/// Statistiques des transferts Wave
class WaveTransferStats extends Equatable {
  final int totalTransfers;
  final double totalAmount;
  final int successfulTransfers;
  final int failedTransfers;
  final int pendingTransfers;
  final double totalFees;
  final double averageAmount;
  final double successRate;
  final DateTime? lastTransferDate;

  const WaveTransferStats({
    required this.totalTransfers,
    required this.totalAmount,
    required this.successfulTransfers,
    required this.failedTransfers,
    required this.pendingTransfers,
    required this.totalFees,
    required this.averageAmount,
    required this.successRate,
    this.lastTransferDate,
  });

  @override
  List<Object?> get props => [
    totalTransfers, totalAmount, successfulTransfers, failedTransfers,
    pendingTransfers, totalFees, averageAmount, successRate, lastTransferDate,
  ];

  factory WaveTransferStats.fromJson(Map<String, dynamic> json) {
    return WaveTransferStats(
      totalTransfers: json['totalTransfers'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      successfulTransfers: json['successfulTransfers'] ?? 0,
      failedTransfers: json['failedTransfers'] ?? 0,
      pendingTransfers: json['pendingTransfers'] ?? 0,
      totalFees: (json['totalFees'] ?? 0.0).toDouble(),
      averageAmount: (json['averageAmount'] ?? 0.0).toDouble(),
      successRate: (json['successRate'] ?? 0.0).toDouble(),
      lastTransferDate: json['lastTransferDate'] != null 
          ? DateTime.parse(json['lastTransferDate']) 
          : null,
    );
  }

  /// Formatage des montants
  String get formattedTotalAmount => '${totalAmount.toStringAsFixed(0)} XOF';
  String get formattedAverageAmount => '${averageAmount.toStringAsFixed(0)} XOF';
  String get formattedTotalFees => '${totalFees.toStringAsFixed(0)} XOF';
  String get formattedSuccessRate => '${(successRate * 100).toStringAsFixed(1)}%';
}

/// Résultat de recherche Wave
class WaveSearchResult extends Equatable {
  final List<WaveTransferModel> transfers;
  final int totalCount;
  final String? nextCursor;

  const WaveSearchResult({
    required this.transfers,
    required this.totalCount,
    this.nextCursor,
  });

  @override
  List<Object?> get props => [transfers, totalCount, nextCursor];

  factory WaveSearchResult.fromJson(Map<String, dynamic> json) {
    return WaveSearchResult(
      transfers: (json['transfers'] as List<dynamic>?)
          ?.map((t) => WaveTransferModel.fromJson(t))
          .toList() ?? [],
      totalCount: json['total_count'] ?? 0,
      nextCursor: json['next_cursor'],
    );
  }

  bool get hasMore => nextCursor != null;
}

/// Exception pour les erreurs Wave
class WaveTransferException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  WaveTransferException(this.message, [this.code, this.details]);

  @override
  String toString() => 'WaveTransferException: $message${code != null ? ' (Code: $code)' : ''}';
}
