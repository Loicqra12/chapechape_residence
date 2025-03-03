import 'package:flutter/foundation.dart';

class AppConfig {
  // Singleton
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    // Charger les variables d'environnement si nécessaire
    await _loadEnvironmentVariables();
    
    _initialized = true;
  }

  static Future<void> _loadEnvironmentVariables() async {
    try {
      // Ici vous pouvez charger des variables d'environnement depuis un fichier .env
      // ou d'autres sources si nécessaire
      debugPrint('Configuration chargée avec succès');
    } catch (e) {
      debugPrint('Erreur lors du chargement de la configuration: $e');
      // Utiliser les valeurs par défaut en cas d'erreur
    }
  }

  // Valeurs par défaut
  static const String appName = 'ChapeChape Résidences';
  static const String apiUrl = 'http://localhost:4000/api';
  static const String apiVersion = 'v1';
  static const String defaultLocale = 'fr';
  static const int apiTimeout = 30000;
  static const String wsUrl = 'ws://localhost:4000';
  static const int wsReconnectInterval = 5000;
  static const String appVersion = '1.0.0';
  static const String appBundleId = 'com.chapechape.residences';
  static const String environment = 'development';
  static const String? proxyUrl = null;

  // Variables d'environnement
  final Map<String, String> _env = {
    'API_URL': apiUrl,
    'API_VERSION': apiVersion,
    'APP_NAME': appName,
    'DEFAULT_LOCALE': defaultLocale,
    'API_TIMEOUT': apiTimeout.toString(),
    'WS_URL': wsUrl,
    'WS_RECONNECT_INTERVAL': wsReconnectInterval.toString(),
    'FLUTTER_APP_VERSION': appVersion,
    'FLUTTER_APP_BUNDLE_ID': appBundleId,
    'ENVIRONMENT': environment,
  };

  // Accesseur pour les variables d'environnement
  String get(String key, {String? defaultValue}) {
    return _env[key] ?? defaultValue ?? '';
  }

  // Mutateur pour les variables d'environnement
  void set(String key, String value) {
    _env[key] = value;
    debugPrint('AppConfig: $key = $value');
  }

  // Initialisation
  void init() {
    debugPrint('AppConfig initialisé avec API_URL: ${get('API_URL')}');
  }
}
