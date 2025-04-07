import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationResult {
  final List<NotificationModel> notifications;
  final int totalUnread;

  NotificationResult({
    required this.notifications,
    required this.totalUnread,
  });
}

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

  // Récupérer les notifications avec le comptage des non lues
  Future<NotificationResult> getNotifications({int page = 1, int limit = 10}) async {
    final notifications = await _notificationService.getNotifications(page: page, limit: limit);
    final totalUnread = await _notificationService.getUnreadCount();
    
    return NotificationResult(
      notifications: notifications,
      totalUnread: totalUnread,
    );
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
  
  // Obtenir le nombre de notifications non lues
  Future<int> getUnreadCount() async {
    return await _notificationService.getUnreadCount();
  }
}