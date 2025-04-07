import 'dart:async';
import 'connectivity_service.dart';
import 'cache_service.dart';
import 'api/api_service.dart';
import 'api/residence_service.dart';
import 'api/reservation_service.dart';
import 'api/message_service.dart';
import 'package:logging/logging.dart';
import '../utils/sync_conflict_resolver.dart';

/// Service qui gère la synchronisation des données entre local et serveur
class SyncService {
  // Singleton
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();
  
  // Services requis
  final ConnectivityService _connectivityService = ConnectivityService();
  final CacheService _cacheService = CacheService();
  late final ApiService _apiService;
  late final ResidenceService _residenceService;
  late final ReservationService _reservationService;
  late final MessageService? _messageService;
  
  // Logger
  final Logger _logger = Logger('SyncService');
  
  // État et configuration
  bool _isInitialized = false;
  bool _isSyncing = false;
  Timer? _syncTimer;
  final int _syncIntervalMinutes = 15; // Intervalle de synchronisation en minutes
  DateTime? _lastSyncTime;
  
  // Écouteur de changement de connectivité
  StreamSubscription<NetworkStatus>? _connectivitySubscription;
  
  // Contrôleur de stream pour notifier des événements de synchronisation
  final _syncController = StreamController<SyncEvent>.broadcast();
  Stream<SyncEvent> get syncEvents => _syncController.stream;
  
  /// Initialise le service de synchronisation
  void initialize({
    required ApiService apiService,
    required ResidenceService residenceService,
    required ReservationService reservationService,
    MessageService? messageService,
  }) {
    if (_isInitialized) return;
    
    // Initialiser les services dépendants
    _apiService = apiService;
    _residenceService = residenceService;
    _reservationService = reservationService;
    _messageService = messageService;
    
    _connectivityService.initialize();
    _cacheService.initialize();
    
    // Configurer l'écouteur de connectivité
    _connectivitySubscription = _connectivityService.status.listen(_onConnectivityChanged);
    
    // Démarrer le timer de synchronisation périodique
    _startSyncTimer();
    
    _isInitialized = true;
    _logger.info('Service de synchronisation initialisé');
    _syncController.add(SyncEvent(SyncEventType.initialized));
  }
  
  /// Gère les changements d'état de connectivité
  void _onConnectivityChanged(NetworkStatus status) async {
    if (status == NetworkStatus.online) {
      _logger.info('Connexion rétablie, synchronisation en cours...');
      _syncController.add(SyncEvent(SyncEventType.connectivityRestored));
      
      // Attendre un court délai pour s'assurer que la connexion est stable
      await Future.delayed(const Duration(seconds: 3));
      
      // Lancer la synchronisation lors du retour en ligne
      await syncPendingOperations();
    } else {
      _logger.info('Appareil hors-ligne, les opérations seront mises en attente');
      _syncController.add(SyncEvent(SyncEventType.connectivityLost));
    }
  }
  
  /// Démarre le timer de synchronisation périodique
  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      Duration(minutes: _syncIntervalMinutes), 
      (timer) async {
        if (_connectivityService.isOnline) {
          await syncAll();
        }
      }
    );
    _logger.info('Synchronisation périodique configurée (intervalle: $_syncIntervalMinutes minutes)');
  }
  
  /// Force une synchronisation immédiate si possible
  Future<bool> forceSynchronization() async {
    if (!_connectivityService.isOnline) {
      _logger.warning('Impossible de forcer la synchronisation: appareil hors-ligne');
      return false;
    }
    
    if (_isSyncing) {
      _logger.warning('Synchronisation déjà en cours, impossible de forcer une nouvelle synchronisation');
      return false;
    }
    
    try {
      await syncAll();
      return true;
    } catch (e) {
      _logger.severe('Erreur lors de la synchronisation forcée: $e');
      return false;
    }
  }
  
  /// Synchronise toutes les données (résidences, réservations et opérations en attente)
  Future<void> syncAll() async {
    if (_isSyncing) {
      _logger.info('Synchronisation déjà en cours, ignoré');
      return;
    }
    
    _isSyncing = true;
    _syncController.add(SyncEvent(SyncEventType.syncStarted));
    _logger.info('Début de la synchronisation complète...');
    
    try {
      // D'abord synchroniser les opérations en attente
      await syncPendingOperations();
      
      // Puis charger les nouvelles données du serveur
      await syncResidences();
      await syncReservations();
      if (_messageService != null) {
        await syncMessages();
      }
      
      _lastSyncTime = DateTime.now();
      _logger.info('Synchronisation complète terminée');
      _syncController.add(SyncEvent(SyncEventType.syncCompleted, success: true));
    } catch (e) {
      _logger.severe('Erreur lors de la synchronisation: $e');
      _syncController.add(SyncEvent(SyncEventType.syncCompleted, success: false, error: e.toString()));
    } finally {
      _isSyncing = false;
    }
  }
  
  /// Synchronise les résidences avec le serveur
  Future<void> syncResidences() async {
    if (!_connectivityService.isOnline) {
      _logger.warning('Appareil hors-ligne, impossible de synchroniser les résidences');
      return;
    }
    
    try {
      _logger.info('Synchronisation des résidences...');
      _syncController.add(SyncEvent(SyncEventType.syncProgress, entity: 'residences', message: 'Synchronisation des résidences'));
      
      // Récupérer les résidences du serveur
      final residences = await _residenceService.getMyResidences();
      
      // Récupérer les résidences du cache
      final cachedResidences = await _cacheService.getCachedResidences();
      
      // Vérifier les conflits et les résoudre
      final resolvedResidences = await SyncConflictResolver.resolveResidenceConflicts(
        cachedResidences, 
        residences
      );
      
      // Mettre à jour le cache local avec les données résolues
      await _cacheService.cacheResidences(resolvedResidences);
      
      _logger.info('Résidences synchronisées avec succès (${resolvedResidences.length} résidences)');
      _syncController.add(SyncEvent(SyncEventType.syncProgress, entity: 'residences', message: '${resolvedResidences.length} résidences synchronisées'));
    } catch (e) {
      _logger.severe('Erreur lors de la synchronisation des résidences: $e');
      _syncController.add(SyncEvent(SyncEventType.syncProgress, entity: 'residences', message: 'Erreur: $e', isError: true));
      // Ne pas propager l'exception pour permettre aux autres synchronisations de continuer
    }
  }
  
  /// Synchronise les réservations avec le serveur
  Future<void> syncReservations() async {
    if (!_connectivityService.isOnline) {
      _logger.warning('Appareil hors-ligne, impossible de synchroniser les réservations');
      return;
    }
    
    try {
      _logger.info('Synchronisation des réservations...');
      _syncController.add(SyncEvent(SyncEventType.syncProgress, entity: 'reservations', message: 'Synchronisation des réservations'));
      
      // Récupérer les réservations du serveur (utiliser la méthode directe si disponible)
      final reservations = await _reservationService.getPartnerReservationsDirect();
      
      // Récupérer les réservations du cache
      final cachedReservations = await _cacheService.getCachedReservations();
      
      // Vérifier les conflits et les résoudre
      final resolvedReservations = await SyncConflictResolver.resolveReservationConflicts(
        cachedReservations, 
        reservations
      );
      
      // Mettre à jour le cache local
      await _cacheService.cacheReservations(resolvedReservations);
      
      _logger.info('Réservations synchronisées avec succès (${resolvedReservations.length} réservations)');
      _syncController.add(SyncEvent(SyncEventType.syncProgress, entity: 'reservations', message: '${resolvedReservations.length} réservations synchronisées'));
    } catch (e) {
      _logger.severe('Erreur lors de la synchronisation des réservations: $e');
      _syncController.add(SyncEvent(SyncEventType.syncProgress, entity: 'reservations', message: 'Erreur: $e', isError: true));
    }
  }

  /// Synchronise les messages avec le serveur
  Future<void> syncMessages() async {
    if (!_connectivityService.isOnline || _messageService == null) {
      _logger.warning('Impossible de synchroniser les messages: hors-ligne ou service non disponible');
      return;
    }
    
    try {
      _logger.info('Synchronisation des messages...');
      _syncController.add(SyncEvent(SyncEventType.syncProgress, entity: 'messages', message: 'Synchronisation des messages'));
      
      // Récupérer les messages du serveur
      final messages = await _messageService!.getAllMessages();
      
      // Récupérer les messages du cache
      final cachedMessages = await _cacheService.getCachedMessages();
      
      // Vérifier les messages non envoyés
      final pendingMessages = await _cacheService.getPendingMessages();
      
      // Essayer d'envoyer les messages en attente
      for (final message in pendingMessages) {
        try {
          await _messageService!.sendMessage(
            message['conversationId'].toString(),
            message['content'].toString(),
          );
          
          // Supprimer le message de la liste des messages en attente
          await _cacheService.removePendingMessage(message['id'].toString());
        } catch (e) {
          _logger.warning('Échec de l\'envoi du message en attente: $e');
        }
      }
      
      // Mettre à jour le cache local
      await _cacheService.cacheMessages(messages);
      
      _logger.info('Messages synchronisés avec succès (${messages.length} messages)');
      _syncController.add(SyncEvent(SyncEventType.syncProgress, entity: 'messages', message: '${messages.length} messages synchronisés'));
    } catch (e) {
      _logger.severe('Erreur lors de la synchronisation des messages: $e');
      _syncController.add(SyncEvent(SyncEventType.syncProgress, entity: 'messages', message: 'Erreur: $e', isError: true));
    }
  }
  
  /// Synchronise les opérations en attente avec le serveur
  Future<void> syncPendingOperations() async {
    if (!_connectivityService.isOnline) {
      _logger.warning('Appareil hors-ligne, impossible de synchroniser les opérations en attente');
      return;
    }
    
    try {
      // Récupérer toutes les opérations en attente
      final pendingOps = await _cacheService.getPendingOperations();
      
      if (pendingOps.isEmpty) {
        _logger.info('Aucune opération en attente à synchroniser');
        return;
      }
      
      _logger.info('Synchronisation de ${pendingOps.length} opérations en attente...');
      _syncController.add(SyncEvent(SyncEventType.syncProgress, entity: 'pendingOperations', message: 'Synchronisation de ${pendingOps.length} opérations en attente'));
      
      // Trier les opérations par date pour les traiter dans l'ordre
      pendingOps.sort((a, b) => 
        DateTime.parse(a['timestamp'].toString())
          .compareTo(DateTime.parse(b['timestamp'].toString()))
      );
      
      int successCount = 0;
      int failedCount = 0;
      
      // Traiter chaque opération en attente
      for (final op in pendingOps) {
        final String id = op['id'];
        final String operation = op['operation'];
        final Map<String, dynamic> data = op['data'];
        
        try {
          await _processPendingOperation(operation, data);
          
          // Supprimer l'opération une fois traitée
          await _cacheService.removePendingOperation(id);
          _logger.info('Opération $operation synchronisée avec succès');
          successCount++;
        } catch (e) {
          _logger.warning('Erreur lors de la synchronisation de l\'opération $operation: $e');
          failedCount++;
          
          // Vérifier si l'opération est trop ancienne (plus de 3 jours)
          try {
            final timestamp = DateTime.parse(op['timestamp'].toString());
            final now = DateTime.now();
            if (now.difference(timestamp).inDays > 3) {
              // Supprimer les opérations trop anciennes pour éviter de réessayer indéfiniment
              await _cacheService.removePendingOperation(id);
              _logger.warning('Opération $operation supprimée car trop ancienne (> 3 jours)');
            }
          } catch (e) {
            _logger.severe('Erreur lors de la vérification de l\'âge de l\'opération: $e');
          }
        }
      }
      
      _logger.info('Synchronisation des opérations terminée. Réussies: $successCount, Échouées: $failedCount');
      _syncController.add(SyncEvent(
        SyncEventType.syncProgress, 
        entity: 'pendingOperations', 
        message: 'Opérations synchronisées: $successCount réussies, $failedCount échouées'
      ));
      
      // Vérifie l'état du token d'authentification après synchronisation
      final token = await _apiService.getToken();
      if (token == null || token.isEmpty) {
        _logger.warning('Token d\'authentification non valide après synchronisation');
      }
    } catch (e) {
      _logger.severe('Erreur lors de la synchronisation des opérations en attente: $e');
      _syncController.add(SyncEvent(
        SyncEventType.syncProgress, 
        entity: 'pendingOperations', 
        message: 'Erreur: $e',
        isError: true
      ));
    }
  }
  
  /// Traite une opération en attente en fonction de son type
  Future<void> _processPendingOperation(String operation, Map<String, dynamic> data) async {
    switch (operation) {
      case 'create_residence':
        await _residenceService.createResidence(data, []);
        break;
      case 'update_residence':
        final id = data['id'];
        await _residenceService.updateResidence(id, data, []);
        break;
      case 'delete_residence':
        final id = data['id'];
        await _residenceService.deleteResidence(id);
        break;
      case 'update_reservation':
        final id = data['id'];
        final status = data['status'];
        await _reservationService.updateReservationStatus(id, status);
        break;
      case 'send_message':
        if (_messageService != null) {
          final conversationId = data['conversationId'];
          final content = data['content'];
          await _messageService!.sendMessage(conversationId, content);
        } else {
          throw Exception('Service de messagerie non disponible');
        }
        break;
      default:
        _logger.warning('Type d\'opération inconnu: $operation');
        throw Exception('Type d\'opération inconnu: $operation');
    }
  }
  
  /// Enregistre une opération à effectuer plus tard si hors-ligne
  Future<void> addOfflineOperation(String operation, Map<String, dynamic> data) async {
    // Si en ligne, exécuter directement
    if (_connectivityService.isOnline) {
      try {
        await _processPendingOperation(operation, data);
        _logger.info('Opération $operation exécutée immédiatement');
        return;
      } catch (e) {
        _logger.warning('Erreur lors de l\'exécution de l\'opération $operation: $e');
        _logger.info('L\'opération sera mise en attente');
      }
    }
    
    // Enregistrer l'opération pour plus tard
    await _cacheService.addPendingOperation(operation, data);
    _logger.info('Opération $operation mise en attente pour synchronisation ultérieure');
    _syncController.add(SyncEvent(
      SyncEventType.operationQueued, 
      entity: operation, 
      message: 'Opération mise en attente pour synchronisation ultérieure'
    ));
  }
  
  /// Renvoie la date de dernière synchronisation réussie
  DateTime? getLastSyncTime() {
    return _lastSyncTime;
  }
  
  /// Indique si une synchronisation est actuellement en cours
  bool get isSyncing => _isSyncing;
  
  /// Ferme proprement le service
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _syncController.close();
  }
}

/// Événements de synchronisation pour informer l'interface utilisateur
class SyncEvent {
  final SyncEventType type;
  final String? entity;
  final String? message;
  final bool? success;
  final String? error;
  final bool isError;
  
  SyncEvent(
    this.type, {
    this.entity,
    this.message,
    this.success,
    this.error,
    this.isError = false,
  });
}

/// Types d'événements de synchronisation
enum SyncEventType {
  initialized,
  connectivityLost,
  connectivityRestored,
  syncStarted,
  syncProgress,
  syncCompleted,
  operationQueued,
} 