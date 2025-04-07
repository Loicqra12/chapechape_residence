import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/notification/notification_bloc.dart';
import '../../../core/blocs/notification/notification_event.dart';
import '../../../core/blocs/notification/notification_state.dart';
import '../../../core/models/notification/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Charger les notifications au démarrage
    context.read<NotificationBloc>().add(const LoadNotifications());

    // Configurer le scroll pour la pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      final state = context.read<NotificationBloc>().state;
      if (state is NotificationLoaded && !state.hasReachedMax) {
        context.read<NotificationBloc>().add(
          LoadNotifications(page: state.currentPage + 1),
        );
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _handleNotificationTap(NotificationModel notification) {
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(
        MarkNotificationAsRead(notification.id),
      );
    }

    if (notification.actionUrl != null) {
      // Naviguer selon le type de notification
      switch (notification.type) {
        case 'booking':
          Navigator.of(context).pushNamed(
            '/bookings/details',
            arguments: notification.actionData,
          );
          break;
        case 'payment':
          Navigator.of(context).pushNamed(
            '/payments',
            arguments: notification.actionData,
          );
          break;
        case 'support':
          Navigator.of(context).pushNamed(
            '/support',
            arguments: notification.actionData,
          );
          break;
        case 'reminder':
          Navigator.of(context).pushNamed(
            '/calendar',
            arguments: notification.actionData,
          );
          break;
        default:
          // Si le type n'est pas reconnu, utiliser l'URL directement
          Navigator.of(context).pushNamed(notification.actionUrl!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state is NotificationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
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
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            actions: [
              if (state is NotificationLoaded && state.totalUnread > 0)
                TextButton(
                  onPressed: () {
                    context.read<NotificationBloc>().add(MarkAllNotificationsAsRead());
                  },
                  child: const Text('Tout marquer comme lu'),
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<NotificationBloc>().add(RefreshNotifications());
            },
            child: _buildBody(context, state, theme),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, NotificationState state, ThemeData theme) {
    if (state is NotificationLoading && state is! NotificationLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is NotificationLoaded) {
      if (state.notifications.isEmpty) {
        return _buildEmptyState();
      }

      return ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Column(
              children: [
                ...state.notifications.map((notification) {
                  return Column(
                    children: [
                      _NotificationItem(
                        notification: notification,
                        onTap: () => _handleNotificationTap(notification),
                        onDismiss: () {
                          context.read<NotificationBloc>().add(
                            DeleteNotification(notification.id),
                          );
                        },
                      ),
                      if (notification != state.notifications.last)
                        const Divider(height: 1),
                    ],
                  );
                }).toList(),

                if (!state.hasReachedMax && state is! NotificationLoading)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Aucune notification',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} heures';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'booking':
        return Icons.home;
      case 'payment':
        return Icons.payment;
      case 'support':
        return Icons.support_agent;
      case 'reminder':
        return Icons.calendar_today;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'booking':
        return Colors.blue;
      case 'payment':
        return Colors.green;
      case 'support':
        return Colors.orange;
      case 'reminder':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _getNotificationIcon(notification.type);
    final color = _getNotificationColor(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: !notification.isRead ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
