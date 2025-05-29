import 'package:equatable/equatable.dart';
import '../../models/notification/notification_model.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final bool hasReachedMax;
  final int currentPage;
  final int totalUnread;
  final bool activeFilters;

  const NotificationLoaded({
    required this.notifications,
    required this.hasReachedMax,
    required this.currentPage,
    required this.totalUnread,
    this.activeFilters = false,
  });

  NotificationLoaded copyWith({
    List<NotificationModel>? notifications,
    bool? hasReachedMax,
    int? currentPage,
    int? totalUnread,
    bool? activeFilters,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      totalUnread: totalUnread ?? this.totalUnread,
      activeFilters: activeFilters ?? this.activeFilters,
    );
  }

  @override
  List<Object> get props => [notifications, hasReachedMax, currentPage, totalUnread, activeFilters];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError(this.message);

  @override
  List<Object> get props => [message];
}

class NotificationActionInProgress extends NotificationState {}

class NotificationActionSuccess extends NotificationState {
  final String message;

  const NotificationActionSuccess(this.message);

  @override
  List<Object> get props => [message];
} 