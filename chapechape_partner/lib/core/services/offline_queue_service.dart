import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import 'connectivity_service.dart';

/// Service de file d'attente pour les opérations offline
/// Gère la persistance et l'exécution des opérations en attente
class OfflineQueueService {
  // Singleton
  static final OfflineQueueService _instance = OfflineQueueService._internal();
  factory OfflineQueueService() => _instance;
  OfflineQueueService._internal();

  // Logger
  final Logger _logger = Logger('OfflineQueueService');

  // Services
  final ConnectivityService _connectivityService = ConnectivityService();
  
  // Configuration
  static const String _queueBox = 'offline_queue';
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(minutes: 5);
  static const Duration _maxOperationAge = Duration(days: 7);

  // État
  bool _isInitialized = false;
  bool _isProcessing = false;
  Timer? _processingTimer;
  final Uuid _uuid = Uuid();

  // Contrôleur de stream pour les événements
  final _queueController = StreamController<QueueEvent>.broadcast();
  Stream<QueueEvent> get queueEvents => _queueController.stream;

  // Types d'opérations supportées
  static const String createResidence = 'create_residence';
  static const String updateResidence = 'update_residence';
  static const String deleteResidence = 'delete_residence';
  static const String createReservation = 'create_reservation';
  static const String updateReservation = 'update_reservation';
  static const String cancelReservation = 'cancel_reservation';
  static const String createPayment = 'create_payment';
  static const String updatePayment = 'update_payment';
  static const String sendMessage = 'send_message';
  static const String updateProfile = 'update_profile';

  /// Initialise le service
  Future<void> initialize() async {
    if (_isInitialized) return;

    await Hive.openBox(_queueBox);
    _connectivityService.initialize();

    // Démarrer le traitement périodique
    _startPeriodicProcessing();

    _isInitialized = true;
    _logger.info('OfflineQueueService initialisé');
    _queueController.add(QueueEvent(QueueEventType.initialized));
  }

  /// Démarre le traitement périodique des opérations en attente
  void _startPeriodicProcessing() {
    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _processQueue(),
    );
  }

  /// Ajoute une opération à la file d'attente
  Future<String> enqueueOperation({
    required String type,
    required Map<String, dynamic> data,
    int priority = 0,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) {
      throw Exception('OfflineQueueService non initialisé');
    }

    final operationId = _uuid.v4();
    final operation = QueueOperation(
      id: operationId,
      type: type,
      data: data,
      priority: priority,
      metadata: metadata ?? {},
      createdAt: DateTime.now(),
      attempts: 0,
      status: QueueStatus.pending,
    );

    final box = Hive.box(_queueBox);
    await box.put(operationId, jsonEncode(operation.toJson()));

    _logger.info('Opération ajoutée à la file: $type (ID: $operationId)');
    _queueController.add(QueueEvent(
      QueueEventType.operationEnqueued,
      operationId: operationId,
      operationType: type,
    ));

    // Traiter immédiatement si en ligne
    if (_connectivityService.isOnline) {
      _processQueue();
    }

    return operationId;
  }

  /// Traite la file d'attente
  Future<void> _processQueue() async {
    if (_isProcessing || !_connectivityService.isOnline) return;

    _isProcessing = true;
    _logger.info('Traitement de la file d\'attente...');

    try {
      final box = Hive.box(_queueBox);
      final operations = <QueueOperation>[];

      // Récupérer toutes les opérations
      for (final key in box.keys) {
        try {
          final data = box.get(key);
          if (data is String) {
            final operation = QueueOperation.fromJson(jsonDecode(data));
            operations.add(operation);
          }
        } catch (e) {
          _logger.warning('Erreur lors de la lecture de l\'opération $key: $e');
        }
      }

      if (operations.isEmpty) {
        _logger.info('Aucune opération en attente');
        return;
      }

      // Trier par priorité et date de création
      operations.sort((a, b) {
        if (a.priority != b.priority) {
          return b.priority.compareTo(a.priority); // Priorité élevée en premier
        }
        return a.createdAt.compareTo(b.createdAt);
      });

      int processed = 0;
      int failed = 0;

      for (final operation in operations) {
        try {
          await _processOperation(operation);
          processed++;
        } catch (e) {
          _logger.warning('Échec du traitement de l\'opération ${operation.id}: $e');
          failed++;
          
          // Marquer comme échouée si trop de tentatives
          if (operation.attempts >= _maxRetries) {
            await _markOperationAsFailed(operation.id, e.toString());
          } else {
            await _incrementAttempts(operation.id);
          }
        }
      }

      _logger.info('File d\'attente traitée: $processed réussies, $failed échouées');
      _queueController.add(QueueEvent(
        QueueEventType.queueProcessed,
        message: '$processed opérations traitées, $failed échouées',
      ));

    } catch (e) {
      _logger.severe('Erreur lors du traitement de la file d\'attente: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Traite une opération spécifique
  Future<void> _processOperation(QueueOperation operation) async {
    _logger.info('Traitement de l\'opération: ${operation.type} (ID: ${operation.id})');

    // Vérifier l'âge de l'opération
    final age = DateTime.now().difference(operation.createdAt);
    if (age > _maxOperationAge) {
      await _removeOperation(operation.id);
      _logger.warning('Opération trop ancienne supprimée: ${operation.id}');
      return;
    }

    // Exécuter l'opération selon son type
    switch (operation.type) {
      case createResidence:
        await _executeCreateResidence(operation);
        break;
      case updateResidence:
        await _executeUpdateResidence(operation);
        break;
      case deleteResidence:
        await _executeDeleteResidence(operation);
        break;
      case createReservation:
        await _executeCreateReservation(operation);
        break;
      case updateReservation:
        await _executeUpdateReservation(operation);
        break;
      case cancelReservation:
        await _executeCancelReservation(operation);
        break;
      case createPayment:
        await _executeCreatePayment(operation);
        break;
      case updatePayment:
        await _executeUpdatePayment(operation);
        break;
      case sendMessage:
        await _executeSendMessage(operation);
        break;
      case updateProfile:
        await _executeUpdateProfile(operation);
        break;
      default:
        throw Exception('Type d\'opération non supporté: ${operation.type}');
    }

    // Marquer comme réussie et supprimer
    await _removeOperation(operation.id);
    _queueController.add(QueueEvent(
      QueueEventType.operationCompleted,
      operationId: operation.id,
      operationType: operation.type,
    ));
  }

  /// Exécute la création d'une résidence
  Future<void> _executeCreateResidence(QueueOperation operation) async {
    // TODO: Implémenter l'appel API pour créer une résidence
    _logger.info('Exécution de la création de résidence: ${operation.data}');
    await Future.delayed(const Duration(seconds: 1)); // Simulation
  }

  /// Exécute la mise à jour d'une résidence
  Future<void> _executeUpdateResidence(QueueOperation operation) async {
    // TODO: Implémenter l'appel API pour mettre à jour une résidence
    _logger.info('Exécution de la mise à jour de résidence: ${operation.data}');
    await Future.delayed(const Duration(seconds: 1)); // Simulation
  }

  /// Exécute la suppression d'une résidence
  Future<void> _executeDeleteResidence(QueueOperation operation) async {
    // TODO: Implémenter l'appel API pour supprimer une résidence
    _logger.info('Exécution de la suppression de résidence: ${operation.data}');
    await Future.delayed(const Duration(seconds: 1)); // Simulation
  }

  /// Exécute la création d'une réservation
  Future<void> _executeCreateReservation(QueueOperation operation) async {
    // TODO: Implémenter l'appel API pour créer une réservation
    _logger.info('Exécution de la création de réservation: ${operation.data}');
    await Future.delayed(const Duration(seconds: 1)); // Simulation
  }

  /// Exécute la mise à jour d'une réservation
  Future<void> _executeUpdateReservation(QueueOperation operation) async {
    // TODO: Implémenter l'appel API pour mettre à jour une réservation
    _logger.info('Exécution de la mise à jour de réservation: ${operation.data}');
    await Future.delayed(const Duration(seconds: 1)); // Simulation
  }

  /// Exécute l'annulation d'une réservation
  Future<void> _executeCancelReservation(QueueOperation operation) async {
    // TODO: Implémenter l'appel API pour annuler une réservation
    _logger.info('Exécution de l\'annulation de réservation: ${operation.data}');
    await Future.delayed(const Duration(seconds: 1)); // Simulation
  }

  /// Exécute la création d'un paiement
  Future<void> _executeCreatePayment(QueueOperation operation) async {
    // TODO: Implémenter l'appel API pour créer un paiement
    _logger.info('Exécution de la création de paiement: ${operation.data}');
    await Future.delayed(const Duration(seconds: 1)); // Simulation
  }

  /// Exécute la mise à jour d'un paiement
  Future<void> _executeUpdatePayment(QueueOperation operation) async {
    // TODO: Implémenter l'appel API pour mettre à jour un paiement
    _logger.info('Exécution de la mise à jour de paiement: ${operation.data}');
    await Future.delayed(const Duration(seconds: 1)); // Simulation
  }

  /// Exécute l'envoi d'un message
  Future<void> _executeSendMessage(QueueOperation operation) async {
    // TODO: Implémenter l'appel API pour envoyer un message
    _logger.info('Exécution de l\'envoi de message: ${operation.data}');
    await Future.delayed(const Duration(seconds: 1)); // Simulation
  }

  /// Exécute la mise à jour du profil
  Future<void> _executeUpdateProfile(QueueOperation operation) async {
    // TODO: Implémenter l'appel API pour mettre à jour le profil
    _logger.info('Exécution de la mise à jour de profil: ${operation.data}');
    await Future.delayed(const Duration(seconds: 1)); // Simulation
  }

  /// Marque une opération comme échouée
  Future<void> _markOperationAsFailed(String operationId, String error) async {
    final box = Hive.box(_queueBox);
    final data = box.get(operationId);
    if (data != null) {
      final operation = QueueOperation.fromJson(jsonDecode(data));
      operation.status = QueueStatus.failed;
      operation.error = error;
      await box.put(operationId, jsonEncode(operation.toJson()));
    }
  }

  /// Incrémente le nombre de tentatives
  Future<void> _incrementAttempts(String operationId) async {
    final box = Hive.box(_queueBox);
    final data = box.get(operationId);
    if (data != null) {
      final operation = QueueOperation.fromJson(jsonDecode(data));
      operation.attempts++;
      operation.lastAttempt = DateTime.now();
      await box.put(operationId, jsonEncode(operation.toJson()));
    }
  }

  /// Supprime une opération de la file
  Future<void> _removeOperation(String operationId) async {
    final box = Hive.box(_queueBox);
    await box.delete(operationId);
  }

  /// Récupère toutes les opérations en attente
  Future<List<QueueOperation>> getPendingOperations() async {
    if (!_isInitialized) return [];

    final box = Hive.box(_queueBox);
    final operations = <QueueOperation>[];

    for (final key in box.keys) {
      try {
        final data = box.get(key);
        if (data is String) {
          final operation = QueueOperation.fromJson(jsonDecode(data));
          if (operation.status == QueueStatus.pending) {
            operations.add(operation);
          }
        }
      } catch (e) {
        _logger.warning('Erreur lors de la lecture de l\'opération $key: $e');
      }
    }

    return operations;
  }

  /// Récupère les statistiques de la file d'attente
  Future<QueueStats> getQueueStats() async {
    if (!_isInitialized) return QueueStats();

    final box = Hive.box(_queueBox);
    int pending = 0;
    int failed = 0;
    int completed = 0;

    for (final key in box.keys) {
      try {
        final data = box.get(key);
        if (data is String) {
          final operation = QueueOperation.fromJson(jsonDecode(data));
          switch (operation.status) {
            case QueueStatus.pending:
              pending++;
              break;
            case QueueStatus.failed:
              failed++;
              break;
            case QueueStatus.completed:
              completed++;
              break;
          }
        }
      } catch (e) {
        _logger.warning('Erreur lors de la lecture de l\'opération $key: $e');
      }
    }

    return QueueStats(
      pending: pending,
      failed: failed,
      completed: completed,
      total: pending + failed + completed,
    );
  }

  /// Force le traitement de la file d'attente
  Future<void> forceProcessQueue() async {
    if (_connectivityService.isOnline) {
      await _processQueue();
    }
  }

  /// Vide la file d'attente
  Future<void> clearQueue() async {
    final box = Hive.box(_queueBox);
    await box.clear();
    _logger.info('File d\'attente vidée');
    _queueController.add(QueueEvent(QueueEventType.queueCleared));
  }

  /// Ferme le service
  void dispose() {
    _processingTimer?.cancel();
    _queueController.close();
  }
}

/// Modèle pour une opération en file d'attente
class QueueOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final int priority;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  int attempts;
  QueueStatus status;
  DateTime? lastAttempt;
  String? error;

  QueueOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.priority,
    required this.metadata,
    required this.createdAt,
    this.attempts = 0,
    this.status = QueueStatus.pending,
    this.lastAttempt,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'data': data,
    'priority': priority,
    'metadata': metadata,
    'createdAt': createdAt.toIso8601String(),
    'attempts': attempts,
    'status': status.name,
    'lastAttempt': lastAttempt?.toIso8601String(),
    'error': error,
  };

  factory QueueOperation.fromJson(Map<String, dynamic> json) {
    return QueueOperation(
      id: json['id'],
      type: json['type'],
      data: Map<String, dynamic>.from(json['data']),
      priority: json['priority'],
      metadata: Map<String, dynamic>.from(json['metadata']),
      createdAt: DateTime.parse(json['createdAt']),
      attempts: json['attempts'] ?? 0,
      status: QueueStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => QueueStatus.pending,
      ),
      lastAttempt: json['lastAttempt'] != null 
          ? DateTime.parse(json['lastAttempt']) 
          : null,
      error: json['error'],
    );
  }
}

/// Statuts des opérations
enum QueueStatus { pending, completed, failed }

/// Statistiques de la file d'attente
class QueueStats {
  final int pending;
  final int failed;
  final int completed;
  final int total;

  QueueStats({
    this.pending = 0,
    this.failed = 0,
    this.completed = 0,
    this.total = 0,
  });
}

/// Événements de la file d'attente
class QueueEvent {
  final QueueEventType type;
  final String? operationId;
  final String? operationType;
  final String? message;

  QueueEvent(
    this.type, {
    this.operationId,
    this.operationType,
    this.message,
  });
}

/// Types d'événements
enum QueueEventType {
  initialized,
  operationEnqueued,
  operationCompleted,
  operationFailed,
  queueProcessed,
  queueCleared,
}
