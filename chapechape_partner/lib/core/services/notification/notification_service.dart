import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'twilio_service.dart';

/// Service de notifications unifié pour l'app Partner
/// Orchestre OneSignal (push), Local Notifications et Twilio (SMS)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  // Services intégrés
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  TwilioService? _twilioService;

  /// À appeler depuis [main] après création du [TwilioService] (injection ApiService).
  void bindTwilioService(TwilioService service) {
    _twilioService = service;
  }
  
  bool _isInitialized = false;
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();

  /// Initialise tous les services de notifications
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🔔 Initialisation du service de notifications Partner unifié');
      
      // 1. Initialiser les notifications locales
      await _initializeLocalNotifications();
      
      // 2. Initialiser SMS (backend) si branché
      await _twilioService?.initialize();
      
      // 3. OneSignal est déjà initialisé dans main.dart
      debugPrint('✅ OneSignal déjà configuré dans main.dart');
      
      _isInitialized = true;
      debugPrint('✅ Service de notifications Partner unifié initialisé avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation des notifications: $e');
    }
  }
  
  /// Initialise les notifications locales Flutter
  Future<void> _initializeLocalNotifications() async {
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

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    debugPrint('✅ Notifications locales initialisées');
  }
  
  /// Gère les taps sur les notifications locales
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Notification locale tappée: ${response.payload}');
    if (response.payload != null) {
      _handleNotificationPayload(response.payload!);
    }
  }

  /// Affiche une notification locale complète
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    bool sendSms = false,
    String? phoneNumber,
  }) async {
    if (!_isInitialized) await initialize();
    
    try {
      // 1. Afficher notification locale
      await _showLocalNotification(
        title: title,
        body: body,
        payload: payload,
      );
      
      // 2. Envoyer SMS si demandé
      if (sendSms && phoneNumber != null) {
        final sms = _twilioService;
        if (sms == null) {
          debugPrint('⚠️ SMS ignoré: TwilioService non configuré (bindTwilioService)');
        } else {
          await sms.sendSMS(phoneNumber, '$title: $body');
          debugPrint('📞 SMS demandé pour $phoneNumber');
        }
      }
      
      debugPrint('✅ Notification complète envoyée: $title');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'affichage de la notification: $e');
    }
  }
  
  /// Affiche une notification locale native
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chapechape_partner_channel',
      'ChapeChape Partner Notifications',
      channelDescription: 'Notifications pour ChapeChape Partner',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
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

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
    
    debugPrint('📱 Notification locale affichée: $title');
  }

  /// Affiche une notification pour une nouvelle réservation
  Future<void> showBookingNotification({
    required String guestName,
    required String residenceName,
    required String bookingId,
    String? guestPhone,
    bool sendConfirmationSms = false,
  }) async {
    await showNotification(
      title: 'Nouvelle réservation',
      body: '$guestName a réservé $residenceName',
      payload: 'booking:$bookingId',
      sendSms: sendConfirmationSms,
      phoneNumber: guestPhone,
    );
  }

  /// Affiche une notification pour un paiement reçu
  Future<void> showPaymentNotification({
    required String amount,
    required String residenceName,
    required String bookingId,
    String? partnerPhone,
    bool notifyPartner = true,
  }) async {
    await showNotification(
      title: 'Paiement reçu',
      body: '$amount FCFA pour $residenceName',
      payload: 'payment:$bookingId',
      sendSms: notifyPartner,
      phoneNumber: partnerPhone,
    );
  }

  /// Affiche une notification pour un nouveau message
  Future<void> showMessageNotification({
    required String senderName,
    required String message,
    required String conversationId,
  }) async {
    await showNotification(
      title: 'Nouveau message de $senderName',
      body: message.length > 50 ? '${message.substring(0, 50)}...' : message,
      payload: 'message:$conversationId',
    );
  }
  
  /// Programme une notification de rappel
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();
    
    try {
      const androidDetails = AndroidNotificationDetails(
        'chapechape_partner_reminders',
        'ChapeChape Partner Reminders',
        channelDescription: 'Rappels pour ChapeChape Partner',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      
      debugPrint('⏰ Rappel programmé pour ${scheduledDate.toString()}: $title');
    } catch (e) {
      debugPrint('❌ Erreur lors de la programmation du rappel: $e');
    }
  }
  
  /// Programme un rappel de check-in
  Future<void> scheduleCheckInReminder({
    required String bookingId,
    required String residenceName,
    required DateTime checkInDate,
  }) async {
    final reminderDate = checkInDate.subtract(const Duration(hours: 2));
    
    await scheduleReminder(
      id: bookingId.hashCode,
      title: 'Check-in aujourd\'hui',
      body: 'N\'oubliez pas le check-in à $residenceName à ${checkInDate.hour}h',
      scheduledDate: reminderDate,
      payload: 'checkin:$bookingId',
    );
  }

  /// Annule toutes les notifications locales
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) await initialize();
    
    try {
      await _localNotifications.cancelAll();
      debugPrint('🗑️ Toutes les notifications locales annulées');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'annulation des notifications: $e');
    }
  }

  /// Annule une notification spécifique
  Future<void> cancelNotification(int id) async {
    if (!_isInitialized) await initialize();
    
    try {
      await _localNotifications.cancel(id);
      debugPrint('🗑️ Notification $id annulée');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'annulation de la notification $id: $e');
    }
  }

  /// Gère le payload d'une notification avec navigation
  void _handleNotificationPayload(String payload) {
    try {
      debugPrint('🔍 Traitement du payload: $payload');
      
      final parts = payload.split(':');
      if (parts.length != 2) return;
      
      final type = parts[0];
      final id = parts[1];
      
      switch (type) {
        case 'booking':
          debugPrint('📋 Navigation vers réservation $id');
          _navigateToBookingDetails(id);
          break;
        case 'payment':
          debugPrint('💰 Navigation vers paiement $id');
          _navigateToPaymentDetails(id);
          break;
        case 'message':
          debugPrint('💬 Navigation vers conversation $id');
          _navigateToConversation(id);
          break;
        case 'checkin':
          debugPrint('🏠 Navigation vers check-in $id');
          _navigateToCheckIn(id);
          break;
        default:
          debugPrint('❓ Type de payload inconnu: $type');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du traitement du payload: $e');
    }
  }
  
  /// Navigation vers détails réservation
  void _navigateToBookingDetails(String bookingId) {
    // TODO: Implémenter avec GoRouter
    debugPrint('🔗 Navigation vers /reservations/$bookingId');
  }
  
  /// Navigation vers détails paiement
  void _navigateToPaymentDetails(String paymentId) {
    // TODO: Implémenter avec GoRouter
    debugPrint('🔗 Navigation vers /payments/$paymentId');
  }
  
  /// Navigation vers conversation
  void _navigateToConversation(String conversationId) {
    // TODO: Implémenter avec GoRouter
    debugPrint('🔗 Navigation vers /messages/$conversationId');
  }
  
  /// Navigation vers check-in
  void _navigateToCheckIn(String bookingId) {
    // TODO: Implémenter avec GoRouter
    debugPrint('🔗 Navigation vers /checkin/$bookingId');
  }

  /// Vérifie si les notifications sont autorisées
  Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) await initialize();
    
    try {
      final bool? result = await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      return result ?? true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification des permissions: $e');
      return false;
    }
  }

  /// Demande les permissions de notification
  Future<bool> requestPermissions() async {
    if (!_isInitialized) await initialize();
    
    try {
      debugPrint('🔐 Demande de permissions de notification');
      
      // Android
      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final bool? androidResult = await androidImplementation?.requestNotificationsPermission();
      
      // iOS
      final iosImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final bool? iosResult = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      
      final result = androidResult ?? iosResult ?? true;
      debugPrint(result ? '✅ Permissions accordées' : '❌ Permissions refusées');
      return result;
    } catch (e) {
      debugPrint('❌ Erreur lors de la demande de permissions: $e');
      return false;
    }
  }
  
  /// Obtient les notifications en attente
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) await initialize();
    
    try {
      return await _localNotifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des notifications en attente: $e');
      return [];
    }
  }
  
  /// Nettoie les ressources
  void dispose() {
    _twilioService?.dispose();
  }
}
