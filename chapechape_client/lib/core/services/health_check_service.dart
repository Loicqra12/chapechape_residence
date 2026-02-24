import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service de vérification de santé du serveur optimisé
class HealthCheckService {
  static final HealthCheckService _instance = HealthCheckService._internal();
  
  DateTime? _lastServerCheck;
  static const Duration _serverCheckInterval = Duration(minutes: 15);
  bool _isServerHealthy = true;
  
  factory HealthCheckService() {
    return _instance;
  }

  HealthCheckService._internal();

  /// Vérifie si le serveur est accessible (avec rate limiting)
  Future<bool> isServerHealthy() async {
    // Éviter les vérifications trop fréquentes
    if (_lastServerCheck != null && 
        DateTime.now().difference(_lastServerCheck!) < _serverCheckInterval) {
      return _isServerHealthy;
    }
    
    try {
      _lastServerCheck = DateTime.now();
      
      // Utiliser l'endpoint ping dédié
      final response = await http.get(
        Uri.parse('http://192.168.1.94:4000/api/ping'),
      ).timeout(const Duration(seconds: 5));
      
      _isServerHealthy = response.statusCode == 200;
      debugPrint('🏥 Serveur ${_isServerHealthy ? 'accessible' : 'inaccessible'}');
      
      return _isServerHealthy;
    } catch (e) {
      _isServerHealthy = false;
      debugPrint('🏥 Serveur inaccessible: $e');
      return false;
    }
  }

  /// Force une vérification immédiate du serveur
  Future<bool> forceServerCheck() async {
    _lastServerCheck = null;
    return await isServerHealthy();
  }

  /// Vérifie la connectivité Internet générale
  Future<bool> isInternetAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('https://www.google.com'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('🌐 Internet non disponible: $e');
      return false;
    }
  }

  /// Obtient l'état complet de la connectivité
  Future<Map<String, bool>> getConnectivityStatus() async {
    final internetAvailable = await isInternetAvailable();
    final serverHealthy = await isServerHealthy();
    
    return {
      'internet': internetAvailable,
      'server': serverHealthy,
      'app_functional': internetAvailable, // L'app fonctionne si Internet est disponible
    };
  }
}








