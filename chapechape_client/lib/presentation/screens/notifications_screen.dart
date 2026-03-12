import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/text_styles.dart';
import '../../core/blocs/notification/notification_bloc.dart';
import '../../core/blocs/notification/notification_state.dart';
import '../../core/blocs/notification/notification_event.dart';
import '../../core/models/notification_model.dart';
import '../widgets/skeletons/notification_item_skeleton.dart';
import 'package:chapechape_client/presentation/widgets/common/empty_state_widget.dart';

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
        body: BlocConsumer<NotificationBloc, NotificationState>(
          listener: (context, state) {
            if (state is NotificationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.errorColor,
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
              return ListView.builder(
                padding: EdgeInsets.all(AppSpacing.sm),
                itemCount: 5,
                itemBuilder: (context, index) => const NotificationItemSkeleton(),
              );
            } else if (state is NotificationActionInProgress) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    AppSpacing.verticalMd,
                    Text('Action en cours...'),
                  ],
                ),
              );
            } else if (state is NotificationLoaded) {
              if (state.notifications.isEmpty) {
                return const EmptyStateWidget(
                  imagePath: 'assets/images/empty_states/empty_notifications_illustration.png',
                  title: 'Aucune notification',
                  subtitle: 'Nous vous tiendrons informé de vos réservations, promotions et nouveautés important',
                );
              }

              final hasUnread = state.notifications.any((n) => !n.isRead);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasUnread)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.done_all, size: 18),
                          label: const Text('Marquer tout comme lu'),
                          onPressed: () {
                            context.read<NotificationBloc>().add(const MarkAllNotificationsAsRead());
                          },
                        ),
                      ),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        HapticFeedback.mediumImpact();
                        context.read<NotificationBloc>().add(const LoadNotifications(isRefresh: true));
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: state.notifications.length + (state.hasReachedMax ? 0 : 1),
                        itemBuilder: (context, index) {
                          if (index == state.notifications.length) {
                            return const Center(
                              child: Padding(
                                padding: AppSpacing.cardPadding,
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final notification = state.notifications[index];
                          return _buildNotificationItem(context, notification);
                        },
                      ),
                    ),
                  ),
                ],
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
        padding: EdgeInsets.only(right: AppSpacing.lg20), // 20px pour espacement spécifique
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
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(notification.type),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
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
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        notification.message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.grey[600],
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
      padding: EdgeInsets.all(AppSpacing.sm),
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
        // 🚫 Paiement masqué pour Google Play – redirection vers réservations
        case 'payment_received':
        case 'payment_failed':
        case 'payment_refunded':
          context.push('/bookings');
          break;
        case 'favorite_added':
        case 'favorite_price_changed':
        case 'favorite_status_changed':
          context.push('/favorites');
          break;
        case 'system_maintenance':
        case 'account_update':
          context.push('/profile/settings');
          break;
        default:
          if (notification.actionUrl != null) {
            context.push(notification.actionUrl!);
          }
      }
    }
  }
}
