import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../image_optimization_service.dart';

/// Service de détection de la qualité de connexion pour optimiser l'expérience utilisateur
class ConnectionQualityService {
  static final ConnectionQualityService _instance = ConnectionQualityService._internal();
  factory ConnectionQualityService() => _instance;
  
  // Constantes pour la détection de la vitesse
  static const _probeUrl = 'https://www.google.com/favicon.ico';
  static const _slowConnectionThresholdMs = 1500; // Seuil pour une connexion lente (ms)
  static const _offlineTimeoutMs = 5000; // Délai avant de considérer comme hors-ligne
  
  // État de la connexion
  bool _isOffline = false;
  bool _isSlowConnection = false;
  DateTime _lastCheck = DateTime.now();
  
  // Référence au service d'optimisation d'images
  final ImageOptimizationService _imageOptimizationService = ImageOptimizationService();
  
  // Timer pour les vérifications périodiques
  Timer? _periodicCheckTimer;
  
  ConnectionQualityService._internal();
  
  /// Initialise le service et démarre la vérification périodique
  Future<void> initialize() async {
    if (!kIsWeb) {
      // Faire une vérification initiale
      await checkConnectionQuality();
      
      // Démarrer les vérifications périodiques (toutes les 30 secondes)
      _periodicCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        checkConnectionQuality();
      });
    }
  }
  
  /// Arrête les vérifications périodiques
  void dispose() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = null;
  }
  
  /// État actuel: connexion lente
  bool get isSlowConnection => _isSlowConnection;
  
  /// État actuel: hors ligne
  bool get isOffline => _isOffline;
  
  /// Date de la dernière vérification
  DateTime get lastCheck => _lastCheck;
  
  /// Vérifie la qualité de la connexion actuelle
  Future<void> checkConnectionQuality() async {
    if (kIsWeb) {
      // Sur le web, on suppose toujours en ligne avec une bonne connexion
      _updateStatus(false, false);
      return;
    }
    
    try {
      // Mesurer le temps de réponse
      final stopwatch = Stopwatch()..start();
      
      final response = await http.get(Uri.parse(_probeUrl))
          .timeout(const Duration(milliseconds: _offlineTimeoutMs));
      
      stopwatch.stop();
      
      // Mettre à jour l'état en fonction du temps de réponse
      final responseTime = stopwatch.elapsedMilliseconds;
      final isSlowConnection = responseTime > _slowConnectionThresholdMs;
      
      _updateStatus(isSlowConnection, false);
      
      debugPrint('🌐 Qualité de connexion: ${responseTime}ms, lente=${isSlowConnection}');
    } on TimeoutException catch (_) {
      _updateStatus(true, true);
      debugPrint('🌐 Timeout de connexion, considéré comme hors ligne');
    } on SocketException catch (_) {
      _updateStatus(true, true);
      debugPrint('🌐 Erreur socket, considéré comme hors ligne');
    } catch (e) {
      _updateStatus(true, true);
      debugPrint('🌐 Erreur lors de la vérification de la connexion: $e');
    } finally {
      _lastCheck = DateTime.now();
    }
  }
  
  /// Force une mise à jour de l'état
  void forceStatus({required bool isSlowConnection, required bool isOffline}) {
    _updateStatus(isSlowConnection, isOffline);
  }
  
  /// Met à jour l'état et notifie les services dépendants
  void _updateStatus(bool isSlowConnection, bool isOffline) {
    final hasChanged = _isSlowConnection != isSlowConnection || _isOffline != isOffline;
    
    _isSlowConnection = isSlowConnection;
    _isOffline = isOffline;
    
    if (hasChanged) {
      // Mettre à jour le service d'optimisation d'images
      _imageOptimizationService.updateConnectionStatus(
        isSlowConnection: _isSlowConnection,
        isOffline: _isOffline,
      );
      
      debugPrint('🌐 État de connexion mis à jour: lent=$_isSlowConnection, hors ligne=$_isOffline');
    }
  }
  
  /// Vérifie si une URL spécifique est accessible
  Future<bool> isUrlAccessible(String url) async {
    if (_isOffline) return false;
    
    try {
      final response = await http.head(Uri.parse(url))
          .timeout(const Duration(milliseconds: _offlineTimeoutMs));
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (e) {
      return false;
    }
  }
} 