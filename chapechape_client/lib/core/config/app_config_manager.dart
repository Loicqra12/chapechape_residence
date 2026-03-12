import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'environment.dart';
import 'package:chapechape_client/core/services/ip_detection_service.dart';

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
  static Environment _environment = Environment.prod;
  static Environment get environment => _environment;
  
  // Service de détection d'IP
  static IpDetectionService? _ipDetectionService;
  
  // Clés pour les préférences
  static const String _customServerUrlKey = 'custom_server_url_enabled';
  static const String _useSecureConnectionKey = 'use_secure_connection';
  
  // Indique si les connexions sécurisées (HTTPS) doivent être utilisées
  static bool _useSecureConnection = false;
  static bool get useSecureConnection => _useSecureConnection;
  static set useSecureConnection(bool value) => _setUseSecureConnection(value);
  
  // Indique si une URL personnalisée est utilisée
  static bool _useCustomServerUrl = false;
  static bool get useCustomServerUrl => _useCustomServerUrl;
  
  /// Initialise le gestionnaire de configuration
  static Future<void> initialize({
    Environment environment = Environment.prod, // 🚀 FORCER PRODUCTION PAR DÉFAUT
    bool autoDetectIp = true,
  }) async {
    _environment = environment;
    
    debugPrint('🔧 [DEBUG] Initialisation avec environnement: ${_environment.toString().split('.').last}');
    
    // Initialiser le service de détection d'IP
    _ipDetectionService = await IpDetectionService.initialize();
    
    // Charger la configuration depuis les préférences
    final prefs = await SharedPreferences.getInstance();
    
    // En production, toujours forcer l'URL officielle (pas d'URL personnalisée)
    if (_environment == Environment.prod) {
      _useCustomServerUrl = false;
      _useSecureConnection = true; // HTTPS obligatoire en production
      debugPrint('🔧 [DEBUG] Mode PRODUCTION détecté - URL personnalisée désactivée, HTTPS activé');
    } else {
      _useCustomServerUrl = prefs.getBool(_customServerUrlKey) ?? false;
      _useSecureConnection = prefs.getBool(_useSecureConnectionKey) ?? false;
      debugPrint('🔧 [DEBUG] Mode DEV/STAGING - useCustomServerUrl: $_useCustomServerUrl, useSecureConnection: $_useSecureConnection');
    }
    
    debugPrint('🔧 [DEBUG] Avant _loadConfig() - useCustomServerUrl: $_useCustomServerUrl, useSecureConnection: $_useSecureConnection');
    
    // Charger la configuration selon l'environnement
    _loadConfig();
    
    debugPrint('🔧 [DEBUG] Après _loadConfig() - URL API: ${_config['apiUrl']}');
    
    // ⛔ DÉSACTIVER COMPLÈTEMENT L'AUTODETECTION EN PRODUCTION
    if (_environment != Environment.prod && autoDetectIp && !_useCustomServerUrl) {
      debugPrint('🔧 [DEBUG] Autodetection d\'IP autorisée (non-production)');
      await _ipDetectionService?.autoDetectServerIp();
      // Recharger la configuration avec la nouvelle IP
      _loadConfig();
      debugPrint('🔧 [DEBUG] Après autodetection - URL API: ${_config['apiUrl']}');
    } else {
      debugPrint('🔧 [DEBUG] Autodetection d\'IP DÉSACTIVÉE (production ou autres conditions)');
    }
    
    debugPrint('🔧 Configuration initialisée pour l\'environnement: ${_environment.toString().split('.').last}');
    debugPrint('🔧 URL API FINALE: ${_config['apiUrl']}');
  }
  
  /// Active ou désactive l'utilisation d'une URL personnalisée
  static Future<void> setUseCustomServerUrl(bool value) async {
    _useCustomServerUrl = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_customServerUrlKey, value);
    _loadConfig(); // Recharger la configuration
  }
  
  /// Active ou désactive l'utilisation des connexions sécurisées (HTTPS)
  static Future<void> _setUseSecureConnection(bool value) async {
    _useSecureConnection = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useSecureConnectionKey, value);
    _loadConfig(); // Recharger la configuration
    debugPrint('🔒 Connexions sécurisées (HTTPS): ${value ? 'activées' : 'désactivées'}');
  }
  
  /// Change le protocole de connexion (HTTP/HTTPS)
  static Future<void> toggleSecureConnection() async {
    await _setUseSecureConnection(!_useSecureConnection);
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
        case Environment.dev:
          // Si nous utilisons une URL personnalisée, utiliser l'IP du service de détection
          if (_useCustomServerUrl && _ipDetectionService != null) {
            _config = {
              'appName': 'ChapeChape Client (Dev)',
              'apiUrl': _ipDetectionService!.serverApiUrl,
              'apiBaseUrl': _ipDetectionService!.serverBaseUrl,
              'mediaBaseUrl': _ipDetectionService!.serverMediaUrl,
              'wsUrl': _ipDetectionService!.serverWsUrl,
              'apiVersion': 'v1',
              'apiTimeout': 30000,
              'wsReconnectInterval': 5000,
              'appVersion': '1.0.0-dev',
              'environment': 'development',
              'proxyUrl': null,
            };
          } else {
            // Configuration par défaut
            _config = {
              'appName': 'ChapeChape Client (Dev)',
              'apiUrl': '${_useSecureConnection ? 'https' : 'http'}://192.168.1.82:4000/api',
              'apiBaseUrl': '${_useSecureConnection ? 'https' : 'http'}://192.168.1.82:4000',
              'mediaBaseUrl': '${_useSecureConnection ? 'https' : 'http'}://192.168.1.82:4000/media',
              'wsUrl': '${_useSecureConnection ? 'wss' : 'ws'}://192.168.1.82:4000/ws',
              'apiVersion': 'v1',
              'apiTimeout': 30000,
              'wsReconnectInterval': 5000,
              'appVersion': '1.0.0-dev',
              'environment': 'development',
              'proxyUrl': null,
            };
          }
          break;
        case Environment.staging:
          // Si nous utilisons une URL personnalisée, utiliser l'IP du service de détection
          if (_useCustomServerUrl && _ipDetectionService != null) {
            _config = {
              'appName': 'ChapeChape Client (Staging)',
              'apiUrl': _ipDetectionService!.serverApiUrl,
              'apiBaseUrl': _ipDetectionService!.serverBaseUrl,
              'mediaBaseUrl': _ipDetectionService!.serverMediaUrl,
              'wsUrl': _ipDetectionService!.serverWsUrl,
              'apiVersion': 'v1',
              'apiTimeout': 30000,
              'wsReconnectInterval': 5000,
              'appVersion': '1.0.0-staging',
              'environment': 'staging',
              'proxyUrl': null,
            };
          } else {
            // Configuration par défaut
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
              'proxyUrl': null,
            };
          }
          break;
        case Environment.prod:
          // Si nous utilisons une URL personnalisée, utiliser l'IP du service de détection
          if (_useCustomServerUrl && _ipDetectionService != null) {
            _config = {
              'appName': 'ChapeChape Client',
              'apiUrl': _ipDetectionService!.serverApiUrl,
              'apiBaseUrl': _ipDetectionService!.serverBaseUrl,
              'mediaBaseUrl': _ipDetectionService!.serverMediaUrl,
              'wsUrl': _ipDetectionService!.serverWsUrl,
              'apiVersion': 'v1',
              'apiTimeout': 30000,
              'wsReconnectInterval': 5000,
              'appVersion': '1.9.0',
              'environment': 'production',
              'proxyUrl': null,
            };
          } else {
            // Configuration par défaut
            _config = {
              'appName': 'ChapeChape Client',
              'apiUrl': '${_useSecureConnection ? 'https' : 'http'}://api.chapechaperesidence.com/api',
              'apiBaseUrl': '${_useSecureConnection ? 'https' : 'http'}://api.chapechaperesidence.com',
              'mediaBaseUrl': '${_useSecureConnection ? 'https' : 'http'}://api.chapechaperesidence.com/media',
              'wsUrl': '${_useSecureConnection ? 'wss' : 'ws'}://api.chapechaperesidence.com/ws',
              'apiVersion': 'v1',
              'apiTimeout': 30000,
              'wsReconnectInterval': 5000,
              'appVersion': '1.9.0',
              'environment': 'production',
              'proxyUrl': null,
            };
          }
          break;
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement de la configuration: $e');
      // Utiliser les valeurs par défaut (développement) en cas d'erreur
      _config = {
        'appName': 'ChapeChape Client (Fallback)',
        'apiUrl': '${_useSecureConnection ? 'https' : 'http'}://192.168.1.82:4000/api',
        'apiBaseUrl': '${_useSecureConnection ? 'https' : 'http'}://192.168.1.82:4000',
        'mediaBaseUrl': '${_useSecureConnection ? 'https' : 'http'}://192.168.1.82:4000/media',
        'wsUrl': '${_useSecureConnection ? 'wss' : 'ws'}://192.168.1.82:4000/ws',
        'apiVersion': 'v1',
        'apiTimeout': 30000,
        'wsReconnectInterval': 5000,
        'appVersion': '1.0.0-fallback',
        'environment': 'development',
        'proxyUrl': null,
      };
    }
  }

  /// Accesseurs de la configuration
  static String get appName => _config['appName'] as String;
  // Fallback vers l'API de production si la config échoue (branche google-play-submission)
  static String get apiUrl => _config['apiUrl'] as String? ?? 'https://api.chapechaperesidence.com/api';
  static String get apiBaseUrl => _config['apiBaseUrl'] as String? ?? 'https://api.chapechaperesidence.com';
  static String get mediaBaseUrl => _config['mediaBaseUrl'] as String? ?? 'https://api.chapechaperesidence.com/media';
  static String get wsUrl => _config['wsUrl'] as String? ?? 'wss://api.chapechaperesidence.com/ws';
  static String get apiVersion => _config['apiVersion'] as String;
  static int get apiTimeout => _config['apiTimeout'] as int;
  static int get wsReconnectInterval => _config['wsReconnectInterval'] as int;
  static String get appVersion => _config['appVersion'] as String;
  static String get environmentName => _config['environment'] as String;
  static String? get proxyUrl => _config['proxyUrl'] as String?;

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
    final baseUrl = mediaBaseUrl;
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

    if (path.startsWith('/uploads/')) {
      // Ajouter 'residences/' après '/uploads/' si elle n'y est pas déjà
      if (!path.startsWith('/uploads/residences/')) {
        String modifiedPath = path.replaceAll('/uploads/', '/uploads/residences/');
        return '$baseUrl$modifiedPath';
      }
      return '$baseUrl$path';
    } else if (path.startsWith('/')) {
      // URL relative mais sans uploads, ajouter le chemin complet avec residences
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

    if (path.startsWith('/')) {
      return '$baseUrl$path';
    } else if (path.startsWith('uploads/profiles')) {
      return '$baseUrl/$path';
    } else {
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
  static String get serverIp => _ipDetectionService?.serverIp ?? '192.168.1.82';

  /// Obtient le port actuel du serveur
  static int get serverPort => _ipDetectionService?.serverPort ?? 4000;
}
