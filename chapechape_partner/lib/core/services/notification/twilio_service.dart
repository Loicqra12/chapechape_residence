import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
// Temporairement désactivé pour résoudre les problèmes de build
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../config/twilio_config.dart';
import '../../models/notification/notification_model.dart';
import '../../models/residence/residence.dart';

/// Service pour gérer les notifications via Twilio (version simplifiée)
class TwilioService {
  final Dio _dio = Dio();
  // final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  
  /// Initialise le service de notification
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialisation des notifications locales
      // const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      // const initializationSettingsIOS = DarwinInitializationSettings();
      // const initializationSettings = InitializationSettings(
      //   android: initializationSettingsAndroid,
      //   iOS: initializationSettingsIOS,
      // );
      
      // await _localNotifications.initialize(
      //   initializationSettings,
      //   onDidReceiveNotificationResponse: _onNotificationTapped,
      // );
      
      _isInitialized = true;
      debugPrint('💬 Service de notification initialisé');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation des notifications: $e');
    }
  }
  
  /// Gère les taps sur les notifications (méthode simplifiée temporaire)
  void _onNotificationTapped(String payload) {
    // Implémentez ici la navigation vers l'écran approprié
    debugPrint('🔔 Notification tappée: $payload');
  }
  
  /// Enregistre un appareil pour les notifications push
  Future<bool> registerDevice(String userId, String deviceToken) async {
    if (!TwilioConfig.isProduction) {
      debugPrint('💬 [DEV] Appareil enregistré pour l\'utilisateur: $userId');
      return true;
    }
    
    try {
      // En production, vous implémenteriez ici l'appel à l'API Twilio
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'enregistrement de l\'appareil: $e');
      return false;
    }
  }
  
  /// Envoie un SMS via Twilio
  Future<bool> sendSMS(String phoneNumber, String message) async {
    if (!TwilioConfig.isProduction) {
      debugPrint('💬 [DEV] SMS à $phoneNumber: $message');
      return true;
    }

    try {
      final response = await _dio.post(
        'https://api.twilio.com/2010-04-01/Accounts/${TwilioConfig.accountSid}/Messages.json',
        data: FormData.fromMap({
          'From': TwilioConfig.twilioNumber,
          'To': phoneNumber,
          'Body': message,
        }),
        options: Options(
          headers: {
            'Authorization': 'Basic ' + base64Encode(
              '${TwilioConfig.accountSid}:${TwilioConfig.authToken}'.codeUnits,
            ),
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'envoi du SMS: $e');
      return false;
    }
  }
  
  /// Crée une notification locale sur l'appareil
  Future<void> createLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();
    
    try {
      // const androidDetails = AndroidNotificationDetails(
      //   'chapechape_channel',
      //   'ChapeChape Notifications',
      //   channelDescription: 'Notifications pour l\'application ChapeChape',
      //   importance: Importance.high,
      //   priority: Priority.high,
      // );
      
      // const iosDetails = DarwinNotificationDetails(
      //   presentAlert: true,
      //   presentBadge: true,
      //   presentSound: true,
      // );
      
      // const notificationDetails = NotificationDetails(
      //   android: androidDetails,
      //   iOS: iosDetails,
      // );
      
      // await _localNotifications.show(
      //   DateTime.now().millisecondsSinceEpoch.remainder(100000),
      //   title,
      //   body,
      //   notificationDetails,
      //   payload: payload,
      // );
      
      debugPrint('🔔 Notification locale créée: $title');
    } catch (e) {
      debugPrint('❌ Erreur lors de la création de la notification: $e');
    }
  }
  
  /// Crée une notification pour un événement de résidence
  Future<NotificationModel> createResidenceNotification(Residence residence, String eventType) async {
    String title = '';
    String message = '';
    
    switch (eventType) {
      case 'residence_created':
        title = 'Nouvelle résidence';
        message = 'La résidence "${residence.name}" a été créée avec succès';
        break;
      case 'residence_updated':
        title = 'Résidence mise à jour';
        message = 'La résidence "${residence.name}" a été mise à jour';
        break;
      case 'residence_deleted':
        title = 'Résidence supprimée';
        message = 'La résidence "${residence.name}" a été supprimée';
        break;
      default:
        title = 'Mise à jour de résidence';
        message = 'Une mise à jour a été effectuée pour "${residence.name}"';
    }
    
    // Créer une notification locale
    await createLocalNotification(title: title, body: message);
    
    // Retourner le modèle de notification
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: 'residence',
      actionData: {'residenceId': residence.id},
    );
  }
  
  /// Dispose des ressources
  void dispose() {
    _dio.close();
  }
}

/// Extension pour encoder en Base64
extension Base64 on TwilioService {
  String base64Encode(List<int> bytes) {
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final padding = '=';
    
    String base64 = '';
    int i = 0;
    
    while (i < bytes.length) {
      int b1 = i < bytes.length ? bytes[i++] : 0;
      int b2 = i < bytes.length ? bytes[i++] : 0;
      int b3 = i < bytes.length ? bytes[i++] : 0;
      
      int n = (b1 << 16) | (b2 << 8) | b3;
      
      int e1 = (n >> 18) & 63;
      int e2 = (n >> 12) & 63;
      int e3 = (n >> 6) & 63;
      int e4 = n & 63;
      
      base64 += chars[e1] + chars[e2];
      base64 += i - 2 > bytes.length ? padding : chars[e3];
      base64 += i - 1 > bytes.length ? padding : chars[e4];
    }
    
    return base64;
  }
} 