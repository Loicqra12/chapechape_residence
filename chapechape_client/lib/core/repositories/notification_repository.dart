import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationRepository {
  final NotificationService _notificationService;

  NotificationRepository._({
    required NotificationService notificationService,
  }) : _notificationService = notificationService;

  static Future<NotificationRepository> initialize() async {
    final notificationService = await NotificationService.initialize();
    return NotificationRepository._(notificationService: notificationService);
  }

  // Getter pour le service
  NotificationService get notificationService => _notificationService;

  // Récupérer les notifications
  Future<List<NotificationModel>> getNotifications({int page = 1, int limit = 10}) async {
    return await _notificationService.getNotifications(page: page, limit: limit);
  }
  
  // Marquer une notification comme lue
  Future<bool> markAsRead(String notificationId) async {
    return await _notificationService.markAsRead(notificationId);
  }
  
  // Marquer toutes les notifications comme lues
  Future<bool> markAllAsRead() async {
    return await _notificationService.markAllAsRead();
  }
  
  // Supprimer une notification
  Future<bool> deleteNotification(String notificationId) async {
    return await _notificationService.deleteNotification(notificationId);
  }
}