import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour détecter et gérer l'adresse IP du serveur
class IpDetectionService {
  static const String _serverIpKey = 'server_ip_address';
  static const String _serverPortKey = 'server_port';
  static const int _defaultPort = 4000;
  static const String _defaultIp = '192.168.1.68'; // IP par défaut mise à jour

  static IpDetectionService? _instance;
  late final SharedPreferences _prefs;

  // Constructeur privé
  IpDetectionService._();

  /// Initialise et retourne l'instance du service
  static Future<IpDetectionService> initialize() async {
    if (_instance != null) return _instance!;

    final instance = IpDetectionService._();
    await instance._initialize();
    _instance = instance;
    return instance;
  }

  /// Initialisation interne du service
  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Si aucune IP n'est enregistrée, définir l'IP par défaut
    if (!_prefs.containsKey(_serverIpKey)) {
      await _prefs.setString(_serverIpKey, _defaultIp);
    }
    
    // Si aucun port n'est enregistré, définir le port par défaut
    if (!_prefs.containsKey(_serverPortKey)) {
      await _prefs.setInt(_serverPortKey, _defaultPort);
    }
  }

  /// Obtient l'adresse IP du serveur actuellement configurée
  String get serverIp => _prefs.getString(_serverIpKey) ?? _defaultIp;

  /// Obtient le port du serveur actuellement configuré
  int get serverPort => _prefs.getInt(_serverPortKey) ?? _defaultPort;

  /// Définit une nouvelle adresse IP pour le serveur
  Future<void> setServerIp(String ip) async {
    await _prefs.setString(_serverIpKey, ip);
    debugPrint('🌐 Adresse IP du serveur mise à jour: $ip');
  }

  /// Définit un nouveau port pour le serveur
  Future<void> setServerPort(int port) async {
    await _prefs.setInt(_serverPortKey, port);
    debugPrint('🌐 Port du serveur mis à jour: $port');
  }

  /// Construit l'URL de base du serveur (http://ip:port)
  String get serverBaseUrl => 'http://$serverIp:$serverPort';

  /// Construit l'URL de l'API (http://ip:port/api)
  String get serverApiUrl => '$serverBaseUrl/api';

  /// Construit l'URL WebSocket (ws://ip:port/ws)
  String get serverWsUrl => 'ws://$serverIp:$serverPort/ws';

  /// Construit l'URL des médias (http://ip:port/media)
  String get serverMediaUrl => '$serverBaseUrl/media';

  /// Vérifie si le serveur est accessible
  Future<bool> isServerReachable() async {
    try {
      final response = await http.get(
        Uri.parse('$serverBaseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification du serveur: $e');
      return false;
    }
  }

  /// Détecte automatiquement l'adresse IP locale
  Future<List<String>> detectLocalIps() async {
    List<String> addresses = [];
    
    try {
      // Vérifier si nous sommes sur le Web
      if (kIsWeb) {
        return [_defaultIp]; // Impossible de détecter l'IP locale sur le Web
      }
      
      // Obtenir les interfaces réseau
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      
      // Filtrer pour obtenir uniquement les adresses IPv4 non-loopback
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && 
              !addr.isLoopback &&
              addr.address != '127.0.0.1') {
            addresses.add(addr.address);
          }
        }
      }
      
      // Si aucune adresse n'est trouvée, utiliser l'adresse par défaut
      if (addresses.isEmpty) {
        addresses.add(_defaultIp);
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la détection des adresses IP: $e');
      addresses.add(_defaultIp);
    }
    
    return addresses;
  }

  /// Teste la connectivité à plusieurs adresses IP et retourne la première qui répond
  Future<String?> findWorkingServerIp(List<String> ipAddresses) async {
    for (var ip in ipAddresses) {
      try {
        final testUrl = 'http://$ip:$serverPort/health';
        final response = await http.get(
          Uri.parse(testUrl),
        ).timeout(const Duration(seconds: 2));
        
        if (response.statusCode == 200) {
          return ip;
        }
      } catch (e) {
        // Continuer à la prochaine IP
        continue;
      }
    }
    return null; // Aucune IP ne répond
  }

  /// Tente de détecter et configurer automatiquement l'IP du serveur
  Future<bool> autoDetectServerIp() async {
    try {
      // Obtenir toutes les adresses IP locales
      final localIps = await detectLocalIps();
      debugPrint('🔍 Adresses IP locales détectées: $localIps');
      
      // Générer des adresses IP potentielles dans le même sous-réseau
      final potentialIps = <String>[];
      
      // Ajouter l'IP actuelle
      potentialIps.add(serverIp);
      
      // Ajouter les IPs locales
      potentialIps.addAll(localIps);
      
      // Pour chaque IP locale, générer des IPs dans le même sous-réseau
      for (var localIp in localIps) {
        final parts = localIp.split('.');
        if (parts.length == 4) {
          final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
          
          // Ajouter quelques IPs courantes dans le même sous-réseau
          potentialIps.add('$subnet.1');  // Souvent la passerelle
          potentialIps.add('$subnet.254'); // Souvent la passerelle alternative
          
          // Ajouter quelques IPs proches de l'IP locale
          final lastOctet = int.tryParse(parts[3]) ?? 0;
          for (var i = 1; i <= 5; i++) {
            if (lastOctet - i > 0) {
              potentialIps.add('$subnet.${lastOctet - i}');
            }
            if (lastOctet + i < 255) {
              potentialIps.add('$subnet.${lastOctet + i}');
            }
          }
        }
      }
      
      // Éliminer les doublons
      final uniqueIps = potentialIps.toSet().toList();
      debugPrint('🔍 Test de connectivité sur les IPs: $uniqueIps');
      
      // Trouver la première IP qui répond
      final workingIp = await findWorkingServerIp(uniqueIps);
      
      if (workingIp != null) {
        // Mettre à jour l'IP du serveur
        await setServerIp(workingIp);
        debugPrint('✅ Serveur détecté automatiquement à l\'adresse: $workingIp');
        return true;
      } else {
        debugPrint('❌ Aucun serveur détecté automatiquement');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la détection automatique du serveur: $e');
      return false;
    }
  }
}
