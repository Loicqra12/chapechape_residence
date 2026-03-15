import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:chapechape_client/core/utils/logger.dart';

/// Service de rapport d'erreurs pour l'application
/// Enregistre et envoie les erreurs à un service de monitoring
class ErrorReportingService {
  static final ErrorReportingService _instance = ErrorReportingService._internal();
  factory ErrorReportingService() => _instance;
  ErrorReportingService._internal();

  final _logger = AppLogger('ErrorReportingService');
  bool _isInitialized = false;
  
  /// Initialise le service de rapport d'erreurs
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Intercepter les erreurs Flutter (widgets, build, etc.)
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      reportError(details.exception, details.stack ?? StackTrace.current);
    };
    
    // CRUCIAL : intercepter les erreurs qui échappent à la Zone (ex: callbacks
    // moteur Flutter). Sans cela, l'exception est envoyée au natif et Android
    // tue l'app (sur Xiaomi : "Failed to mkdir /data/miuilog/stability/hprof/").
    // Retourner true = erreur gérée → l'app ne crashe pas.
    ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stackTrace) {
      reportError(error, stackTrace);
      return true;
    };
    
    // Intercepter les erreurs Zone non gérées
    runZonedGuarded(() {
      _logger.info('Service de rapport d\'erreurs initialisé');
    }, (error, stackTrace) {
      reportError(error, stackTrace);
    });
    
    _isInitialized = true;
    _logger.info('Service de rapport d\'erreurs initialisé avec succès');
  }
  
  /// Rapporte une erreur au service de monitoring
  void reportError(dynamic error, StackTrace stackTrace) {
    _logger.error('Erreur non gérée détectée', error, stackTrace);
    
    // À l'avenir, vous pourriez intégrer Firebase Crashlytics ou un autre service ici
    // Exemple:
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
    
    // Pour l'instant, nous enregistrons simplement l'erreur dans les logs
    if (kDebugMode) {
      print('🔴 ERREUR NON GÉRÉE: $error');
      print('STACK TRACE: $stackTrace');
    }
  }
  
  /// Enregistre un événement personnalisé dans le service de monitoring
  void logEvent(String name, [Map<String, dynamic>? parameters]) {
    _logger.info('Événement: $name, Paramètres: $parameters');
    
    // À l'avenir, vous pourriez ajouter Firebase Analytics ou un autre service ici
    // Exemple:
    // FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
  }
  
  /// Définit l'utilisateur actuel pour le suivi des erreurs
  void setUser(String userId, {String? email, String? name}) {
    // À l'avenir, vous pourriez configurer l'identité de l'utilisateur pour le service de monitoring
    // Exemple:
    // FirebaseCrashlytics.instance.setUserIdentifier(userId);
    
    _logger.info('Utilisateur défini: $userId, Email: $email, Nom: $name');
  }
} 