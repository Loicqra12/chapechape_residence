import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/blocs/notification/notification_bloc.dart';
import '../../core/blocs/notification/notification_state.dart';
import '../../core/blocs/notification/notification_event.dart';
import '../../core/models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

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
        body: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoading) {
              return const Center(child: CircularProgressIndicator());
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
                  context.read<NotificationBloc>().add(const LoadNotifications());
                },
                child: ListView.builder(
                  itemCount: state.notifications.length,
                  itemBuilder: (context, index) {
                    final notification = state.notifications[index];
                    return _buildNotificationItem(context, notification);
                  },
                ),
              );
            } else if (state is NotificationError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur',
                      style: AppTheme.headingMedium.copyWith(color: Colors.red[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: AppTheme.bodyMedium.copyWith(color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<NotificationBloc>().add(const LoadNotifications());
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Notification supprimée')),
        );
      },
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            context.read<NotificationBloc>().add(MarkNotificationAsRead(notification.id));
          }
          // TODO: Naviguer vers l'écran approprié en fonction du type de notification
        },
        child: Container(
          color: backgroundColor,
          child: ListTile(
            leading: _buildNotificationIcon(notification.type),
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(notification.timestamp),
                  style: AppTheme.labelSmall.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            isThreeLine: true,
            trailing: isUnread
                ? Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
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
}
