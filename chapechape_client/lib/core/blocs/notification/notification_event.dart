import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object> get props => [];
}

class LoadNotifications extends NotificationEvent {
  final int page;
  final int limit;
  final bool isRefresh;

  const LoadNotifications({
    this.page = 1,
    this.limit = 10,
    this.isRefresh = false,
  });
  
  @override
  List<Object> get props => [page, limit, isRefresh];
}

class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;

  const MarkNotificationAsRead(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

class MarkAllNotificationsAsRead extends NotificationEvent {
  const MarkAllNotificationsAsRead();
}

class DeleteNotification extends NotificationEvent {
  final String notificationId;

  const DeleteNotification(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

class RefreshNotifications extends NotificationEvent {
  const RefreshNotifications();
}

class ClearNotificationError extends NotificationEvent {
  const ClearNotificationError();
}