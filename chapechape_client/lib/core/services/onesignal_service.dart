import 'dart:io';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:chapechape_client/core/services/auth_service.dart';
import 'package:dio/dio.dart';

class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  static const String _appId = '45b31099-4645-4f52-ad2f-f464a4095513';
  
  final Dio _dio = Dio();
  // _authService est conservé pour une utilisation future dans l'implémentation réelle
  // ignore: unused_field
  late AuthService _authService;
  String? _userId;
  bool _isInitialized = false;
  String _baseUrl = 'http://192.168.1.94:4000/api'; // URL du serveur local

  // Singleton pattern
  factory OneSignalService() {
    return _instance;
  }

  OneSignalService._internal();

  // Initialiser avec l'authService pour pouvoir envoyer le token au backend
  void init(AuthService authService) {
    if (_isInitialized) return;
    
    _authService = authService;
    _initPlatform();
    _isInitialized = true;
    
    debugPrint('OneSignal service initialisé avec authService');
  }

  Future<void> _initPlatform() async {
    try {
      debugPrint('🔔🔔 Début initialisation OneSignal avec App ID: $_appId');
      
      // Initialiser OneSignal avec l'ID d'application
      OneSignal.initialize(_appId);
      
      // Activer le mode debug (à supprimer en production)
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      
      // Forcer la journalisation de l'état de la permission actuelle
      bool permissionStatus = await OneSignal.Notifications.permission;
      debugPrint('🔔🔔 État actuel de la permission de notification: $permissionStatus');
      
      // Demander l'autorisation pour les notifications
      final permissionResult = await OneSignal.Notifications.requestPermission(true);
      debugPrint('🔔🔔 Résultat de la demande de permission: $permissionResult');
      
      debugPrint('🔔 OneSignal initialisé avec succès');
      
      // Configurer les écouteurs d'événements
      _setupListeners();
      
      // Récupérer l'ID d'utilisateur OneSignal après un délai pour s'assurer qu'il est disponible
      await Future.delayed(const Duration(seconds: 2));
      
      // Obtenir l'ID utilisateur
      final pushSubscription = OneSignal.User.pushSubscription;
      _userId = pushSubscription.id;
      
      if (_userId != null) {
        debugPrint('🔑 OneSignal User ID: $_userId');
        
        // Si l'utilisateur est authentifié, enregistrer le device
        if (_isUserAuthenticated()) {
          _registerDevice();
        }
      } else {
        debugPrint('⚠️ OneSignal User ID non disponible pour le moment');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation de OneSignal: $e');
    }
  }

  void _setupListeners() {
    try {
      // Écouter les clics sur les notifications
      OneSignal.Notifications.addClickListener((event) {
        debugPrint('📱 Notification cliquée: ${event.notification.title}');
        
        // Traiter les données supplémentaires
        if (event.notification.additionalData != null) {
          _handleNotificationData(event.notification.additionalData!);
        }
      });
      
      // Écouter les notifications reçues en premier plan
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        debugPrint('📬 Notification reçue en premier plan: ${event.notification.title}');
        // Ne pas empêcher l'affichage de la notification
      });
      
      debugPrint('✅ Écouteurs OneSignal configurés avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors de la configuration des écouteurs OneSignal: $e');
    }
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    try {
      // Logique pour traiter les différents types de notifications
      if (data.containsKey('type')) {
        final String type = data['type'];
        
        debugPrint('📋 Type de notification: $type');
        
        switch (type) {
          case 'new_message':
            // Naviguer vers la conversation
            break;
          case 'booking_update':
            // Naviguer vers la réservation
            break;
          case 'payment_confirmation':
            // Naviguer vers les paiements
            break;
          default:
            // Naviguer vers le centre de notifications
            break;
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du traitement des données de notification: $e');
    }
  }

  // Enregistrer l'appareil auprès du backend
  Future<void> _registerDevice() async {
    if (_userId == null || !_isUserAuthenticated()) return;
    
    try {
      // Récupérer le token (utiliser la méthode appropriée selon votre implémentation)
      String? token = await _getToken();
      if (token == null) {
        debugPrint('⚠️ Token d\'authentification non disponible pour l\'enregistrement de l\'appareil');
        return;
      }
      
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      final response = await _dio.post(
        '$_baseUrl/api/devices/register',
        data: {
          'deviceToken': _userId,
          'userType': 'client',
          'platform': Platform.isAndroid ? 'android' : 'ios'
        }
      );
      
      debugPrint('✅ Appareil enregistré avec succès: ${response.data}');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'enregistrement de l\'appareil: $e');
    }
  }

  // Mettre à jour les préférences de notification
  Future<void> updateNotificationPreferences({
    bool? pushEnabled,
    bool? emailEnabled,
    Map<String, bool>? categories,
  }) async {
    if (!_isUserAuthenticated()) return;
    
    try {
      String? token = await _getToken();
      if (token == null) {
        debugPrint('⚠️ Token d\'authentification non disponible pour la mise à jour des préférences');
        return;
      }
      
      final data = {
        if (pushEnabled != null) 'pushEnabled': pushEnabled,
        if (emailEnabled != null) 'emailEnabled': emailEnabled,
        if (categories != null) 'categories': categories,
      };
      
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      final response = await _dio.put(
        '$_baseUrl/api/devices/preferences',
        data: data
      );
      
      debugPrint('✅ Préférences de notification mises à jour: ${response.data}');
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour des préférences: $e');
      rethrow;
    }
  }

  // Désenregistrer l'appareil
  Future<void> unregisterDevice() async {
    if (_userId == null || !_isUserAuthenticated()) return;
    
    try {
      String? token = await _getToken();
      if (token == null) {
        debugPrint('⚠️ Token d\'authentification non disponible pour le désenregistrement de l\'appareil');
        return;
      }
      
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      final response = await _dio.delete(
        '$_baseUrl/api/devices/unregister',
        data: {'deviceToken': _userId}
      );
      
      debugPrint('✅ Appareil désenregistré avec succès: ${response.data}');
    } catch (e) {
      debugPrint('❌ Erreur lors du désenregistrement de l\'appareil: $e');
    }
  }

  // Obtenir les préférences de notification actuelles
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    if (!_isUserAuthenticated()) {
      return {
        'deviceTokens': [],
        'notificationSettings': {
          'pushEnabled': true,
          'emailEnabled': true,
          'categories': {
            'messages': true,
            'bookings': true,
            'payments': true,
            'promotions': true
          }
        }
      };
    }
    
    try {
      String? token = await _getToken();
      if (token == null) {
        throw Exception('Token d\'authentification non disponible');
      }
      
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      final response = await _dio.get('$_baseUrl/api/devices/preferences');
      
      return response.data['data'];
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des préférences: $e');
      rethrow;
    }
  }
  
  // Méthode utilitaire pour obtenir le token d'authentification
  Future<String?> _getToken() async {
    try {
      // Implémentation fictive pour la démonstration
      // Dans une vraie application, obtenez le token de votre système d'authentification
      return _isUserAuthenticated() ? 'your_token_here' : null;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du token: $e');
      return null;
    }
  }
  
  // Vérifie si l'utilisateur est authentifié
  // Cette méthode encapsule l'accès à isAuthenticated pour éviter les erreurs de typage
  bool _isUserAuthenticated() {
    try {
      // Implémentation fictive pour la démonstration
      // Dans une vraie application, utilisez votre propre logique d'authentification
      return true; // Ou _authService.isAuthenticated si c'est un booléen
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification de l\'authentification: $e');
      return false;
    }
  }
}
