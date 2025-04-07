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
    on<RefreshNotifications>(_onRefreshNotifications);
    on<ClearNotificationError>(_onClearError);
  }

  // Getter pour accéder au repository
  NotificationRepository get notificationRepository => _notificationRepository;

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (event.isRefresh) {
        emit(const NotificationLoading());
      }

      final currentState = state;
      if (currentState is NotificationLoaded && !event.isRefresh) {
        if (currentState.hasReachedMax) return;
      }

      final result = await _notificationRepository.getNotifications(
        page: event.page,
        limit: event.limit,
      );

      final notifications = result.notifications;
      final totalUnread = result.totalUnread;
      final hasReachedMax = notifications.length < event.limit;

      if (currentState is NotificationLoaded && !event.isRefresh) {
        final updatedNotifications = [...currentState.notifications, ...notifications];
        emit(NotificationLoaded(
          notifications: updatedNotifications,
          hasReachedMax: hasReachedMax,
          currentPage: event.page,
          totalUnread: totalUnread,
        ));
      } else {
        emit(NotificationLoaded(
          notifications: notifications,
          hasReachedMax: hasReachedMax,
          currentPage: 1,
          totalUnread: totalUnread,
        ));
      }
    } catch (e) {
      emit(NotificationError('Erreur lors du chargement des notifications: $e'));
    }
  }

  Future<void> _onMarkAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationLoaded) {
      final currentState = state as NotificationLoaded;
      emit(const NotificationActionInProgress());
      
      try {
        final success = await _notificationRepository.markAsRead(event.notificationId);
        
        if (success) {
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
      final currentState = state as NotificationLoaded;
      emit(const NotificationActionInProgress());
      
      try {
        final success = await _notificationRepository.markAllAsRead();
        
        if (success) {
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
      final currentState = state as NotificationLoaded;
      emit(const NotificationActionInProgress());
      
      try {
        final success = await _notificationRepository.deleteNotification(event.notificationId);
        
        if (success) {
          final updatedNotifications = currentState.notifications
              .where((notification) => notification.id != event.notificationId)
              .toList();
          
          final wasUnread = currentState.notifications
              .firstWhere((n) => n.id == event.notificationId)
              .isRead == false;
          
          emit(NotificationLoaded(
            notifications: updatedNotifications,
            hasReachedMax: currentState.hasReachedMax,
            currentPage: currentState.currentPage,
            totalUnread: wasUnread ? currentState.totalUnread - 1 : currentState.totalUnread,
          ));
          emit(const NotificationActionSuccess('Notification supprimée'));
        }
      } catch (e) {
        emit(NotificationError('Erreur lors de la suppression de la notification: $e'));
      }
    }
  }

  Future<void> _onRefreshNotifications(
    RefreshNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    add(const LoadNotifications(page: 1, isRefresh: true));
  }

  void _onClearError(
    ClearNotificationError event,
    Emitter<NotificationState> emit,
  ) {
    if (state is NotificationError) {
      add(const LoadNotifications());
    }
  }
}