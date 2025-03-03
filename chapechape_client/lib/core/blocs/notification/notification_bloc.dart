import 'package:flutter_bloc/flutter_bloc.dart';
import 'notification_event.dart';
import 'notification_state.dart';
import '../../models/notification_model.dart';
import '../../repositories/notification_repository.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _notificationRepository;

  NotificationBloc({
    required NotificationRepository notificationRepository,
  })  : _notificationRepository = notificationRepository,
        super(const NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkNotificationAsRead>(_onMarkAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllAsRead);
    on<DeleteNotification>(_onDeleteNotification);
  }

  // Getter pour accéder au repository
  NotificationRepository get notificationRepository => _notificationRepository;

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(const NotificationLoading());
    
    try {
      final notifications = await _notificationRepository.getNotifications(
        page: event.page,
        limit: event.limit,
      );
      
      emit(NotificationLoaded(notifications));
    } catch (e) {
      emit(NotificationError('Erreur lors du chargement des notifications: $e'));
    }
  }

  Future<void> _onMarkAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationLoaded) {
      try {
        final success = await _notificationRepository.markAsRead(event.notificationId);
        
        if (success) {
          final currentNotifications = (state as NotificationLoaded).notifications;
          final updatedNotifications = currentNotifications.map((notification) {
            if (notification.id == event.notificationId) {
              return notification.copyWith(isRead: true);
            }
            return notification;
          }).toList();
          
          emit(NotificationLoaded(updatedNotifications));
        }
      } catch (e) {
        emit(NotificationError('Erreur lors du marquage de la notification: $e'));
      }
    }
  }

  Future<void> _onMarkAllAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationLoaded) {
      try {
        final success = await _notificationRepository.markAllAsRead();
        
        if (success) {
          final currentNotifications = (state as NotificationLoaded).notifications;
          final updatedNotifications = currentNotifications
              .map((notification) => notification.copyWith(isRead: true))
              .toList();
          
          emit(NotificationLoaded(updatedNotifications));
        }
      } catch (e) {
        emit(NotificationError('Erreur lors du marquage de toutes les notifications: $e'));
      }
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationLoaded) {
      try {
        final success = await _notificationRepository.deleteNotification(event.notificationId);
        
        if (success) {
          final currentNotifications = (state as NotificationLoaded).notifications;
          final updatedNotifications = currentNotifications
              .where((notification) => notification.id != event.notificationId)
              .toList();
          
          emit(NotificationLoaded(updatedNotifications));
        }
      } catch (e) {
        emit(NotificationError('Erreur lors de la suppression de la notification: $e'));
      }
    }
  }
}