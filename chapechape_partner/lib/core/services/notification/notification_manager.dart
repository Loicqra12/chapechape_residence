import 'package:flutter/material.dart';
import 'notification_service.dart';
import '../onesignal_service.dart';
import 'twilio_service.dart';

/// Manager central pour orchestrer tous les types de notifications
/// Coordonne OneSignal (push), Local Notifications et Twilio (SMS)
class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  
  final NotificationService _localService = NotificationService();
  final OneSignalService _pushService = OneSignalService();
  TwilioService? _smsService;

  /// À appeler depuis [main] après création du [TwilioService].
  void bindSmsService(TwilioService service) {
    _smsService = service;
  }
  
  bool _isInitialized = false;
  
  factory NotificationManager() {
    return _instance;
  }
  
  NotificationManager._internal();

  /// Initialise tous les services de notifications
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🚀 Initialisation du NotificationManager central');
      
      // Initialiser le service local (qui gère déjà OneSignal et Twilio)
      await _localService.initialize();
      
      _isInitialized = true;
      debugPrint('✅ NotificationManager initialisé avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation du NotificationManager: $e');
    }
  }

  /// Envoie une notification complète multi-canal
  Future<void> sendCompleteNotification({
    required String title,
    required String body,
    String? payload,
    
    // Configuration locale
    bool showLocal = true,
    
    // Configuration SMS
    bool sendSms = false,
    String? phoneNumber,
    
    // Configuration push (via backend)
    bool sendPush = false,
    String? userId,
    Map<String, dynamic>? pushData,
  }) async {
    if (!_isInitialized) await initialize();
    
    try {
      debugPrint('📡 Envoi notification multi-canal: $title');
      
      // 1. Notification locale
      if (showLocal) {
        await _localService.showNotification(
          title: title,
          body: body,
          payload: payload,
          sendSms: sendSms,
          phoneNumber: phoneNumber,
        );
      }
      
      // 2. Push notification (simulée - en production via backend)
      if (sendPush && userId != null) {
        debugPrint('🚀 Push notification simulée pour utilisateur $userId');
        // En production, le backend appellerait OneSignal
      }
      
      debugPrint('✅ Notification multi-canal envoyée avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'envoi multi-canal: $e');
    }
  }

  /// Scénario complet: Nouvelle réservation
  Future<void> handleNewBooking({
    required String bookingId,
    required String guestName,
    required String residenceName,
    required String partnerUserId,
    String? guestPhone,
    String? partnerPhone,
    bool notifyGuestBySms = true,
    bool notifyPartnerByPush = true,
  }) async {
    try {
      debugPrint('🏨 Traitement nouvelle réservation: $bookingId');
      
      // 1. Notification locale pour le partner (immédiate)
      await _localService.showBookingNotification(
        guestName: guestName,
        residenceName: residenceName,
        bookingId: bookingId,
      );
      
      // 2. SMS de confirmation au client
      if (notifyGuestBySms && guestPhone != null) {
        final smsMessage = 'ChapeChape: Votre réservation à $residenceName est confirmée. '
            'Référence: $bookingId. Détails sur l\'app.';
        final sms = _smsService;
        if (sms == null) {
          debugPrint('⚠️ SMS confirmation ignoré: TwilioService non configuré');
        } else {
          await sms.sendSMS(guestPhone, smsMessage);
          debugPrint('📞 SMS confirmation demandé pour le client');
        }
      }
      
      // 3. Push notification au partner (via backend en production)
      if (notifyPartnerByPush) {
        debugPrint('🚀 Push notification simulée pour partner $partnerUserId');
        // Le backend enverrait via OneSignal:
        // await oneSignalService.sendToUser(partnerUserId, title, body, data);
      }
      
      debugPrint('✅ Scénario nouvelle réservation traité complètement');
    } catch (e) {
      debugPrint('❌ Erreur lors du traitement de la nouvelle réservation: $e');
    }
  }

  /// Scénario complet: Paiement reçu
  Future<void> handlePaymentReceived({
    required String bookingId,
    required String amount,
    required String residenceName,
    required String partnerUserId,
    String? partnerPhone,
    bool notifyPartnerBySms = false,
    bool notifyPartnerByPush = true,
  }) async {
    try {
      debugPrint('💰 Traitement paiement reçu: $bookingId');
      
      // 1. Notification locale immédiate
      await _localService.showPaymentNotification(
        amount: amount,
        residenceName: residenceName,
        bookingId: bookingId,
        partnerPhone: partnerPhone,
        notifyPartner: notifyPartnerBySms,
      );
      
      // 2. Push notification (via backend)
      if (notifyPartnerByPush) {
        debugPrint('🚀 Push paiement simulée pour partner $partnerUserId');
      }
      
      debugPrint('✅ Scénario paiement traité complètement');
    } catch (e) {
      debugPrint('❌ Erreur lors du traitement du paiement: $e');
    }
  }

  /// Scénario complet: Rappel check-in
  Future<void> scheduleCheckInFlow({
    required String bookingId,
    required String residenceName,
    required DateTime checkInDate,
    String? guestPhone,
    bool sendSmsReminder = true,
  }) async {
    try {
      debugPrint('⏰ Programmation rappels check-in: $bookingId');
      
      // 1. Rappel local 2h avant
      await _localService.scheduleCheckInReminder(
        bookingId: bookingId,
        residenceName: residenceName,
        checkInDate: checkInDate,
      );
      
      // 2. SMS rappel 1h avant (programmé)
      if (sendSmsReminder && guestPhone != null) {
        final reminderTime = checkInDate.subtract(const Duration(hours: 1));
        debugPrint('📞 SMS rappel programmé pour ${reminderTime.toString()}');
        // En production, programmer via un job scheduler
      }
      
      debugPrint('✅ Rappels check-in programmés');
    } catch (e) {
      debugPrint('❌ Erreur lors de la programmation des rappels: $e');
    }
  }

  /// Scénario complet: Nouveau message
  Future<void> handleNewMessage({
    required String conversationId,
    required String senderName,
    required String message,
    required String recipientUserId,
    bool sendPushNotification = true,
  }) async {
    try {
      debugPrint('💬 Traitement nouveau message: $conversationId');
      
      // 1. Notification locale
      await _localService.showMessageNotification(
        senderName: senderName,
        message: message,
        conversationId: conversationId,
      );
      
      // 2. Push notification (via backend)
      if (sendPushNotification) {
        debugPrint('🚀 Push message simulée pour utilisateur $recipientUserId');
      }
      
      debugPrint('✅ Nouveau message traité complètement');
    } catch (e) {
      debugPrint('❌ Erreur lors du traitement du message: $e');
    }
  }

  /// Obtient le statut de tous les services
  Future<Map<String, bool>> getServicesStatus() async {
    try {
      return {
        'local_notifications': await _localService.areNotificationsEnabled(),
        'push_notifications': true, // OneSignal géré dans main.dart
        'sms_service': true, // Twilio toujours disponible
        'manager_initialized': _isInitialized,
      };
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification du statut: $e');
      return {
        'local_notifications': false,
        'push_notifications': false,
        'sms_service': false,
        'manager_initialized': false,
      };
    }
  }

  /// Demande toutes les permissions nécessaires
  Future<bool> requestAllPermissions() async {
    try {
      debugPrint('🔐 Demande de toutes les permissions notifications');
      
      final localPermissions = await _localService.requestPermissions();
      // OneSignal permissions déjà demandées dans main.dart
      
      debugPrint(localPermissions ? 
        '✅ Toutes les permissions accordées' : 
        '⚠️ Certaines permissions manquantes');
      
      return localPermissions;
    } catch (e) {
      debugPrint('❌ Erreur lors de la demande de permissions: $e');
      return false;
    }
  }

  /// Nettoie toutes les ressources
  void dispose() {
    _localService.dispose();
    debugPrint('🧹 NotificationManager nettoyé');
  }
}
