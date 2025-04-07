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

  // Contrôleur pour notifier des changements d'état
  final _controller = StreamController<NetworkStatus>.broadcast();
  final Connectivity _connectivity = Connectivity();
  
  // Stream accessible en externe pour écouter les changements d'état
  Stream<NetworkStatus> get status => _controller.stream;
  
  // État actuel de la connectivité
  NetworkStatus _currentStatus = NetworkStatus.online;
  NetworkStatus get currentStatus => _currentStatus;
  
  // Méthode d'initialisation
  Future<void> initialize() async {
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    await checkConnectivity();
  }
  
  // Vérification immédiate de la connectivité 
  Future<NetworkStatus> checkConnectivity() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    _updateConnectionStatus(connectivityResult);
    return _currentStatus;
  }
  
  // Méthode pour mettre à jour l'état et notifier les abonnés
  void _updateConnectionStatus(ConnectivityResult result) {
    NetworkStatus previousStatus = _currentStatus;
    
    // Déterminer le nouvel état basé sur le résultat de connectivité
    if (result == ConnectivityResult.none) {
      _currentStatus = NetworkStatus.offline;
      print('📱 État de la connexion: Hors ligne');
    } else {
      _currentStatus = NetworkStatus.online;
      print('📱 État de la connexion: En ligne (${result.name})');
    }
    
    // Notifier seulement si l'état a changé
    if (previousStatus != _currentStatus) {
      _controller.add(_currentStatus);
    }
  }
  
  // Vérifier si une connexion réseau est disponible
  bool get isOnline => _currentStatus == NetworkStatus.online;
  
  // Fermer le contrôleur proprement
  void dispose() {
    _controller.close();
  }
} 