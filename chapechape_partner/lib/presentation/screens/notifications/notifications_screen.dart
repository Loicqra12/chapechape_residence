import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Marquer toutes les notifications comme lues
            },
            child: const Text('Tout marquer comme lu'),
          ),
        ],
      ),
      body: ListView(
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
                _NotificationItem(
                  title: 'Nouvelle réservation',
                  message: 'Vous avez reçu une nouvelle réservation pour la Résidence Bellevue',
                  time: 'Il y a 5 minutes',
                  isUnread: true,
                  icon: Icons.home,
                  color: theme.colorScheme.primary,
                ),
                const Divider(height: 1),
                _NotificationItem(
                  title: 'Paiement reçu',
                  message: 'Le paiement de 500€ a été reçu pour la réservation #1234',
                  time: 'Il y a 2 heures',
                  isUnread: true,
                  icon: Icons.payment,
                  color: Colors.green,
                ),
                const Divider(height: 1),
                _NotificationItem(
                  title: 'Message du support',
                  message: 'Le support a répondu à votre demande',
                  time: 'Hier',
                  isUnread: false,
                  icon: Icons.support_agent,
                  color: Colors.blue,
                ),
                const Divider(height: 1),
                _NotificationItem(
                  title: 'Rappel',
                  message: 'N\'oubliez pas de mettre à jour vos disponibilités',
                  time: 'Il y a 2 jours',
                  isUnread: false,
                  icon: Icons.calendar_today,
                  color: Colors.orange,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off, size: 64),
                SizedBox(height: 16),
                Text('Aucune notification'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final bool isUnread;
  final IconData icon;
  final Color color;

  const _NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.isUnread,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
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
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isUnread)
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
          Text(message),
          const SizedBox(height: 4),
          Text(
            time,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
      onTap: () {
        // TODO: Ouvrir la notification
      },
    );
  }
}
