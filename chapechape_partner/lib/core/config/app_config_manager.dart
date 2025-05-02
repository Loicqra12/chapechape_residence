import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'environment.dart';
import 'package:chapechape_partner/core/services/ip_detection_service.dart';

/// Gestionnaire de configuration de l'application
/// Responsable de charger et fournir les configurations selon l'environnement
class AppConfigManager {
  // Singleton
  static final AppConfigManager _instance = AppConfigManager._internal();
  factory AppConfigManager() => _instance;
  AppConfigManager._internal();

  // Configuration actuelle
  static Map<String, dynamic> _config = {};
  
  // Environnement actuel
  static Environment _environment = Environment.development;
  static Environment get environment => _environment;
  
  // Service de détection d'IP
  static IpDetectionService? _ipDetectionService;
  
  // Clé pour stocker l'URL personnalisée du serveur
  static const String _customServerUrlKey = 'custom_server_url_enabled';
  
  // Indique si une URL personnalisée est utilisée
  static bool _useCustomServerUrl = false;
  static bool get useCustomServerUrl => _useCustomServerUrl;
  
  /// Initialise le gestionnaire de configuration
  static Future<void> initialize({
    Environment environment = Environment.development,
    bool autoDetectIp = true,
  }) async {
    _environment = environment;
    
    // Initialiser le service de détection d'IP
    _ipDetectionService = await IpDetectionService.initialize();
    
    // Charger la configuration depuis les préférences
    final prefs = await SharedPreferences.getInstance();
    _useCustomServerUrl = prefs.getBool(_customServerUrlKey) ?? false;
    
    // Charger la configuration selon l'environnement
    _loadConfig();
    
    // Tenter de détecter automatiquement l'IP du serveur si demandé
    if (autoDetectIp && !_useCustomServerUrl) {
      await _ipDetectionService?.autoDetectServerIp();
      // Recharger la configuration avec la nouvelle IP
      _loadConfig();
    }
    
    debugPrint('🔧 Configuration initialisée pour l\'environnement: ${_environment.toString().split('.').last}');
    debugPrint('🔧 URL API: ${_config['apiUrl']}');
  }
  
  /// Active ou désactive l'utilisation d'une URL personnalisée
  static Future<void> setUseCustomServerUrl(bool value) async {
    _useCustomServerUrl = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_customServerUrlKey, value);
    _loadConfig(); // Recharger la configuration
  }
  
  /// Définit une nouvelle adresse IP pour le serveur
  static Future<void> setServerIp(String ip) async {
    await _ipDetectionService?.setServerIp(ip);
    _loadConfig(); // Recharger la configuration
  }
  
  /// Définit un nouveau port pour le serveur
  static Future<void> setServerPort(int port) async {
    await _ipDetectionService?.setServerPort(port);
    _loadConfig(); // Recharger la configuration
  }
  
  /// Charge la configuration selon l'environnement actuel
  static void _loadConfig() {
    try {
      switch (_environment) {
        case Environment.development:
          // Si nous utilisons une URL personnalisée, utiliser l'IP du service de détection
          if (_useCustomServerUrl && _ipDetectionService != null) {
            _config = {
              'appName': 'ChapeChape Partner (Dev)',
              'apiUrl': _ipDetectionService!.serverApiUrl,
              'apiBaseUrl': _ipDetectionService!.serverBaseUrl,
              'wsUrl': _ipDetectionService!.serverWsUrl,
              'apiVersion': 'v1',
              'apiTimeout': 30000,
              'wsReconnectInterval': 5000,
              'appVersion': '1.0.0-dev',
              'environment': 'development',
            };
          } else {
            // Configuration par défaut
            _config = {
              'appName': 'ChapeChape Partner (Dev)',
              'apiUrl': 'http://192.168.1.66:4000/api',
              'apiBaseUrl': 'http://192.168.1.66:4000',
              'wsUrl': 'ws://192.168.1.66:4000/ws',
              'apiVersion': 'v1',
              'apiTimeout': 30000,
              'wsReconnectInterval': 5000,
              'appVersion': '1.0.0-dev',
              'environment': 'development',
            };
          }
          break;
        case Environment.staging:
          // Si nous utilisons une URL personnalisée, utiliser l'IP du service de détection
          if (_useCustomServerUrl && _ipDetectionService != null) {
            _config = {
              'appName': 'ChapeChape Partner (Staging)',
              'apiUrl': _ipDetectionService!.serverApiUrl,
              'apiBaseUrl': _ipDetectionService!.serverBaseUrl,
              'wsUrl': _ipDetectionService!.serverWsUrl,
              'apiVersion': 'v1',
              'apiTimeout': 30000,
              'wsReconnectInterval': 5000,
              'appVersion': '1.0.0-staging',
              'environment': 'staging',
            };
          } else {
            // Configuration par défaut
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
          }
          break;
        case Environment.production:
          // Si nous utilisons une URL personnalisée, utiliser l'IP du service de détection
          if (_useCustomServerUrl && _ipDetectionService != null) {
            _config = {
              'appName': 'ChapeChape Partner',
              'apiUrl': _ipDetectionService!.serverApiUrl,
              'apiBaseUrl': _ipDetectionService!.serverBaseUrl,
              'wsUrl': _ipDetectionService!.serverWsUrl,
              'apiVersion': 'v1',
              'apiTimeout': 30000,
              'wsReconnectInterval': 5000,
              'appVersion': '1.0.0',
              'environment': 'production',
            };
          } else {
            // Configuration par défaut
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
          }
          break;
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement de la configuration: $e');
      // Utiliser les valeurs par défaut (développement) en cas d'erreur
      _config = {
        'appName': 'ChapeChape Partner (Fallback)',
        'apiUrl': 'http://192.168.1.66:4000/api',
        'apiBaseUrl': 'http://192.168.1.66:4000',
        'wsUrl': 'ws://192.168.1.66:4000/ws',
        'apiVersion': 'v1',
        'apiTimeout': 30000,
        'wsReconnectInterval': 5000,
        'appVersion': '1.0.0-fallback',
        'environment': 'development',
      };
    }
  }

  // Accesseurs de la configuration avec sécurité pour null
  static String get appName => _config['appName'] as String? ?? 'ChapeChape Partner';
  static String get apiUrl => _config['apiUrl'] as String? ?? 'http://192.168.1.66:4000/api';
  static String get apiBaseUrl => _config['apiBaseUrl'] as String? ?? 'http://192.168.1.66:4000';
  static String get wsUrl => _config['wsUrl'] as String? ?? 'ws://192.168.1.66:4000/ws';
  static String get apiVersion => _config['apiVersion'] as String? ?? 'v1';
  static int get apiTimeout => _config['apiTimeout'] as int? ?? 30000;
  static int get wsReconnectInterval => _config['wsReconnectInterval'] as int? ?? 5000;
  static String get appVersion => _config['appVersion'] as String? ?? '1.0.0';
  static String get environmentName => _config['environment'] as String? ?? 'development';

  /// Indique si l'application est en mode débogage
  static bool get isDebug => !kReleaseMode;
  
  /// Construit un point de terminaison d'API complet
  static String getApiEndpoint(String path) {
    final baseUrl = apiUrl;
    if (path.startsWith('/')) {
      return '$baseUrl$path';
    } else {
      return '$baseUrl/$path';
    }
  }
  
  /// Construit une URL de média complète
  static String getMediaUrl(String path) {
    final baseUrl = apiBaseUrl;
    if (path.startsWith('/')) {
      return '$baseUrl$path';
    } else if (path.startsWith('http')) {
      return path; // Déjà une URL complète
    } else {
      return '$baseUrl/$path';
    }
  }
  
  /// Construit une URL d'image de résidence complète
  static String getResidenceImageUrl(String path) {
    if (path.startsWith('http')) {
      return path; // Déjà une URL complète
    }
    
    final baseUrl = apiBaseUrl;
    
    if (path.startsWith('/uploads/residences/')) {
      // Chemin déjà complet avec le sous-dossier residences
      return '$baseUrl$path';
    } else if (path.startsWith('/uploads/')) {
      // Ajouter 'residences/' après '/uploads/'
      return path.replaceFirst('/uploads/', '$baseUrl/uploads/residences/');
    } else if (path.startsWith('/')) {
      // URL relative mais sans uploads, ajouter le chemin uploads/residences
      return '$baseUrl/uploads/residences$path';
    } else {
      // URL sans slash initial, ajouter le chemin complet avec slash
      return '$baseUrl/uploads/residences/$path';
    }
  }
  
  /// Construit une URL d'image de profil complète
  static String getProfileImageUrl(String path) {
    if (path.startsWith('http')) {
      return path; // Déjà une URL complète
    }
    
    final baseUrl = apiBaseUrl;
    
    if (path.startsWith('/uploads/profiles/')) {
      // Chemin déjà complet avec le sous-dossier profiles
      return '$baseUrl$path';
    } else if (path.startsWith('/uploads/')) {
      // Ajouter 'profiles/' après '/uploads/'
      return path.replaceFirst('/uploads/', '$baseUrl/uploads/profiles/');
    } else if (path.startsWith('/')) {
      // URL relative mais sans uploads, ajouter le chemin uploads/profiles
      return '$baseUrl/uploads/profiles$path';
    } else if (path.startsWith('uploads/profiles/')) {
      return '$baseUrl/$path';
    } else {
      // URL sans slash initial, ajouter le chemin complet avec slash
      return '$baseUrl/uploads/profiles/$path';
    }
  }
  
  /// Vérifie si le serveur est accessible
  static Future<bool> isServerReachable() async {
    return await _ipDetectionService?.isServerReachable() ?? false;
  }
  
  /// Tente de détecter automatiquement l'IP du serveur
  static Future<bool> autoDetectServerIp() async {
    final result = await _ipDetectionService?.autoDetectServerIp() ?? false;
    if (result) {
      _loadConfig(); // Recharger la configuration avec la nouvelle IP
    }
    return result;
  }
  
  /// Obtient l'adresse IP actuelle du serveur
  static String get serverIp => _ipDetectionService?.serverIp ?? '192.168.1.66';
  
  /// Obtient le port actuel du serveur
  static int get serverPort => _ipDetectionService?.serverPort ?? 4000;
}
