import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;
  
  NotificationBloc({
    required NotificationRepository repository,
  })  : _repository = repository,
        super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkNotificationAsRead>(_onMarkAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<RefreshNotifications>(_onRefreshNotifications);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (state is NotificationInitial) {
        emit(NotificationLoading());
      }

      final notifications = await _repository.getNotifications();

      final unreadCount = notifications.where((n) => !n.isRead).length;
      final hasReachedMax = true;

      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        if (event.page == 1) {
          emit(NotificationLoaded(
            notifications: notifications,
            hasReachedMax: hasReachedMax,
            currentPage: event.page,
            totalUnread: unreadCount,
          ));
        } else {
          emit(NotificationLoaded(
            notifications: [...currentState.notifications, ...notifications],
            hasReachedMax: hasReachedMax,
            currentPage: event.page,
            totalUnread: currentState.totalUnread + unreadCount,
          ));
        }
      } else {
        emit(NotificationLoaded(
          notifications: notifications,
          hasReachedMax: hasReachedMax,
          currentPage: event.page,
          totalUnread: unreadCount,
        ));
      }
    } catch (error) {
      emit(NotificationError(error.toString()));
    }
  }

  Future<void> _onMarkAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (state is NotificationLoaded) {
        emit(NotificationActionInProgress());
        
        final success = await _repository.markAsRead(event.notificationId);
        
        if (success) {
          final currentState = state as NotificationLoaded;
          final updatedNotifications = currentState.notifications.map((notification) {
            if (notification.id == event.notificationId) {
              return notification.copyWith(isRead: true);
            }
            return notification;
          }).toList();

          emit(NotificationLoaded(
            notifications: updatedNotifications,
            hasReachedMax: currentState.hasReachedMax,
            currentPage: currentState.currentPage,
            totalUnread: currentState.totalUnread - 1,
          ));

          emit(const NotificationActionSuccess('Notification marquée comme lue'));
        }
      }
    } catch (error) {
      emit(NotificationError(error.toString()));
    }
  }

  Future<void> _onMarkAllAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (state is NotificationLoaded) {
        emit(NotificationActionInProgress());
        
        final currentState = state as NotificationLoaded;
        for (final notification in currentState.notifications.where((n) => !n.isRead)) {
          await _repository.markAsRead(notification.id);
        }
        
        final updatedNotifications = currentState.notifications
            .map((notification) => notification.copyWith(isRead: true))
            .toList();

        emit(NotificationLoaded(
          notifications: updatedNotifications,
          hasReachedMax: currentState.hasReachedMax,
          currentPage: currentState.currentPage,
          totalUnread: 0,
        ));

        emit(const NotificationActionSuccess('Toutes les notifications ont été marquées comme lues'));
      }
    } catch (error) {
      emit(NotificationError(error.toString()));
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (state is NotificationLoaded) {
        emit(NotificationActionInProgress());
        
        final success = true;
        
        if (success) {
          final currentState = state as NotificationLoaded;
          final deletedNotification = currentState.notifications
              .firstWhere((n) => n.id == event.notificationId);
          final wasUnread = !deletedNotification.isRead;
          
          final updatedNotifications = currentState.notifications
              .where((n) => n.id != event.notificationId)
              .toList();

          emit(NotificationLoaded(
            notifications: updatedNotifications,
            hasReachedMax: currentState.hasReachedMax,
            currentPage: currentState.currentPage,
            totalUnread: wasUnread ? currentState.totalUnread - 1 : currentState.totalUnread,
          ));

          emit(const NotificationActionSuccess('Notification supprimée'));
        }
      }
    } catch (error) {
      emit(NotificationError(error.toString()));
    }
  }

  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    add(const LoadNotifications(page: 1));
  }
} 