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
    on<FilterNotifications>(_onFilterNotifications);
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (state is NotificationInitial) {
        emit(NotificationLoading());
      }

      final paginatedResponse = await _repository.getNotifications(page: event.page);
      
      // Récupérer le nombre total de notifications non lues depuis l'API
      // Cela évite l'accumulation incorrecte lors de la pagination
      final totalUnread = await _repository.getUnreadCount();

      final hasReachedMax = paginatedResponse.page >= paginatedResponse.pages;

      if (state is NotificationLoaded) {
        final currentState = state as NotificationLoaded;
        if (event.page == 1) {
          emit(NotificationLoaded(
            notifications: paginatedResponse.notifications,
            hasReachedMax: hasReachedMax,
            currentPage: paginatedResponse.page,
            totalUnread: totalUnread,
          ));
        } else {
          emit(NotificationLoaded(
            notifications: [...currentState.notifications, ...paginatedResponse.notifications],
            hasReachedMax: hasReachedMax,
            currentPage: paginatedResponse.page,
            totalUnread: totalUnread,
          ));
        }
      } else {
        emit(NotificationLoaded(
          notifications: paginatedResponse.notifications,
          hasReachedMax: hasReachedMax,
          currentPage: paginatedResponse.page,
          totalUnread: totalUnread,
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
        final currentState = state as NotificationLoaded;
        emit(NotificationActionInProgress());

        final success = await _repository.markAsRead(event.notificationId);

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
        final currentState = state as NotificationLoaded;
        emit(NotificationActionInProgress());

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
        final currentState = state as NotificationLoaded;
        emit(NotificationActionInProgress());

        final success = await _repository.deleteNotification(event.notificationId);

        if (success) {
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
        } else {
          emit(NotificationError('Impossible de supprimer la notification'));
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

  Future<void> _onFilterNotifications(
    FilterNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      if (state is NotificationLoaded) {
        // Récupérer toutes les notifications pour ensuite les filtrer
        final paginatedResponse = await _repository.getNotifications();
        final allNotifications = paginatedResponse.notifications;
        
        // Appliquer les filtres
        final filteredNotifications = allNotifications.where((notification) {
          // Filtre par type
          if (event.type != null && event.type != 'all' && notification.type != event.type) {
            return false;
          }
          
          // Filtre par statut de lecture
          if (event.isRead != null && notification.isRead != event.isRead) {
            return false;
          }
          
          // Filtre par date
          if (event.startDate != null && notification.timestamp.isBefore(event.startDate!)) {
            return false;
          }
          
          if (event.endDate != null) {
            // Ajouter un jour pour inclure toute la journée de fin
            final endDatePlusOne = event.endDate!.add(const Duration(days: 1));
            if (notification.timestamp.isAfter(endDatePlusOne)) {
              return false;
            }
          }
          
          return true;
        }).toList();
        
        // Calculer le nombre de notifications non lues
        final unreadCount = filteredNotifications.where((n) => !n.isRead).length;
        
        emit(NotificationLoaded(
          notifications: filteredNotifications,
          hasReachedMax: true,
          currentPage: 1,
          totalUnread: unreadCount,
          activeFilters: event.type != null || event.isRead != null || event.startDate != null || event.endDate != null,
        ));
      }
    } catch (error) {
      emit(NotificationError(error.toString()));
    }
  }
} 