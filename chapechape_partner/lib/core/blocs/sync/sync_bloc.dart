import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/sync_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/cache_service.dart';

// Events
abstract class SyncEvent extends Equatable {
  const SyncEvent();
  
  @override
  List<Object?> get props => [];
}

class SyncRequested extends SyncEvent {}

class SyncStarted extends SyncEvent {}

class SyncFinished extends SyncEvent {
  final bool success;
  final String? error;
  
  const SyncFinished({
    required this.success,
    this.error,
  });
  
  @override
  List<Object?> get props => [success, error];
}

class SyncProgressUpdated extends SyncEvent {
  final String? entity;
  final String? message;
  final bool isError;
  
  const SyncProgressUpdated({
    this.entity,
    this.message,
    this.isError = false,
  });
  
  @override
  List<Object?> get props => [entity, message, isError];
}

class ConnectivityChanged extends SyncEvent {
  final NetworkStatus status;
  
  const ConnectivityChanged(this.status);
  
  @override
  List<Object?> get props => [status];
}

class CheckPendingOperations extends SyncEvent {}

// States
abstract class SyncState extends Equatable {
  const SyncState();
  
  @override
  List<Object?> get props => [];
}

class SyncInitial extends SyncState {}

class SyncIdle extends SyncState {
  final DateTime? lastSyncTime;
  final int pendingOperations;
  
  const SyncIdle({
    this.lastSyncTime,
    this.pendingOperations = 0,
  });
  
  @override
  List<Object?> get props => [lastSyncTime, pendingOperations];
}

class SyncInProgress extends SyncState {
  final String? currentEntity;
  final String? currentMessage;
  
  const SyncInProgress({
    this.currentEntity,
    this.currentMessage,
  });
  
  @override
  List<Object?> get props => [currentEntity, currentMessage];
}

class SyncSuccess extends SyncState {
  final DateTime syncTime;
  
  const SyncSuccess({
    required this.syncTime,
  });
  
  @override
  List<Object?> get props => [syncTime];
}

class SyncError extends SyncState {
  final String message;
  
  const SyncError({
    required this.message,
  });
  
  @override
  List<Object?> get props => [message];
}

class SyncOffline extends SyncState {
  final int pendingOperations;
  
  const SyncOffline({
    this.pendingOperations = 0,
  });
  
  @override
  List<Object?> get props => [pendingOperations];
}

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncService _syncService;
  final ConnectivityService _connectivityService;
  final CacheService _cacheService;
  
  StreamSubscription<NetworkStatus>? _connectivitySubscription;
  StreamSubscription<SyncEvent>? _syncEventSubscription;
  
  SyncBloc({
    required SyncService syncService,
    required ConnectivityService connectivityService,
    required CacheService cacheService,
  }) : 
    _syncService = syncService,
    _connectivityService = connectivityService,
    _cacheService = cacheService,
    super(SyncInitial()) {
    
    on<SyncRequested>(_onSyncRequested);
    on<SyncStarted>(_onSyncStarted);
    on<SyncFinished>(_onSyncFinished);
    on<SyncProgressUpdated>(_onSyncProgressUpdated);
    on<ConnectivityChanged>(_onConnectivityChanged);
    on<CheckPendingOperations>(_onCheckPendingOperations);
    
    // Écouter les changements de connectivité
    _connectivitySubscription = _connectivityService.status.listen((status) {
      add(ConnectivityChanged(status));
    });
    
    // Écouter les événements de synchronisation
    _syncEventSubscription = _listenToSyncEvents();
    
    // Vérifier l'état initial
    _checkInitialState();
  }
  
  Future<void> _checkInitialState() async {
    // Vérifier la connectivité initiale
    final initialStatus = await _connectivityService.checkConnectivity();
    
    if (initialStatus == NetworkStatus.offline) {
      final pendingOps = await _cacheService.getPendingOperations();
      emit(SyncOffline(pendingOperations: pendingOps.length));
    } else {
      // Vérifier s'il y a des opérations en attente
      add(CheckPendingOperations());
    }
  }
  
  StreamSubscription<SyncEvent> _listenToSyncEvents() {
    return _syncService.syncEvents.map<SyncEvent?>((syncEvent) {
      // Convertir les événements SyncService en événements SyncBloc
      switch (syncEvent.type) {
        case SyncEventType.syncStarted:
          return SyncStarted();
          
        case SyncEventType.syncCompleted:
          return SyncFinished(
            success: syncEvent.success ?? false,
            error: syncEvent.error,
          );
          
        case SyncEventType.syncProgress:
          return SyncProgressUpdated(
            entity: syncEvent.entity,
            message: syncEvent.message,
            isError: syncEvent.isError ?? false,
          );
          
        case SyncEventType.connectivityLost:
          return ConnectivityChanged(NetworkStatus.offline);
          
        case SyncEventType.connectivityRestored:
          return ConnectivityChanged(NetworkStatus.online);
          
        case SyncEventType.operationQueued:
          return CheckPendingOperations();
          
        default:
          return null;
      }
    })
    .where((event) => event != null)
    .cast<SyncEvent>()
    .listen((event) {
      add(event);
    });
  }
  
  Future<void> _onSyncRequested(
    SyncRequested event, 
    Emitter<SyncState> emit,
  ) async {
    if (state is SyncInProgress) return; // Éviter les synchronisations multiples
    
    if (_connectivityService.isOnline) {
      add(SyncStarted());
      final result = await _syncService.forceSynchronization();
      
      if (!result) {
        emit(SyncError(message: 'Échec de la synchronisation'));
      }
    } else {
      final pendingOps = await _cacheService.getPendingOperations();
      emit(SyncOffline(pendingOperations: pendingOps.length));
    }
  }
  
  void _onSyncStarted(
    SyncStarted event, 
    Emitter<SyncState> emit,
  ) {
    emit(const SyncInProgress());
  }
  
  void _onSyncFinished(
    SyncFinished event, 
    Emitter<SyncState> emit,
  ) async {
    if (event.success) {
      final syncTime = _syncService.getLastSyncTime() ?? DateTime.now();
      emit(SyncSuccess(syncTime: syncTime));
      
      // Après un court délai, passer à l'état idle avec la date de dernière synchro
      await Future.delayed(const Duration(seconds: 2));
      final pendingOps = await _cacheService.getPendingOperations();
      emit(SyncIdle(lastSyncTime: syncTime, pendingOperations: pendingOps.length));
    } else {
      emit(SyncError(message: event.error ?? 'Erreur inconnue'));
      
      // Après un court délai, passer à l'état idle
      await Future.delayed(const Duration(seconds: 3));
      final pendingOps = await _cacheService.getPendingOperations();
      final syncTime = _syncService.getLastSyncTime();
      emit(SyncIdle(lastSyncTime: syncTime, pendingOperations: pendingOps.length));
    }
  }
  
  void _onSyncProgressUpdated(
    SyncProgressUpdated event, 
    Emitter<SyncState> emit,
  ) {
    emit(SyncInProgress(
      currentEntity: event.entity,
      currentMessage: event.message,
    ));
  }
  
  Future<void> _onConnectivityChanged(
    ConnectivityChanged event, 
    Emitter<SyncState> emit,
  ) async {
    if (event.status == NetworkStatus.offline) {
      final pendingOps = await _cacheService.getPendingOperations();
      emit(SyncOffline(pendingOperations: pendingOps.length));
    } else if (state is SyncOffline) {
      // On vient de retrouver la connexion
      final pendingOps = await _cacheService.getPendingOperations();
      emit(SyncIdle(
        lastSyncTime: _syncService.getLastSyncTime(),
        pendingOperations: pendingOps.length,
      ));
      
      // Lancer une synchronisation automatique si nécessaire
      if (pendingOps.isNotEmpty) {
        add(SyncRequested());
      }
    }
  }
  
  Future<void> _onCheckPendingOperations(
    CheckPendingOperations event, 
    Emitter<SyncState> emit,
  ) async {
    if (state is SyncInProgress) return;
    
    final pendingOps = await _cacheService.getPendingOperations();
    
    if (_connectivityService.isOnline) {
      emit(SyncIdle(
        lastSyncTime: _syncService.getLastSyncTime(),
        pendingOperations: pendingOps.length,
      ));
    } else {
      emit(SyncOffline(pendingOperations: pendingOps.length));
    }
  }
  
  @override
  Future<void> close() async {
    await _connectivitySubscription?.cancel();
    await _syncEventSubscription?.cancel();
    return super.close();
  }
} 