import 'package:dio/dio.dart';
import '../models/notification_model.dart';
import 'api_service.dart';
import '../utils/logger.dart';

class NotificationService {
  final ApiService _apiService;
  final AppLogger _logger = AppLogger('NotificationService');

  NotificationService._({
    required ApiService apiService,
  }) : _apiService = apiService;

  static Future<NotificationService> initialize() async {
    final apiService = await ApiService.initialize();
    return NotificationService._(apiService: apiService);
  }

  // Récupérer les notifications de l'utilisateur
  Future<List<NotificationModel>> getNotifications({int page = 1, int limit = 10}) async {
    try {
      final response = await _apiService.get(
        '/notifications',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      
      if (response.data['success'] == true && response.data['data'] != null) {
        final List<dynamic> notificationsData = response.data['data'];
        return notificationsData.map((json) => _mapToNotificationModel(json)).toList();
      }
      
      return [];
    } on DioException catch (e) {
      _logger.error('Erreur lors de la récupération des notifications', e);
      rethrow;
    }
  }
  
  // Obtenir le nombre de notifications non lues
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get('/notifications/unread/count');
      if (response.data['success'] == true) {
        return response.data['data']['count'] ?? 0;
      }
      return 0;
    } on DioException catch (e) {
      _logger.error('Erreur lors du comptage des notifications non lues', e);
      return 0;
    }
  }
  
  // Marquer une notification comme lue
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _apiService.put('/notifications/$notificationId/read');
      return response.data['success'] == true;
    } on DioException catch (e) {
      _logger.error('Erreur lors du marquage de la notification', e);
      rethrow;
    }
  }
  
  // Marquer toutes les notifications comme lues
  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiService.put('/notifications/read-all');
      return response.data['success'] == true;
    } on DioException catch (e) {
      _logger.error('Erreur lors du marquage de toutes les notifications', e);
      rethrow;
    }
  }
  
  // Supprimer une notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await _apiService.delete('/notifications/$notificationId');
      return response.data['success'] == true;
    } on DioException catch (e) {
      _logger.error('Erreur lors de la suppression de la notification', e);
      rethrow;
    }
  }
  
  // Convertir les données du backend en modèle NotificationModel
  NotificationModel _mapToNotificationModel(Map<String, dynamic> json) {
    try {
      return NotificationModel(
        id: json['_id'] ?? '',
        title: _getTitleFromType(json['type']),
        message: json['message'] ?? '',
        timestamp: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
        isRead: json['read'] ?? false,
        type: json['type'],
        actionUrl: json['data']?['actionUrl'],
        imageUrl: json['data']?['imageUrl'],
      );
    } catch (e) {
      _logger.error('Erreur lors de la conversion des données de notification', e);
      rethrow;
    }
  }
  
  // Obtenir un titre basé sur le type de notification
  String _getTitleFromType(String? type) {
    switch (type) {
      case 'booking_confirmed':
        return 'Réservation confirmée';
      case 'booking_cancelled':
        return 'Réservation annulée';
      case 'payment_received':
        return 'Paiement reçu';
      case 'favorite_added':
        return 'Nouvelle propriété favorite';
      case 'system_maintenance':
        return 'Maintenance système';
      case 'account_update':
        return 'Mise à jour du compte';
      default:
        return 'Notification';
    }
  }
}