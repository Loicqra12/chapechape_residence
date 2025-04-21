import 'package:flutter/foundation.dart';
import 'environment.dart';

/// Gestionnaire central des configurations de l'application
class AppConfigManager {
  // Singleton pattern
  static final AppConfigManager _instance = AppConfigManager._internal();
  factory AppConfigManager() => _instance;
  AppConfigManager._internal();

  // État d'initialisation
  static bool _initialized = false;
  
  // Environnement actuel
  static Environment _environment = Environment.dev;

  // Configuration actuelle
  static Map<String, dynamic> _config = {};

  /// Initialise la configuration avec l'environnement spécifié
  static Future<void> initialize({Environment? environment}) async {
    if (_initialized) return;

    // Définir l'environnement si spécifié
    if (environment != null) {
      _environment = environment;
    }

    // Charger la configuration en fonction de l'environnement
    await _loadConfig();
    
    _initialized = true;
    debugPrint('🔧 Configuration initialisée: ${_environment.displayName}');
  }

  /// Charge la configuration correspondant à l'environnement actuel
  static Future<void> _loadConfig() async {
    try {
      switch (_environment) {
        case Environment.dev:
          _config = {
            'appName': 'ChapeChape Client (Dev)',
            'apiUrl': 'http://192.168.1.68:4000/api',
            'apiBaseUrl': 'http://192.168.1.68:4000',
            'mediaBaseUrl': 'http://192.168.1.68:4000/media',
            'wsUrl': 'ws://192.168.1.68:4000/ws',
            'apiVersion': 'v1',
            'apiTimeout': 30000,
            'wsReconnectInterval': 5000,
            'appVersion': '1.0.0-dev',
            'environment': 'development',
            'proxyUrl': null, // Ajout de la configuration proxy pour le développement
          };
          break;
        
        case Environment.staging:
          _config = {
            'appName': 'ChapeChape Client (Staging)',
            'apiUrl': 'https://staging-api.chapechape.com/api',
            'apiBaseUrl': 'https://staging-api.chapechape.com',
            'mediaBaseUrl': 'https://staging-api.chapechape.com/media',
            'wsUrl': 'wss://staging-api.chapechape.com/ws',
            'apiVersion': 'v1',
            'apiTimeout': 30000,
            'wsReconnectInterval': 5000,
            'appVersion': '1.0.0-staging',
            'environment': 'staging',
            'proxyUrl': null, // Ajout de la configuration proxy pour staging
          };
          break;
        
        case Environment.prod:
          _config = {
            'appName': 'ChapeChape Client',
            'apiUrl': 'https://api.chapechape.com/api',
            'apiBaseUrl': 'https://api.chapechape.com',
            'mediaBaseUrl': 'https://api.chapechape.com/media',
            'wsUrl': 'wss://api.chapechape.com/ws',
            'apiVersion': 'v1',
            'apiTimeout': 30000,
            'wsReconnectInterval': 5000,
            'appVersion': '1.0.0',
            'environment': 'production',
            'proxyUrl': null, // Ajout de la configuration proxy pour production
          };
          break;
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement de la configuration: $e');
      // Utiliser les valeurs par défaut (développement) en cas d'erreur
      _config = {
        'appName': 'ChapeChape Client (Fallback)',
        'apiUrl': 'http://192.168.1.68:4000/api',
        'apiBaseUrl': 'http://192.168.1.68:4000',
        'mediaBaseUrl': 'http://192.168.1.68:4000/media',
        'wsUrl': 'ws://192.168.1.68:4000/ws',
        'apiVersion': 'v1',
        'apiTimeout': 30000,
        'wsReconnectInterval': 5000,
        'appVersion': '1.0.0-fallback',
        'environment': 'development',
        'proxyUrl': null, // Ajout de la configuration proxy pour le fallback
      };
    }
  }

  /// Retourne l'environnement actuel
  static Environment get environment => _environment;
  
  /// Accesseurs de la configuration
  static String get appName => _config['appName'] as String;
  static String get apiUrl => _config['apiUrl'] as String;
  static String get apiBaseUrl => _config['apiBaseUrl'] as String;
  static String get wsUrl => _config['wsUrl'] as String;
  static String get apiVersion => _config['apiVersion'] as String;
  static int get apiTimeout => _config['apiTimeout'] as int;
  static int get wsReconnectInterval => _config['wsReconnectInterval'] as int;
  static String get appVersion => _config['appVersion'] as String;
  static String get environmentName => _config['environment'] as String;
  static String? get proxyUrl => _config['proxyUrl'] as String?;

  /// Méthode utilitaire pour obtenir l'URL complète d'un endpoint
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
  
  /// Méthode utilitaire pour obtenir l'URL complète d'une ressource média (image, etc.)
  static String getMediaUrl(String path) {
    final mediaBaseUrl = _config['mediaBaseUrl'] ?? 'https://api.chapechape.com/media';
    
    // Nettoie le chemin d'accès pour éviter les doubles slashes
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    
    return '$mediaBaseUrl/$cleanPath';
  }

  /// Vérifie si l'application est en mode débogage
  static bool get isDebug => _environment.isDebug;
}
