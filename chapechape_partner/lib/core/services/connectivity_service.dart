import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum NetworkStatus { online, offline }

/// Service qui gère la connectivité et notifie des changements d'état réseau
class ConnectivityService {
  // Singleton
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _controller = StreamController<NetworkStatus>.broadcast();
  final Connectivity _connectivity = Connectivity();

  Stream<NetworkStatus> get status => _controller.stream;

  NetworkStatus _currentStatus = NetworkStatus.online;
  NetworkStatus get currentStatus => _currentStatus;

  Future<void> initialize() async {
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    await checkConnectivity();

    Timer.periodic(const Duration(seconds: 30), (_) {
      checkConnectivity();
    });
  }

  Future<NetworkStatus> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
    return _currentStatus;
  }

  /// Met à jour l'état selon le résultat (API connectivity_plus : résultat unique ou liste selon la version).
  void _updateConnectionStatus(dynamic result) {
    final previousStatus = _currentStatus;
    final isOffline = _isOffline(result);

    _currentStatus = isOffline ? NetworkStatus.offline : NetworkStatus.online;
    if (isOffline) {
      debugPrint('📱 État de la connexion: Hors ligne');
    } else {
      debugPrint('📱 État de la connexion: En ligne');
    }

    if (previousStatus != _currentStatus) {
      _controller.add(_currentStatus);
    }
  }

  bool _isOffline(dynamic result) {
    if (result is List) {
      final list = result as List<ConnectivityResult>;
      return list.isEmpty ||
          (list.length == 1 && list.first == ConnectivityResult.none);
    }
    return result == ConnectivityResult.none;
  }

  void dispose() {
    _controller.close();
  }

  bool get isOnline => _currentStatus == NetworkStatus.online;
}