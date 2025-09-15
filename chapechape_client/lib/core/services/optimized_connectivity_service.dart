import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service de connectivité optimisé pour éviter le rate limiting
class OptimizedConnectivityService {
  static final OptimizedConnectivityService _instance = OptimizedConnectivityService._internal();
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  /// Stream indiquant si l'appareil est connecté à Internet
  Stream<bool> get connectivityStream => _controller.stream;
  
  /// État actuel de la connectivité
  bool _isConnected = true;
  bool get isConnected => _isConnected;
  
  Timer? _checkTimer;
  DateTime? _lastCheck;
  static const Duration _minCheckInterval = Duration(minutes: 5);
  
  factory OptimizedConnectivityService() {
    return _instance;
  }

  OptimizedConnectivityService._internal() {
    _startOptimizedCheck();
  }
  
  /// Démarre une vérification optimisée de la connectivité
  void _startOptimizedCheck() {
    // Vérifier toutes les 10 minutes (beaucoup moins fréquent)
    _checkTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _checkConnectivityIfNeeded();
    });
    
    // Faire une vérification immédiate
    _checkConnectivityIfNeeded();
  }

  /// Vérifie la connectivité seulement si nécessaire
  Future<void> _checkConnectivityIfNeeded() async {
    // Éviter les vérifications trop fréquentes
    if (_lastCheck != null && 
        DateTime.now().difference(_lastCheck!) < _minCheckInterval) {
      return;
    }
    
    await checkConnectivity();
  }

  /// Vérifier l'état de connectivité actuel
  Future<bool> checkConnectivity() async {
    try {
      _lastCheck = DateTime.now();
      
      // Utiliser Google pour éviter le rate limiting du serveur
      final response = await http.get(
        Uri.parse('https://www.google.com'),
      ).timeout(const Duration(seconds: 10));
      
      final isNowConnected = response.statusCode >= 200 && response.statusCode < 300;
      
      // Si l'état a changé, notifier les écouteurs
      if (isNowConnected != _isConnected) {
        _isConnected = isNowConnected;
        _controller.add(_isConnected);
        debugPrint('🔄 État de connectivité changé: ${_isConnected ? 'Connecté' : 'Déconnecté'}');
      }
      
      return _isConnected;
    } catch (e) {
      // En cas d'erreur, on suppose qu'on est hors ligne
      if (_isConnected) {
        _isConnected = false;
        _controller.add(false);
        debugPrint('🔌 Connexion perdue: $e');
      }
      return false;
    }
  }

  /// Force une vérification immédiate (pour les cas urgents)
  Future<bool> forceCheck() async {
    _lastCheck = null; // Réinitialiser pour forcer la vérification
    return await checkConnectivity();
  }

  /// Libérer les ressources
  void dispose() {
    _checkTimer?.cancel();
    _controller.close();
  }
}








