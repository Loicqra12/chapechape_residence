import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:chapechape_client/core/services/auth_service.dart';
import 'package:chapechape_client/core/config/app_config_manager.dart';
import 'package:chapechape_client/router/app_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chapechape_client/core/utils/secure_storage.dart';

class OneSignalService {
  static final OneSignalService _instance = OneSignalService._internal();
  static const String _appId = '45b31099-4645-4f52-ad2f-f464a4095513';
  static final FlutterSecureStorage _storage = AppSecureStorage.instance;
  
  final Dio _dio = Dio();
  // _authService est conservé pour une utilisation future dans l'implémentation réelle
  // ignore: unused_field
  late AuthService _authService;
  String? _userId;
  bool _isInitialized = false;
  bool _subscriptionObserverAttached = false;
  static const String _appKind = 'client';
  // Utiliser l'URL de l'API depuis AppConfigManager (production)
  String get _baseUrl => AppConfigManager.apiUrl;
  String _apiPath(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    if (_baseUrl.endsWith('/api')) {
      return '$_baseUrl$normalizedPath';
    }
    return '$_baseUrl/api$normalizedPath';
  }

  // Singleton pattern
  factory OneSignalService() {
    return _instance;
  }

  OneSignalService._internal();

  /// Initialise OneSignal (non bloquant pour runApp).
  /// L'enregistrement backend se fait via [syncAfterLogin] + observer subscription.
  Future<void> init(AuthService authService) async {
    if (_isInitialized) return;

    _authService = authService;

    try {
      debugPrint('🔔 Début initialisation OneSignal App ID: $_appId');
      OneSignal.initialize(_appId);

      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      }

      _setupListeners();
      _setupSubscriptionObserver();
      _isInitialized = true;

      // Permission : ne bloque pas l'auth ; sync si token déjà présent
      OneSignal.Notifications.requestPermission(true).then((granted) async {
        debugPrint('🔔 Permission notifications: $granted');
        if (await _hasAuthToken()) {
          await syncCurrentSubscription();
        }
      });

      debugPrint('✅ OneSignal service initialisé');
    } catch (e) {
      debugPrint('❌ Erreur initialisation OneSignal: $e');
    }
  }

  void _setupSubscriptionObserver() {
    if (_subscriptionObserverAttached) return;
    _subscriptionObserverAttached = true;

    OneSignal.User.pushSubscription.addObserver((state) async {
      final subscriptionId = state.current.id;
      debugPrint('🔔 Subscription OneSignal changée: $subscriptionId');
      _userId = subscriptionId;
      if (subscriptionId != null && await _hasAuthToken()) {
        await _registerDevice();
      }
    });
  }

  /// À appeler après AuthAuthenticated (login, register, cold start).
  Future<void> syncAfterLogin(String userId) async {
    if (userId.isEmpty) return;

    try {
      if (!_isInitialized) {
        debugPrint('⚠️ syncAfterLogin avant init OneSignal — retry court');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      await OneSignal.login(userId);
      OneSignal.User.addTags({'userType': _appKind, 'appKind': _appKind});
      await syncCurrentSubscription();
      debugPrint('✅ OneSignal syncAfterLogin OK ($userId)');
    } catch (e) {
      // Ne jamais faire échouer le login pour un problème push
      debugPrint('❌ syncAfterLogin OneSignal: $e');
    }
  }

  /// Lit la subscription courante et enregistre côté backend si possible.
  Future<void> syncCurrentSubscription() async {
    try {
      _userId = OneSignal.User.pushSubscription.id;
      if (_userId == null) {
        debugPrint('⚠️ Subscription OneSignal pas encore disponible');
        return;
      }
      if (await _hasAuthToken()) {
        await _registerDevice();
      }
    } catch (e) {
      debugPrint('❌ syncCurrentSubscription: $e');
    }
  }

  /// Désenregistre backend PUIS logout OneSignal — appeler AVANT purge JWT.
  Future<void> onLogout() async {
    try {
      await unregisterDevice();
    } catch (e) {
      debugPrint('⚠️ unregisterDevice au logout: $e');
    }
    try {
      await OneSignal.logout();
    } catch (e) {
      debugPrint('⚠️ OneSignal.logout: $e');
    }
  }

  void _setupListeners() {
    try {
      // Écouter les clics sur les notifications
      OneSignal.Notifications.addClickListener((event) {
        debugPrint('📱 Notification cliquée: ${event.notification.title}');
        
        // Traiter les données supplémentaires
        if (event.notification.additionalData != null) {
          _logPushDebug('click', event.notification.additionalData!);
          _handleNotificationData(event.notification.additionalData!);
        }
      });
      
      // Écouter les notifications reçues en premier plan
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        debugPrint('📬 Notification reçue en premier plan: ${event.notification.title}');
        if (event.notification.additionalData != null) {
          _logPushDebug('foreground', event.notification.additionalData!);
        }
        // Ne pas empêcher l'affichage de la notification
      });
      
      debugPrint('✅ Écouteurs OneSignal configurés avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors de la configuration des écouteurs OneSignal: $e');
    }
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    try {
      final String? rawType = data['pushType']?.toString() ?? data['type']?.toString();
      if (rawType == null || rawType.isEmpty) return;

      final String normalizedType = _normalizePushType(rawType);
      final String? deepLink = data['deepLink']?.toString();

      debugPrint('📋 Type push normalisé (client): $normalizedType');
      if (deepLink != null && deepLink.isNotEmpty) {
        debugPrint('🔗 Deep link push (client): $deepLink');
      }

      final targetRoute =
          _resolveClientRoute(normalizedType, deepLink: deepLink, data: data);
      _navigateToRoute(targetRoute);
    } catch (e) {
      debugPrint('❌ Erreur lors du traitement des données de notification: $e');
    }
  }

  void _logPushDebug(String event, Map<String, dynamic> data) {
    if (!kDebugMode) return;

    try {
      final payload = <String, dynamic>{
        'event': event,
        'pushType': data['pushType'],
        'deepLink': data['deepLink'],
        'entityId': data['entityId'],
        'type': data['type'],
        'bookingId': data['bookingId'],
        'reservationId': data['reservationId'],
        'paymentId': data['paymentId'],
        'payoutId': data['payoutId'],
        'keys': data.keys.toList(),
      };

      debugPrint('[PUSH_DEBUG][client] ${jsonEncode(payload)}');
    } catch (e) {
      debugPrint('[PUSH_DEBUG][client] (erreur log) $e');
    }
  }

  String _resolveClientRoute(
    String normalizedType, {
    String? deepLink,
    required Map<String, dynamic> data,
  }) {
    if (deepLink != null && deepLink.isNotEmpty && deepLink.startsWith('/')) {
      return deepLink;
    }

    switch (normalizedType) {
      case 'new_message':
        return '/chat';
      case 'booking_update':
        final bookingId =
            data['bookingId']?.toString() ?? data['reservationId']?.toString();
        if (bookingId != null && bookingId.isNotEmpty) {
          return '/booking-details/$bookingId';
        }
        return '/bookings';
      case 'payment_update':
        final paymentId =
            data['paymentId']?.toString() ?? data['payoutId']?.toString();
        if (paymentId != null && paymentId.isNotEmpty) {
          return '/payment/$paymentId';
        }
        return '/bookings';
      case 'security_alert':
      case 'promotion':
      case 'system_update':
      default:
        return '/notifications';
    }
  }

  void _navigateToRoute(String route) {
    try {
      AppRouter.router.go(route);
      debugPrint('✅ Navigation push client vers: $route');
    } catch (e) {
      debugPrint('⚠️ Navigation push client échouée ($route): $e');
    }
  }

  String _normalizePushType(String rawType) {
    if (rawType == 'new_message' ||
        rawType == 'booking_update' ||
        rawType == 'payment_update' ||
        rawType == 'security_alert' ||
        rawType == 'promotion' ||
        rawType == 'system_update') {
      return rawType;
    }

    if (rawType.contains('message')) return 'new_message';

    if (rawType.contains('booking') ||
        rawType.contains('arrival') ||
        rawType.contains('departure') ||
        rawType.contains('checkin') ||
        rawType.contains('checkout') ||
        rawType.contains('approval')) {
      return 'booking_update';
    }

    if (rawType.contains('payment') ||
        rawType.contains('deposit') ||
        rawType.contains('payout') ||
        rawType.contains('transfer')) {
      return 'payment_update';
    }

    if (rawType.contains('verification') ||
        rawType.contains('security') ||
        rawType.contains('login') ||
        rawType.contains('phone_changed')) {
      return 'security_alert';
    }

    if (rawType.contains('offer') ||
        rawType.contains('discount') ||
        rawType.contains('popular') ||
        rawType.contains('nearby') ||
        rawType.contains('availability')) {
      return 'promotion';
    }

    return 'system_update';
  }

  // Enregistrer l'appareil auprès du backend
  Future<void> _registerDevice() async {
    if (_userId == null || !await _hasAuthToken()) return;
    
    try {
      // Récupérer le token (utiliser la méthode appropriée selon votre implémentation)
      String? token = await _getToken();
      if (token == null) {
        debugPrint('⚠️ Token d\'authentification non disponible pour l\'enregistrement de l\'appareil');
        return;
      }
      
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      final response = await _dio.post(
        _apiPath('/devices/register'),
        data: {
          'deviceToken': _userId,
          'appKind': _appKind,
          'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
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
    if (!await _hasAuthToken()) return;
    
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
        _apiPath('/devices/preferences'),
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
    if (_userId == null || !await _hasAuthToken()) return;
    
    try {
      String? token = await _getToken();
      if (token == null) {
        debugPrint('⚠️ Token d\'authentification non disponible pour le désenregistrement de l\'appareil');
        return;
      }
      
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      final response = await _dio.delete(
        _apiPath('/devices/unregister'),
        data: {'deviceToken': _userId}
      );
      
      debugPrint('✅ Appareil désenregistré avec succès: ${response.data}');
    } catch (e) {
      debugPrint('❌ Erreur lors du désenregistrement de l\'appareil: $e');
    }
  }

  // Obtenir les préférences de notification actuelles
  Future<Map<String, dynamic>> getNotificationPreferences() async {
    if (!await _hasAuthToken()) {
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
      
      final response = await _dio.get(_apiPath('/devices/preferences'));
      
      return response.data['data'];
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des préférences: $e');
      rethrow;
    }
  }
  
  // Méthode utilitaire pour obtenir le token d'authentification
  Future<String?> _getToken() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null || token.trim().isEmpty) {
        return null;
      }
      return token;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du token: $e');
      return null;
    }
  }
  
  // Vérifie uniquement la présence d'un token côté client (appel léger).
  Future<bool> _hasAuthToken() async {
    try {
      final token = await _getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification de l\'authentification: $e');
      return false;
    }
  }
}
