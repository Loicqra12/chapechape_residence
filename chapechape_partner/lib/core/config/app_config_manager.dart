import 'package:flutter/foundation.dart';
import 'environment.dart';

class AppConfigManager {
  // Singleton pattern
  static final AppConfigManager _instance = AppConfigManager._internal();
  factory AppConfigManager() => _instance;
  AppConfigManager._internal();

  // État d'initialisation
  static bool _initialized = false;

  // Configuration actuelle
  static Map<String, dynamic> _config = {};

  // Initialisation de la configuration
  static Future<void> initialize({Environment? environment}) async {
    if (_initialized) return;

    // Définir l'environnement si spécifié
    if (environment != null) {
      EnvironmentConfig.setEnvironment(environment);
    }

    // Charger la configuration en fonction de l'environnement
    await _loadConfig();
    
    _initialized = true;
    debugPrint('🔧 Configuration initialisée: ${EnvironmentConfig.current}');
  }

  // Chargement de la configuration
  static Future<void> _loadConfig() async {
    try {
      switch (EnvironmentConfig.current) {
        case Environment.development:
          _config = {
            'appName': 'ChapeChape Partner (Dev)',
            'apiUrl': 'http://192.168.1.77:4000/api',
            'apiBaseUrl': 'http://192.168.1.77:4000',
            'wsUrl': 'ws://192.168.1.77:4000/ws',
            'apiVersion': 'v1',
            'apiTimeout': 30000,
            'wsReconnectInterval': 5000,
            'appVersion': '1.0.0-dev',
            'environment': 'development',
          };
          break;
        
        case Environment.staging:
          _config = {
            'appName': 'ChapeChape Partner (Staging)',
            'apiUrl': 'https://staging-api.chapechape.com/api',
            'apiBaseUrl': 'https://staging-api.chapechape.com',
            'wsUrl': 'wss://staging-api.chapechape.com/ws',
            'apiVersion': 'v1',
            'apiTimeout': 30000,
            'wsReconnectInterval': 5000,
            'appVersion': '1.0.0-staging',
            'environment': 'staging',
          };
          break;
        
        case Environment.production:
          _config = {
            'appName': 'ChapeChape Partner',
            'apiUrl': 'https://api.chapechape.com/api',
            'apiBaseUrl': 'https://api.chapechape.com',
            'wsUrl': 'wss://api.chapechape.com/ws',
            'apiVersion': 'v1',
            'apiTimeout': 30000,
            'wsReconnectInterval': 5000,
            'appVersion': '1.0.0',
            'environment': 'production',
          };
          break;
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement de la configuration: $e');
      // Utiliser les valeurs par défaut (développement) en cas d'erreur
      _config = {
        'appName': 'ChapeChape Partner (Fallback)',
        'apiUrl': 'http://192.168.1.77:4000/api',
        'apiBaseUrl': 'http://192.168.1.77:4000',
        'wsUrl': 'ws://192.168.1.77:4000/ws',
        'apiVersion': 'v1',
        'apiTimeout': 30000,
        'wsReconnectInterval': 5000,
        'appVersion': '1.0.0-fallback',
        'environment': 'development',
      };
    }
  }

  // Accesseurs de la configuration
  static String get appName => _config['appName'] as String;
  static String get apiUrl => _config['apiUrl'] as String;
  static String get apiBaseUrl => _config['apiBaseUrl'] as String;
  static String get wsUrl => _config['wsUrl'] as String;
  static String get apiVersion => _config['apiVersion'] as String;
  static int get apiTimeout => _config['apiTimeout'] as int;
  static int get wsReconnectInterval => _config['wsReconnectInterval'] as int;
  static String get appVersion => _config['appVersion'] as String;
  static String get environment => _config['environment'] as String;

  // Méthode utilitaire pour obtenir l'URL complète d'un endpoint
  static String getApiEndpoint(String path) {
    // Si le chemin commence déjà par http(s)://, retourner tel quel
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    
    // Assurer que le chemin commence par /
    String normalizedPath = path.startsWith('/') ? path : '/$path';
    
    // Construire l'URL complète
    return apiUrl + normalizedPath;
  }
  
  // Méthode utilitaire pour obtenir l'URL complète d'une ressource média (image, etc.)
  static String getMediaUrl(String path) {
    final mediaBaseUrl = _config['mediaBaseUrl'] ?? 'https://api.chapechape.com/media';
    
    // Nettoie le chemin d'accès pour éviter les doubles slashes
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    
    return '$mediaBaseUrl/$cleanPath';
  }
}
