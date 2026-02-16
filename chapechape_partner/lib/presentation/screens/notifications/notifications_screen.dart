import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/blocs/notification/notification_bloc.dart';
import '../../../core/blocs/notification/notification_event.dart';
import '../../../core/blocs/notification/notification_state.dart';
import '../../../core/models/notification/notification_model.dart';
import '../../../presentation/widgets/notifications/notification_filter_sheet.dart';
import '../../../presentation/widgets/notifications/grouped_notifications_list.dart';
import '../../widgets/skeletons/skeletons.dart';
import '../../../core/services/error_message_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _groupByType = true; // Toggle pour groupement intelligent

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

  // Affiche la feuille de filtre des notifications
  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const NotificationFilterSheet(),
    );
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
          context.push('/reservations', extra: notification.actionData);
          break;
        case 'payment':
          context.push('/reservations', extra: notification.actionData);
          break;
        case 'message':
          context.push('/messages', extra: notification.actionData);
          break;
        case 'support':
          context.push('/settings', extra: notification.actionData);
          break;
        case 'reminder':
          context.push('/reservations', extra: notification.actionData);
          break;
        default:
          // Si le type n'est pas reconnu, utiliser l'URL directement
          context.push(notification.actionUrl!);
      }
    }
  }

  void _handleQuickAction(NotificationModel notification, String action) {
    // Marquer comme lu si non lu
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(
        MarkNotificationAsRead(notification.id),
      );
    }

    switch (action) {
      case 'approve':
        _handleApprove(notification);
        break;
      case 'reject':
        _handleReject(notification);
        break;
      case 'view':
        _handleNotificationTap(notification);
        break;
      case 'reply':
        _handleReply(notification);
        break;
      case 'invoice':
        _handleInvoice(notification);
        break;
    }
  }

  void _handleApprove(NotificationModel notification) {
    ErrorMessageService.showInfo(
      context,
      'Réservation approuvée avec succès',
    );
    // TODO: Appeler l'API pour approuver la réservation
    context.push('/reservations', extra: notification.actionData);
  }

  void _handleReject(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser la réservation'),
        content: const Text('Êtes-vous sûr de vouloir refuser cette réservation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ErrorMessageService.showInfo(
                context,
                'Réservation refusée',
              );
              // TODO: Appeler l'API pour refuser la réservation
            },
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
  }

  void _handleReply(NotificationModel notification) {
    if (notification.type == 'message') {
      context.push('/messages', extra: notification.actionData);
    } else if (notification.type == 'review') {
      // TODO: Ouvrir un dialogue pour répondre à l'avis
      ErrorMessageService.showInfo(
        context,
        'Fonctionnalité de réponse aux avis en cours de développement',
      );
    }
  }

  void _handleInvoice(NotificationModel notification) {
    ErrorMessageService.showInfo(
      context,
      'Génération de la facture en cours...',
    );
    // TODO: Générer et télécharger la facture
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
              // Bouton pour toggle groupement
              IconButton(
                icon: Icon(
                  _groupByType ? Icons.view_list : Icons.view_module,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  setState(() {
                    _groupByType = !_groupByType;
                  });
                },
                tooltip: _groupByType ? 'Vue liste' : 'Vue groupée',
              ),
              // Bouton de filtre
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: state is NotificationLoaded && state.activeFilters 
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onPressed: () {
                  _showFilterSheet(context);
                },
                tooltip: 'Filtrer les notifications',
              ),
              // Bouton pour tout marquer comme lu
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
      return const NotificationListSkeleton(itemCount: 6);
    }

    if (state is NotificationLoaded) {
      if (state.notifications.isEmpty) {
        return _buildEmptyState();
      }

      return Padding(
        padding: const EdgeInsets.all(16),
        child: GroupedNotificationsList(
          notifications: state.notifications,
          groupByType: _groupByType,
          onNotificationTap: _handleNotificationTap,
          onNotificationDismiss: (notification) {
            context.read<NotificationBloc>().add(
              DeleteNotification(notification.id),
            );
          },
          onQuickAction: _handleQuickAction,
        ),
      );
    }

    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Illustration des notifications
          Image.asset(
            'assets/images/illustrations/empty_notification.png',
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.width * 0.85,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback vers l'icône si l'image ne charge pas
              return Icon(
                Icons.notifications_off,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune notification',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Vous n\'avez pas encore de notifications. Les alertes et mises à jour importantes apparaîtront ici.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
