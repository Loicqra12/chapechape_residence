import 'package:dio/dio.dart';
import '../models/notification_model.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _apiService;

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
      print('Erreur lors de la récupération des notifications: ${e.message}');
      return [];
    }
  }
  
  // Marquer une notification comme lue
  Future<bool> markAsRead(String notificationId) async {
    try {
      final response = await _apiService.put('/notifications/$notificationId/read');
      return response.data['success'] == true;
    } on DioException catch (e) {
      print('Erreur lors du marquage de la notification: ${e.message}');
      return false;
    }
  }
  
  // Marquer toutes les notifications comme lues
  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiService.put('/notifications/read-all');
      return response.data['success'] == true;
    } on DioException catch (e) {
      print('Erreur lors du marquage de toutes les notifications: ${e.message}');
      return false;
    }
  }
  
  // Supprimer une notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final response = await _apiService.delete('/notifications/$notificationId');
      return response.data['success'] == true;
    } on DioException catch (e) {
      print('Erreur lors de la suppression de la notification: ${e.message}');
      return false;
    }
  }
  
  // Convertir les données du backend en modèle NotificationModel
  NotificationModel _mapToNotificationModel(Map<String, dynamic> json) {
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