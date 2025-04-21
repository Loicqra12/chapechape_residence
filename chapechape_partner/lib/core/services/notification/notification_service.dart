// Temporairement désactivé pour résoudre les problèmes de build
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  // Temporairement désactivé pour résoudre les problèmes de build
  // final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService();

  Future<void> initialize() async {
    // Temporairement désactivé pour résoudre les problèmes de build
    /*
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Gérer le tap sur la notification
        debugPrint('Notification tapped: ${response.payload}');
      },
    );
    */
    debugPrint('⚠️ Service de notification désactivé temporairement');
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Temporairement désactivé pour résoudre les problèmes de build
    /*
    const androidDetails = AndroidNotificationDetails(
      'chapechape_partner_channel',
      'ChapeChape Partner Notifications',
      channelDescription: 'Notifications pour ChapeChape Partner',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
    */
    
    // Utiliser un print de débogage en attendant la réactivation des notifications
    debugPrint('📱 Notification simulée: $title - $body');
  }

  Future<void> cancelAllNotifications() async {
    // Temporairement désactivé pour résoudre les problèmes de build
    // await _notificationsPlugin.cancelAll();
    debugPrint('⚠️ Service de notification désactivé temporairement');
  }

  Future<void> cancelNotification(int id) async {
    // Temporairement désactivé pour résoudre les problèmes de build
    // await _notificationsPlugin.cancel(id);
    debugPrint('⚠️ Service de notification désactivé temporairement');
  }
}
