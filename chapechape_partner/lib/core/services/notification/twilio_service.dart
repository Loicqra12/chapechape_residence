import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/api_service.dart';
import '../../config/twilio_config.dart';
import '../../models/notification/notification_model.dart';
import '../../models/residence/residence.dart';

/// SMS côté Partner : uniquement via le backend (JWT), jamais d'appel direct à api.twilio.com.
class TwilioService {
  final ApiService _apiService;

  TwilioService({required ApiService apiService}) : _apiService = apiService;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isInitialized = true;
      debugPrint('💬 Service SMS Partner initialisé (backend Twilio)');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation du service SMS: $e');
    }
  }

  Future<bool> registerDevice(String userId, String deviceToken) async {
    if (!TwilioConfig.isProduction) {
      debugPrint('💬 [DEV] Appareil enregistré pour l\'utilisateur: $userId');
      return true;
    }

    try {
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'enregistrement de l\'appareil: $e');
      return false;
    }
  }

  /// Envoie un SMS via `POST /api/sms/send` (backend + Twilio).
  /// En non-production, simulation locale (comportement historique).
  Future<bool> sendSMS(String phoneNumber, String message) async {
    if (!TwilioConfig.isProduction) {
      debugPrint('💬 [DEV] SMS simulé vers $phoneNumber: $message');
      return true;
    }

    try {
      final response = await _apiService.post(
        '/sms/send',
        data: {
          'to': phoneNumber,
          'body': message,
        },
      );

      final ok = response.statusCode == 200 || response.statusCode == 201;
      final success = response.data is Map && response.data['success'] == true;
      return ok && success;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'envoi du SMS (backend): $e');
      return false;
    }
  }

  Future<void> createLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();
    debugPrint('🔔 Notification locale créée: $title');
  }

  Future<NotificationModel> createResidenceNotification(
      Residence residence, String eventType) async {
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

    await createLocalNotification(title: title, body: message);

    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: 'residence',
      actionData: {'residenceId': residence.id},
    );
  }

  void dispose() {}
}
