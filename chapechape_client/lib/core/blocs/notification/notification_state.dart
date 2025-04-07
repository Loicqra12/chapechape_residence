import 'package:equatable/equatable.dart';
import '../../models/notification_model.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final bool hasReachedMax;
  final int currentPage;
  final int totalUnread;

  const NotificationLoaded({
    required this.notifications,
    required this.hasReachedMax,
    required this.currentPage,
    required this.totalUnread,
  });

  NotificationLoaded copyWith({
    List<NotificationModel>? notifications,
    bool? hasReachedMax,
    int? currentPage,
    int? totalUnread,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      totalUnread: totalUnread ?? this.totalUnread,
    );
  }

  @override
  List<Object> get props => [notifications, hasReachedMax, currentPage, totalUnread];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object> get props => [message];
}

class NotificationActionInProgress extends NotificationState {
  const NotificationActionInProgress();
}

class NotificationActionSuccess extends NotificationState {
  final String message;

  const NotificationActionSuccess(this.message);

  @override
  List<Object> get props => [message];
}