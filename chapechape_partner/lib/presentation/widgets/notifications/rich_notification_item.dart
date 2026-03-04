import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/notification/notification_model.dart';
import 'package:intl/intl.dart';

/// Widget de notification enrichi avec image et actions rapides
class RichNotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final Function(String action)? onQuickAction;

  const RichNotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDismiss,
    this.onQuickAction,
  });

  IconData _getNotificationIcon(String type) {
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

  Color _getNotificationColor(String type, Color primaryColor) {
    switch (type) {
      case 'booking':
        return primaryColor;
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return DateFormat('dd/MM/yyyy').format(timestamp);
    }
  }

  List<QuickActionButton> _getQuickActions(String type, Color primaryColor) {
    switch (type) {
      case 'booking':
        return [
          QuickActionButton(
            icon: Icons.check_circle,
            label: 'Accepter',
            color: Colors.green,
            action: 'approve',
          ),
          QuickActionButton(
            icon: Icons.visibility,
            label: 'Voir',
            color: primaryColor,
            action: 'view',
          ),
          QuickActionButton(
            icon: Icons.cancel,
            label: 'Refuser',
            color: Colors.red,
            action: 'reject',
          ),
        ];
      case 'payment':
        return [
          QuickActionButton(
            icon: Icons.visibility,
            label: 'Voir',
            color: primaryColor,
            action: 'view',
          ),
          QuickActionButton(
            icon: Icons.receipt_long,
            label: 'Facture',
            color: Colors.green,
            action: 'invoice',
          ),
        ];
      case 'message':
        return [
          QuickActionButton(
            icon: Icons.reply,
            label: 'Répondre',
            color: primaryColor,
            action: 'reply',
          ),
          QuickActionButton(
            icon: Icons.visibility,
            label: 'Voir',
            color: Colors.grey,
            action: 'view',
          ),
        ];
      case 'review':
        return [
          QuickActionButton(
            icon: Icons.reply,
            label: 'Répondre',
            color: primaryColor,
            action: 'reply',
          ),
          QuickActionButton(
            icon: Icons.visibility,
            label: 'Voir',
            color: Colors.grey,
            action: 'view',
          ),
        ];
      default:
        return [
          QuickActionButton(
            icon: Icons.visibility,
            label: 'Voir',
            color: primaryColor,
            action: 'view',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final icon = _getNotificationIcon(notification.type);
    final color = _getNotificationColor(notification.type, primaryColor);
    final quickActions = _getQuickActions(notification.type, primaryColor);
    final hasImage = notification.imageUrl != null && notification.imageUrl!.isNotEmpty;

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
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: notification.isRead ? null : color.withOpacity(0.05),
            border: Border(
              left: BorderSide(
                color: notification.isRead ? Colors.transparent : color,
                width: 3,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec icône, titre et badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icône
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Titre et timestamp
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: !notification.isRead 
                                      ? FontWeight.bold 
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTimestamp(notification.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Message
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: Text(
                  notification.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Image si disponible
              if (hasImage) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 44),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: notification.imageUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                ),
              ],
              
              // Actions rapides
              if (onQuickAction != null && quickActions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 44),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: quickActions.map((action) {
                      return _QuickActionChip(
                        icon: action.icon,
                        label: action.label,
                        color: action.color,
                        onTap: () => onQuickAction!(action.action),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton d'action rapide
class QuickActionButton {
  final IconData icon;
  final String label;
  final Color color;
  final String action;

  QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.action,
  });
}

/// Widget pour un chip d'action rapide
class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


