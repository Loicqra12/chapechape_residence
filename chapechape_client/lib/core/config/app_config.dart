import 'package:flutter/foundation.dart';
import 'app_config_manager.dart';
import 'environment.dart';

class AppConfig {
  // Singleton
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    // Sélectionner automatiquement l'environnement selon le mode de compilation
    const environment = kReleaseMode ? Environment.prod : Environment.dev;
    await AppConfigManager.initialize(environment: environment);
    
    debugPrint('🔧 [AppConfig] Initialisation en ${environment == Environment.prod ? 'PRODUCTION' : 'DÉVELOPPEMENT'}');
    _initialized = true;
  }

  static Future<void> _loadEnvironmentVariables() async {
    try {
      // Nous utilisons maintenant AppConfigManager pour gérer les environnements
      debugPrint('Configuration chargée avec succès');
    } catch (e) {
      debugPrint('Erreur lors du chargement de la configuration: $e');
      // Utiliser les valeurs par défaut en cas d'erreur
    }
  }

  // Accesseurs - Tous redirigés vers AppConfigManager
  static String get appName => AppConfigManager.appName;
  static String get apiUrl => AppConfigManager.apiUrl;
  static String get apiBaseUrl => AppConfigManager.apiBaseUrl;
  static String get wsUrl => AppConfigManager.wsUrl;
  static String get apiVersion => AppConfigManager.apiVersion;
  static int get apiTimeout => AppConfigManager.apiTimeout;
  static int get appEnvironment => AppConfigManager.environment.index;
  static String? get proxyUrl => AppConfigManager.proxyUrl;
  
  // Méthodes utilitaires
  static String getApiEndpoint(String path) => AppConfigManager.getApiEndpoint(path);
  static String getMediaUrl(String path) => AppConfigManager.getMediaUrl(path);
  
  // Helpers pour vérification environnement
  static bool get isProduction => AppConfigManager.environment == Environment.prod;
  static bool get isDebug => AppConfigManager.isDebug;
}
