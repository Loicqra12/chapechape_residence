import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification/twilio_service.dart';
import '../models/notification/notification_model.dart';
import '../models/notification/notification_preference.dart';
import '../config/twilio_config.dart';
import '../models/residence/residence.dart';
import '../services/api/api_service.dart';

/// Repository pour gérer les notifications
class NotificationRepository {
  final TwilioService _twilioService;
  final ApiService _apiService; // Nouveau
  static const String _prefsKey = 'notification_preferences';
  
  NotificationRepository(this._twilioService, this._apiService); // Injection de ApiService
  
  /// Récupérer les notifications avec pagination
  Future<PaginatedNotifications> getNotifications({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiService.get('/notifications', queryParameters: {
        'page': page,
        'limit': limit
      });
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return PaginatedNotifications.fromJson(response.data);
      }
      
      return PaginatedNotifications(
        notifications: [],
        total: 0,
        page: page,
        pages: 1,
      );
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des notifications: $e');
      return PaginatedNotifications(
        notifications: [],
        total: 0,
        page: page,
        pages: 1,
      );
    }
  }

  /// Récupérer le nombre de notifications non lues
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get('/notifications/unread/count');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        return (data is Map) ? (data['count'] ?? 0) : 0;
      }
      return 0;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du nombre de notifications non lues: $e');
      return 0;
    }
  }
  
  /// Marquer une notification comme lue
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _apiService.put('/notifications/$notificationId/read');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      debugPrint('❌ Erreur lors du marquage comme lu: $e');
      return false;
    }
  }

  /// Supprimer une notification (persiste côté serveur)
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await _apiService.delete('/notifications/$notificationId');
      return response.statusCode == 200 && (response.data['success'] ?? true);
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression de la notification: $e');
      return false;
    }
  }
  
  /// Récupère les préférences de l'utilisateur
  Future<NotificationPreference> getUserPreferences(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? json = prefs.getString('${_prefsKey}_$userId');
      
      if (json != null) {
        return NotificationPreference.fromJson(jsonDecode(json));
      }
      
      // Si aucune préférence n'existe, créer les préférences par défaut
      return NotificationPreference.defaultForUser(userId);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des préférences: $e');
      return NotificationPreference.defaultForUser(userId);
    }
  }
  
  /// Enregistre les préférences de l'utilisateur
  Future<bool> updatePreferences(NotificationPreference preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${_prefsKey}_${preferences.userId}',
        jsonEncode(preferences.toJson()),
      );
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde des préférences: $e');
      return false;
    }
  }
  
  /// Envoie un SMS si l'utilisateur a activé ce canal
  Future<bool> sendSmsNotification(String userId, String phoneNumber, String message) async {
    try {
      final preferences = await getUserPreferences(userId);
      
      // Vérifier si le canal SMS est activé
      if (preferences.channels['sms'] != true) {
        debugPrint('💬 SMS non envoyé: canal désactivé pour l\'utilisateur $userId');
        return false;
      }
      
      // Vérifier si on est dans les heures de silence
      final now = DateTime.now();
      final currentHour = now.hour;
      
      if (currentHour >= preferences.quietHoursStart || 
          currentHour < preferences.quietHoursEnd) {
        debugPrint('💬 SMS non envoyé: heures de silence (${preferences.quietHoursStart}h-${preferences.quietHoursEnd}h)');
        return false;
      }
      
      // Utiliser le numéro de téléphone spécifié dans les préférences s'il existe
      final targetPhone = preferences.phoneNumber ?? phoneNumber;
      
      return await _twilioService.sendSMS(targetPhone, message);
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'envoi du SMS: $e');
      return false;
    }
  }
  
  /// Gère les événements de résidence pour créer des notifications
  Future<void> handleResidenceEvent(String eventType, Map<String, dynamic> data) async {
    try {
      // Vérifier si l'événement est activé dans les préférences
      // Note: Ici nous n'avons pas encore l'ID de l'utilisateur, donc on utilise
      // les préférences par défaut pour l'instant
      if (!TwilioConfig.defaultNotificationPreferences[eventType]!) {
        debugPrint('💬 Notification non envoyée: type $eventType désactivé');
        return;
      }
      
      // Pour un événement de résidence, nous avons besoin de l'objet complet
      final String residenceId = data['residenceId'] as String;
      
      // Dans une implémentation complète, vous récupéreriez la résidence
      // depuis votre service de résidence. Pour l'instant, créons un objet
      // partiel avec les données disponibles
      final residence = Residence(
        id: residenceId,
        name: data['residenceName'] as String,
        description: '',
        address: '',
        price: 0,
        type: '',
        images: [],
        city: '',
        bedrooms: 0,
        bathrooms: 0,
        surface: 0,
        hasPool: false,
        hasWifi: false,
        hasRestaurant: false,
        isVacationResidence: false,
        isSpecialResidence: false,
        isAvailable: true,
        rating: 0,
        reviewCount: 0,
        category: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Créer une notification via Twilio
      final notification = await _twilioService.createResidenceNotification(residence, eventType);
      
      debugPrint('✅ Notification créée pour l\'événement $eventType: ${notification.title}');
    } catch (e) {
      debugPrint('❌ Erreur lors de la création de notification: $e');
    }
  }
}

/// Extensions pour la sérialisation JSON
extension JsonEncoder on NotificationRepository {
  String convert(Map<String, dynamic> json) => json.toString();
}

extension JsonDecoder on NotificationRepository {
  Map<String, dynamic> convert(String json) => {'json': json};
} 