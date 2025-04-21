import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service simplifié de vérification de connectivité qui n'utilise pas connectivity_plus
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  /// Stream indiquant si l'appareil est connecté à Internet
  Stream<bool> get connectivityStream => _controller.stream;
  
  /// État actuel de la connectivité
  bool _isConnected = true;
  bool get isConnected => _isConnected;
  
  Timer? _checkTimer;
  
  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._internal() {
    // Démarrer la vérification périodique
    _startPeriodicCheck();
  }
  
  /// Démarre une vérification périodique de la connectivité
  void _startPeriodicCheck() {
    // Vérifier toutes les 30 secondes
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      checkConnectivity();
    });
    
    // Faire une vérification immédiate
    checkConnectivity();
  }

  /// Vérifier l'état de connectivité actuel
  Future<bool> checkConnectivity() async {
    try {
      // Tenter une requête simple vers Google
      final response = await http.get(
        Uri.parse('https://www.google.com'),
      ).timeout(const Duration(seconds: 5));
      
      final isNowConnected = response.statusCode >= 200 && response.statusCode < 300;
      
      // Si l'état a changé, notifier les écouteurs
      if (isNowConnected != _isConnected) {
        _isConnected = isNowConnected;
        _controller.add(_isConnected);
        debugPrint('État de connectivité changé: ${_isConnected ? 'Connecté' : 'Déconnecté'}');
      }
      
      return _isConnected;
    } catch (e) {
      // En cas d'erreur, on suppose qu'on est hors ligne
      if (_isConnected) {
        _isConnected = false;
        _controller.add(false);
        debugPrint('Connexion perdue: $e');
      }
      return false;
    }
  }

  /// Libérer les ressources
  void dispose() {
    _checkTimer?.cancel();
    _controller.close();
  }
} 