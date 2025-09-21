import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import 'connectivity_service.dart';
import 'offline_queue_service.dart';
import '../models/payment/payment_model.dart';
import '../models/payment/african_payment_method.dart';

/// Service de gestion des paiements offline
/// Gère la création différée et la synchronisation des paiements
class OfflinePaymentService {
  // Singleton
  static final OfflinePaymentService _instance = OfflinePaymentService._internal();
  factory OfflinePaymentService() => _instance;
  OfflinePaymentService._internal();

  // Logger
  final Logger _logger = Logger('OfflinePaymentService');

  // Services
  final ConnectivityService _connectivityService = ConnectivityService();
  final OfflineQueueService _queueService = OfflineQueueService();
  
  // Configuration
  static const String _paymentsBox = 'offline_payments';
  static const String _transactionsBox = 'offline_transactions';
  static const Duration _paymentTimeout = Duration(minutes: 30);

  // État
  bool _isInitialized = false;
  final Uuid _uuid = Uuid();

  // Contrôleur de stream pour les événements
  final _paymentController = StreamController<PaymentEvent>.broadcast();
  Stream<PaymentEvent> get paymentEvents => _paymentController.stream;

  /// Initialise le service
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.openBox(_paymentsBox);
    await Hive.openBox(_transactionsBox);
    _connectivityService.initialize();
    await _queueService.initialize();

    _isInitialized = true;
    _logger.info('OfflinePaymentService initialisé');
    _paymentController.add(PaymentEvent(PaymentEventType.initialized));
  }

  /// Crée un paiement offline
  Future<String> createOfflinePayment({
    required String reservationId,
    required double amount,
    required AfricanPaymentMethod method,
    required Map<String, dynamic> paymentDetails,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) {
      throw Exception('OfflinePaymentService non initialisé');
    }

    final paymentId = _uuid.v4();
    final transactionId = _uuid.v4();

    // Créer le paiement offline
    final offlinePayment = OfflinePayment(
      id: paymentId,
      transactionId: transactionId,
      reservationId: reservationId,
      amount: amount,
      method: method,
      details: paymentDetails,
      description: description,
      metadata: metadata ?? {},
      status: PaymentStatus.pending,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(_paymentTimeout),
    );

    // Sauvegarder le paiement
    await _saveOfflinePayment(offlinePayment);

    // Si en ligne, essayer de traiter immédiatement
    if (_connectivityService.isOnline) {
      try {
        await _processPaymentImmediately(offlinePayment);
        return paymentId;
      } catch (e) {
        _logger.warning('Échec du traitement immédiat, paiement mis en attente: $e');
      }
    }

    // Ajouter à la file d'attente pour traitement différé
    await _queueService.enqueueOperation(
      type: OfflineQueueService.createPayment,
      data: {
        'paymentId': paymentId,
        'transactionId': transactionId,
        'reservationId': reservationId,
        'amount': amount,
        'method': method.name,
        'details': paymentDetails,
        'description': description,
        'metadata': metadata,
      },
      priority: 1, // Priorité élevée pour les paiements
    );

    _logger.info('Paiement offline créé: $paymentId (${method.name})');
    _paymentController.add(PaymentEvent(
      PaymentEventType.paymentCreated,
      paymentId: paymentId,
      amount: amount,
      method: method.name,
    ));

    return paymentId;
  }

  /// Traite un paiement immédiatement (si en ligne)
  Future<void> _processPaymentImmediately(OfflinePayment payment) async {
    _logger.info('Traitement immédiat du paiement: ${payment.id}');

    try {
      // TODO: Implémenter l'appel API réel pour traiter le paiement
      // Pour l'instant, simulation
      await Future.delayed(const Duration(seconds: 2));

      // Simuler le succès du paiement
      payment.status = PaymentStatus.succeeded;
      payment.processedAt = DateTime.now();
      payment.processedAmount = payment.amount;

      await _updateOfflinePayment(payment);

      _logger.info('Paiement traité avec succès: ${payment.id}');
      _paymentController.add(PaymentEvent(
        PaymentEventType.paymentProcessed,
        paymentId: payment.id,
        amount: payment.amount,
        success: true,
      ));

    } catch (e) {
      _logger.warning('Échec du traitement du paiement: $e');
      payment.status = PaymentStatus.failed;
      payment.error = e.toString();
      await _updateOfflinePayment(payment);

      _paymentController.add(PaymentEvent(
        PaymentEventType.paymentFailed,
        paymentId: payment.id,
        amount: payment.amount,
        error: e.toString(),
      ));

      rethrow;
    }
  }

  /// Sauvegarde un paiement offline
  Future<void> _saveOfflinePayment(OfflinePayment payment) async {
    final box = Hive.box(_paymentsBox);
    await box.put(payment.id, jsonEncode(payment.toJson()));
  }

  /// Met à jour un paiement offline
  Future<void> _updateOfflinePayment(OfflinePayment payment) async {
    final box = Hive.box(_paymentsBox);
    await box.put(payment.id, jsonEncode(payment.toJson()));
  }

  /// Récupère un paiement offline par ID
  Future<OfflinePayment?> getOfflinePayment(String paymentId) async {
    if (!_isInitialized) return null;

    final box = Hive.box(_paymentsBox);
    final data = box.get(paymentId);
    if (data is String) {
      return OfflinePayment.fromJson(jsonDecode(data));
    }
    return null;
  }

  /// Récupère tous les paiements offline
  Future<List<OfflinePayment>> getAllOfflinePayments() async {
    if (!_isInitialized) return [];

    final box = Hive.box(_paymentsBox);
    final payments = <OfflinePayment>[];

    for (final key in box.keys) {
      try {
        final data = box.get(key);
        if (data is String) {
          final payment = OfflinePayment.fromJson(jsonDecode(data));
          payments.add(payment);
        }
      } catch (e) {
        _logger.warning('Erreur lors de la lecture du paiement $key: $e');
      }
    }

    // Trier par date de création (plus récents en premier)
    payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return payments;
  }

  /// Récupère les paiements en attente
  Future<List<OfflinePayment>> getPendingPayments() async {
    final allPayments = await getAllOfflinePayments();
    return allPayments.where((p) => p.status == PaymentStatus.pending).toList();
  }

  /// Récupère les paiements échoués
  Future<List<OfflinePayment>> getFailedPayments() async {
    final allPayments = await getAllOfflinePayments();
    return allPayments.where((p) => p.status == PaymentStatus.failed).toList();
  }

  /// Retente un paiement échoué
  Future<bool> retryPayment(String paymentId) async {
    final payment = await getOfflinePayment(paymentId);
    if (payment == null) return false;

    if (_connectivityService.isOnline) {
      try {
        await _processPaymentImmediately(payment);
        return true;
      } catch (e) {
        _logger.warning('Échec du retry du paiement: $e');
        return false;
      }
    } else {
      // Remettre en file d'attente
      await _queueService.enqueueOperation(
        type: OfflineQueueService.createPayment,
        data: {
          'paymentId': payment.id,
          'transactionId': payment.transactionId,
          'reservationId': payment.reservationId,
          'amount': payment.amount,
          'method': payment.method.name,
          'details': payment.details,
          'description': payment.description,
          'metadata': payment.metadata,
        },
        priority: 1,
      );
      return true;
    }
  }

  /// Annule un paiement en attente
  Future<bool> cancelPayment(String paymentId) async {
    final payment = await getOfflinePayment(paymentId);
    if (payment == null || payment.status != PaymentStatus.pending) return false;

    payment.status = PaymentStatus.cancelled;
    payment.cancelledAt = DateTime.now();
    await _updateOfflinePayment(payment);

    _logger.info('Paiement annulé: $paymentId');
    _paymentController.add(PaymentEvent(
      PaymentEventType.paymentCancelled,
      paymentId: paymentId,
    ));

    return true;
  }

  /// Récupère les statistiques des paiements
  Future<PaymentStats> getPaymentStats() async {
    final allPayments = await getAllOfflinePayments();
    
    int pending = 0;
    int succeeded = 0;
    int failed = 0;
    int cancelled = 0;
    double totalAmount = 0;
    double succeededAmount = 0;

    for (final payment in allPayments) {
      switch (payment.status) {
        case PaymentStatus.pending:
          pending++;
          break;
        case PaymentStatus.succeeded:
          succeeded++;
          succeededAmount += payment.amount;
          break;
        case PaymentStatus.failed:
          failed++;
          break;
        case PaymentStatus.cancelled:
          cancelled++;
          break;
        default:
          break;
      }
      totalAmount += payment.amount;
    }

    return PaymentStats(
      total: allPayments.length,
      pending: pending,
      succeeded: succeeded,
      failed: failed,
      cancelled: cancelled,
      totalAmount: totalAmount,
      succeededAmount: succeededAmount,
    );
  }

  /// Nettoie les anciens paiements
  Future<void> cleanupOldPayments() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    final allPayments = await getAllOfflinePayments();
    final box = Hive.box(_paymentsBox);

    int cleaned = 0;
    for (final payment in allPayments) {
      if (payment.createdAt.isBefore(cutoffDate) && 
          (payment.status == PaymentStatus.succeeded || 
           payment.status == PaymentStatus.cancelled)) {
        await box.delete(payment.id);
        cleaned++;
      }
    }

    if (cleaned > 0) {
      _logger.info('$cleaned anciens paiements nettoyés');
    }
  }

  /// Ferme le service
  void dispose() {
    _paymentController.close();
  }
}

/// Modèle pour un paiement offline
class OfflinePayment {
  final String id;
  final String transactionId;
  final String reservationId;
  final double amount;
  final AfricanPaymentMethod method;
  final Map<String, dynamic> details;
  final String? description;
  final Map<String, dynamic> metadata;
  PaymentStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  DateTime? processedAt;
  double? processedAmount;
  String? error;
  DateTime? cancelledAt;

  OfflinePayment({
    required this.id,
    required this.transactionId,
    required this.reservationId,
    required this.amount,
    required this.method,
    required this.details,
    this.description,
    required this.metadata,
    this.status = PaymentStatus.pending,
    required this.createdAt,
    required this.expiresAt,
    this.processedAt,
    this.processedAmount,
    this.error,
    this.cancelledAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'transactionId': transactionId,
    'reservationId': reservationId,
    'amount': amount,
    'method': method.name,
    'details': details,
    'description': description,
    'metadata': metadata,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'processedAt': processedAt?.toIso8601String(),
    'processedAmount': processedAmount,
    'error': error,
    'cancelledAt': cancelledAt?.toIso8601String(),
  };

  factory OfflinePayment.fromJson(Map<String, dynamic> json) {
    return OfflinePayment(
      id: json['id'],
      transactionId: json['transactionId'],
      reservationId: json['reservationId'],
      amount: (json['amount'] as num).toDouble(),
      method: AfricanPaymentMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => AfricanPaymentMethod.cash,
      ),
      details: Map<String, dynamic>.from(json['details']),
      description: json['description'],
      metadata: Map<String, dynamic>.from(json['metadata']),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      processedAt: json['processedAt'] != null 
          ? DateTime.parse(json['processedAt']) 
          : null,
      processedAmount: json['processedAmount']?.toDouble(),
      error: json['error'],
      cancelledAt: json['cancelledAt'] != null 
          ? DateTime.parse(json['cancelledAt']) 
          : null,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get canRetry => status == PaymentStatus.failed && !isExpired;
  bool get isPending => status == PaymentStatus.pending && !isExpired;
}

/// Statistiques des paiements
class PaymentStats {
  final int total;
  final int pending;
  final int succeeded;
  final int failed;
  final int cancelled;
  final double totalAmount;
  final double succeededAmount;

  PaymentStats({
    required this.total,
    required this.pending,
    required this.succeeded,
    required this.failed,
    required this.cancelled,
    required this.totalAmount,
    required this.succeededAmount,
  });
}

/// Événements de paiement
class PaymentEvent {
  final PaymentEventType type;
  final String? paymentId;
  final double? amount;
  final String? method;
  final bool? success;
  final String? error;

  PaymentEvent(
    this.type, {
    this.paymentId,
    this.amount,
    this.method,
    this.success,
    this.error,
  });
}

/// Types d'événements de paiement
enum PaymentEventType {
  initialized,
  paymentCreated,
  paymentProcessed,
  paymentFailed,
  paymentCancelled,
}
