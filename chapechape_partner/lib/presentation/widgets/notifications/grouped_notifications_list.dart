import 'package:flutter/material.dart';
import '../../../core/models/notification/notification_model.dart';
import 'rich_notification_item.dart';

/// Widget pour afficher les notifications groupées par catégorie
class GroupedNotificationsList extends StatelessWidget {
  final List<NotificationModel> notifications;
  final Function(NotificationModel) onNotificationTap;
  final Function(NotificationModel) onNotificationDismiss;
  final Function(NotificationModel, String)? onQuickAction;
  final bool groupByType;

  const GroupedNotificationsList({
    super.key,
    required this.notifications,
    required this.onNotificationTap,
    required this.onNotificationDismiss,
    this.onQuickAction,
    this.groupByType = true,
  });

  Map<String, List<NotificationModel>> _groupNotifications() {
    if (!groupByType) {
      return {'all': notifications};
    }

    final Map<String, List<NotificationModel>> grouped = {};

    for (var notification in notifications) {
      if (!grouped.containsKey(notification.type)) {
        grouped[notification.type] = [];
      }
      grouped[notification.type]!.add(notification);
    }

    // Trier par nombre de notifications (plus nombreux en premier)
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => grouped[b]!.length.compareTo(grouped[a]!.length));

    final sortedGrouped = <String, List<NotificationModel>>{};
    for (var key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
  }

  String _getGroupTitle(String type) {
    switch (type) {
      case 'booking':
        return 'Réservations';
      case 'payment':
        return 'Paiements';
      case 'message':
        return 'Messages';
      case 'reminder':
        return 'Rappels';
      case 'support':
        return 'Support';
      case 'review':
        return 'Avis';
      case 'alert':
        return 'Alertes';
      case 'all':
        return 'Toutes';
      default:
        return 'Autres';
    }
  }

  IconData _getGroupIcon(String type) {
    switch (type) {
      case 'booking':
        return Icons.calendar_today;
      case 'payment':
        return Icons.payments;
      case 'message':
        return Icons.message;
      case 'reminder':
        return Icons.alarm;
      case 'support':
        return Icons.support_agent;
      case 'review':
        return Icons.star;
      case 'alert':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  Color _getGroupColor(String type) {
    switch (type) {
      case 'booking':
        return Colors.blue;
      case 'payment':
        return Colors.green;
      case 'message':
        return Colors.purple;
      case 'reminder':
        return Colors.orange;
      case 'support':
        return Colors.teal;
      case 'review':
        return Colors.amber;
      case 'alert':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupedNotifications = _groupNotifications();

    if (!groupByType) {
      // Affichage simple sans groupement
      return ListView.separated(
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return RichNotificationItem(
            notification: notification,
            onTap: () => onNotificationTap(notification),
            onDismiss: () => onNotificationDismiss(notification),
            onQuickAction: onQuickAction != null
                ? (action) => onQuickAction!(notification, action)
                : null,
          );
        },
      );
    }

    // Affichage groupé
    return ListView.builder(
      itemCount: groupedNotifications.length,
      itemBuilder: (context, groupIndex) {
        final groupType = groupedNotifications.keys.elementAt(groupIndex);
        final groupNotifications = groupedNotifications[groupType]!;
        final groupTitle = _getGroupTitle(groupType);
        final groupIcon = _getGroupIcon(groupType);
        final groupColor = _getGroupColor(groupType);
        final unreadCount = groupNotifications.where((n) => !n.isRead).length;

        return _NotificationGroup(
          title: groupTitle,
          icon: groupIcon,
          color: groupColor,
          notificationCount: groupNotifications.length,
          unreadCount: unreadCount,
          child: Column(
            children: [
              for (int i = 0; i < groupNotifications.length; i++) ...[
                RichNotificationItem(
                  notification: groupNotifications[i],
                  onTap: () => onNotificationTap(groupNotifications[i]),
                  onDismiss: () => onNotificationDismiss(groupNotifications[i]),
                  onQuickAction: onQuickAction != null
                      ? (action) => onQuickAction!(groupNotifications[i], action)
                      : null,
                ),
                if (i < groupNotifications.length - 1)
                  const Divider(height: 1),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Widget pour un groupe de notifications
class _NotificationGroup extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int notificationCount;
  final int unreadCount;
  final Widget child;

  const _NotificationGroup({
    required this.title,
    required this.icon,
    required this.color,
    required this.notificationCount,
    required this.unreadCount,
    required this.child,
  });

  @override
  State<_NotificationGroup> createState() => _NotificationGroupState();
}

class _NotificationGroupState extends State<_NotificationGroup> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          // En-tête du groupe (cliquable pour expand/collapse)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.05),
                borderRadius: _isExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Icône du groupe
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Titre et compteur
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.notificationCount} notification${widget.notificationCount > 1 ? 's' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Badge non lu
                  if (widget.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  
                  const SizedBox(width: 8),
                  
                  // Icône expand/collapse
                  Icon(
                    _isExpanded 
                        ? Icons.keyboard_arrow_up 
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
          
          // Contenu du groupe (notifications)
          if (_isExpanded) widget.child,
        ],
      ),
    );
  }
}


