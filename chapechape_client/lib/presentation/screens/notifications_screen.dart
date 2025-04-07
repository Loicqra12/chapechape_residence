import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/blocs/notification/notification_bloc.dart';
import '../../core/blocs/notification/notification_state.dart';
import '../../core/blocs/notification/notification_event.dart';
import '../../core/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      final state = context.read<NotificationBloc>().state;
      if (state is NotificationLoaded && !state.hasReachedMax) {
        context.read<NotificationBloc>().add(LoadNotifications(page: state.currentPage + 1));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationRepository = context.read<NotificationBloc>().notificationRepository;
    
    return BlocProvider(
      create: (context) => NotificationBloc(
        notificationRepository: notificationRepository,
      )..add(const LoadNotifications()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                if (state is NotificationLoaded && state.notifications.isNotEmpty) {
                  return IconButton(
                    icon: const Icon(Icons.done_all),
                    tooltip: 'Marquer tout comme lu',
                    onPressed: () {
                      context.read<NotificationBloc>().add(const MarkAllNotificationsAsRead());
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocConsumer<NotificationBloc, NotificationState>(
          listener: (context, state) {
            if (state is NotificationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: 'Réessayer',
                    onPressed: () {
                      context.read<NotificationBloc>().add(const LoadNotifications());
                    },
                  ),
                ),
              );
            } else if (state is NotificationActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is NotificationLoading && state is! NotificationLoaded) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is NotificationActionInProgress) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Action en cours...'),
                  ],
                ),
              );
            } else if (state is NotificationLoaded) {
              if (state.notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune notification',
                        style: AppTheme.headingMedium.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vous n\'avez pas encore de notifications',
                        style: AppTheme.bodyMedium.copyWith(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<NotificationBloc>().add(const LoadNotifications(isRefresh: true));
                },
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: state.notifications.length + (state.hasReachedMax ? 0 : 1),
                  itemBuilder: (context, index) {
                    if (index == state.notifications.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final notification = state.notifications[index];
                    return _buildNotificationItem(context, notification);
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, NotificationModel notification) {
    final bool isUnread = !notification.isRead;
    final Color backgroundColor = isUnread ? Colors.blue.withOpacity(0.05) : Colors.transparent;
    
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        context.read<NotificationBloc>().add(DeleteNotification(notification.id));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: backgroundColor,
        child: InkWell(
          onTap: () {
            if (!notification.isRead) {
              context.read<NotificationBloc>().add(MarkNotificationAsRead(notification.id));
            }
            _handleNotificationNavigation(context, notification);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(notification.type),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String? type) {
    IconData iconData;
    Color iconColor;
    
    switch (type) {
      case 'booking_confirmed':
      case 'booking_cancelled':
      case 'booking_reminder':
        iconData = Icons.calendar_today;
        iconColor = Colors.green;
        break;
      case 'payment_received':
      case 'payment_failed':
      case 'payment_refunded':
        iconData = Icons.payment;
        iconColor = Colors.purple;
        break;
      case 'favorite_added':
      case 'favorite_price_changed':
      case 'favorite_status_changed':
        iconData = Icons.favorite;
        iconColor = Colors.red;
        break;
      case 'system_maintenance':
      case 'account_update':
        iconData = Icons.settings;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.blue;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: iconColor),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  void _handleNotificationNavigation(BuildContext context, NotificationModel notification) {
    if (notification.actionUrl != null) {
      switch (notification.type) {
        case 'booking_confirmed':
        case 'booking_cancelled':
        case 'booking_reminder':
          context.push('/bookings');
          break;
        case 'payment_received':
        case 'payment_failed':
        case 'payment_refunded':
          context.push('/payments');
          break;
        case 'favorite_added':
        case 'favorite_price_changed':
        case 'favorite_status_changed':
          context.push('/favorites');
          break;
        case 'system_maintenance':
        case 'account_update':
          context.push('/settings');
          break;
        default:
          if (notification.actionUrl != null) {
            context.push(notification.actionUrl!);
          }
      }
    }
  }
}
