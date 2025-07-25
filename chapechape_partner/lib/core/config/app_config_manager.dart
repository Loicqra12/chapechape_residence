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
    Environment environment = Environment.development,
    bool autoDetectIp = true,
  }) async {
    _environment = environment;
    
    // Initialiser le service de détection d'IP
    _ipDetectionService = await IpDetectionService.initialize();
    
    // Charger la configuration depuis les préférences
    final prefs = await SharedPreferences.getInstance();
    _useCustomServerUrl = prefs.getBool(_customServerUrlKey) ?? false;
    _useSecureConnection = prefs.getBool(_useSecureConnectionKey) ?? false;
    
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
              // Suppression du suffixe /api pour éviter les problèmes de chemin
              'apiUrl': '${_useSecureConnection ? 'https' : 'http'}://192.168.1.70:4000',
              'apiBaseUrl': '${_useSecureConnection ? 'https' : 'http'}://192.168.1.70:4000',
              'wsUrl': '${_useSecureConnection ? 'wss' : 'ws'}://192.168.1.70:4000/ws',
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
              'apiUrl': '${_useSecureConnection ? 'https' : 'http'}://api.chapechaperesidence.com/api',
              'apiBaseUrl': '${_useSecureConnection ? 'https' : 'http'}://api.chapechaperesidence.com',
              'wsUrl': '${_useSecureConnection ? 'wss' : 'ws'}://api.chapechaperesidence.com/ws',
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
        'apiUrl': '${_useSecureConnection ? 'https' : 'http'}://192.168.1.70:4000/api',
        'apiBaseUrl': '${_useSecureConnection ? 'https' : 'http'}://192.168.1.70:4000',
        'wsUrl': '${_useSecureConnection ? 'wss' : 'ws'}://192.168.1.70:4000/ws',
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
  static String get apiUrl => _config['apiUrl'] as String? ?? 'http://192.168.1.70:4000/api';
  static String get apiBaseUrl => _config['apiBaseUrl'] as String? ?? 'http://192.168.1.70:4000';
  static String get wsUrl => _config['wsUrl'] as String? ?? 'ws://192.168.1.70:4000/ws';
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
  
  /// Liste des patterns d'images de résidences problématiques connus
  static final List<String> _knownProblematicResidenceImagePatterns = [
    // Ajouter ici les patterns d'images problématiques pour les résidences
    'residences-', // Pattern générique pour les anciennes images
  ];
  
  /// Construit une URL d'image de résidence complète
  static String getResidenceImageUrl(String path) {
    // Si l'URL est vide ou invalide, retourner une chaîne vide
    if (path.isEmpty || 
        path.contains('placeholder.com') || 
        path.contains('undefined') || 
        path.contains('null')) {
      debugPrint('URL d\'image de résidence problématique détectée: $path - Elle sera ignorée');
      return '';
    }
    
    // Vérifier si l'image fait partie des images problématiques connues
    for (final problematicPattern in _knownProblematicResidenceImagePatterns) {
      if (path.contains(problematicPattern)) {
        debugPrint('Image de résidence problématique connue détectée: $path - Elle sera ignorée');
        return '';
      }
    }
    
    // Vérifier les URLs problematiques communes aux profils
    for (final problematicPattern in _knownProblematicImagePatterns) {
      if (path.contains(problematicPattern)) {
        debugPrint('Image problématique connue détectée dans résidence: $path - Elle sera ignorée');
        return '';
      }
    }
    
    // Vérifier si c'est une URL Cloudinary
    if (path.contains('cloudinary.com') || path.contains('res.cloudinary.com')) {
      debugPrint('URL Cloudinary de résidence détectée: $path');
      return path;
    }
    
    // Déjà une URL complète
    if (path.startsWith('http')) {
      debugPrint('URL d\'image de résidence déjà complète: $path');
      return path;
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
  
  /// Liste des patterns d'images problématiques connus
  static final List<String> _knownProblematicImagePatterns = [
    'images-1745027999174-175590833.jpg',
    'images-1745120501449-279771060.jpg',
    'images-1745118259981-271943468.jpg',
    'images-1745119349926-381849983.jpg',
    'images-1745119349926-381849983.jpg',
    'images-1745118259981-271943468.jpg',
    'images-1745120501449-279771060.jpg'
  ];
  
  /// Construit une URL d'image de profil complète
  static String getProfileImageUrl(String path) {
    // Si l'URL est vide ou invalide, retourner une chaîne vide
    if (path.isEmpty || 
        path.contains('placeholder.com') || 
        path.contains('undefined') || 
        path.contains('null')) {
      debugPrint('URL d\'image problématique détectée: $path - Elle sera ignorée');
      return '';
    }
    
    // Vérifier si l'image fait partie des images problématiques connues
    for (final problematicPattern in _knownProblematicImagePatterns) {
      if (path.contains(problematicPattern)) {
        debugPrint('Image problématique connue détectée: $path - Elle sera ignorée');
        return '';
      }
    }
    
    // Vérifier si c'est une URL Cloudinary
    if (path.contains('cloudinary.com') || path.contains('res.cloudinary.com')) {
      debugPrint('URL Cloudinary détectée: $path');
      return path;
    }
    
    // Déjà une URL complète
    if (path.startsWith('http')) {
      debugPrint('URL d\'image déjà complète: $path');
      return path;
    }
    
    final baseUrl = apiBaseUrl;
    String result;
    
    // CORRECTION IMPORTANTE: rediriger les requêtes /uploads/images-* vers /uploads/profiles/
    if (path.contains('/uploads/images-') || path.contains('uploads/images-')) {
      // Remplacer 'images-' par 'profile-' pour pointer vers le bon dossier
      String correctedPath = path.replaceAll('images-', 'profile-');
      // Remplacer '/uploads/' par '/uploads/profiles/' pour corriger le chemin du dossier
      correctedPath = correctedPath.replaceAll('/uploads/', '/uploads/profiles/');
      correctedPath = correctedPath.replaceAll('uploads/', '/uploads/profiles/');
      
      // Assurer que le chemin commence par /
      if (!correctedPath.startsWith('/')) {
        correctedPath = '/$correctedPath';
      }
      
      result = '$baseUrl$correctedPath';
      debugPrint('URL d\'image corrigée de $path vers $result');
      return result;
    }
    
    // Gestion normale des chemins
    if (path.startsWith('/uploads/profiles/')) {
      // Chemin déjà complet avec le sous-dossier profiles
      result = '$baseUrl$path';
    } else if (path.startsWith('/uploads/')) {
      // Ajouter 'profiles/' après '/uploads/'
      result = path.replaceFirst('/uploads/', '$baseUrl/uploads/profiles/');
    } else if (path.startsWith('/')) {
      // URL relative mais sans uploads, ajouter le chemin uploads/profiles
      result = '$baseUrl/uploads/profiles$path';
    } else if (path.startsWith('uploads/profiles/')) {
      result = '$baseUrl/$path';
    } else {
      // URL sans slash initial, ajouter le chemin complet avec slash
      result = '$baseUrl/uploads/profiles/$path';
    }
    
    debugPrint('URL d\'image construite: $result');
    return result;
  }
  
  /// Vérifie si le serveur est accessible
  static Future<bool> isServerReachable() async {
    return await _ipDetectionService?.isServerReachable() ?? false;
  }
  
  /// Retourne la liste des patterns d'images problématiques
  static List<String> getProblematicImagePatterns() {
    return List.from(_knownProblematicImagePatterns);
  }
  
  /// Retourne la liste des patterns d'images de résidences problématiques
  static List<String> getProblematicResidenceImagePatterns() {
    return List.from(_knownProblematicResidenceImagePatterns);
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
  static String get serverIp => _ipDetectionService?.serverIp ?? '192.168.1.70';
  
  /// Obtient le port actuel du serveur
  static int get serverPort => _ipDetectionService?.serverPort ?? 4000;
}
