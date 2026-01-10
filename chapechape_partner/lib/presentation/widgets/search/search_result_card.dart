import 'package:flutter/material.dart';
import '../../../core/models/residence/residence.dart';
import '../../../core/models/reservation/reservation.dart';
import '../../../core/models/message/conversation.dart';
import '../../../core/models/notification/notification_model.dart';
import 'package:intl/intl.dart';

/// Card générique pour afficher un résultat de recherche
class SearchResultCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? trailing;
  final String query;
  final VoidCallback onTap;
  final Widget? image;

  const SearchResultCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.query,
    required this.onTap,
    this.image,
  });

  factory SearchResultCard.residence({
    required Residence residence,
    required String query,
    required VoidCallback onTap,
  }) {
    return SearchResultCard(
      icon: Icons.home,
      iconColor: Colors.blue,
      title: residence.name,
      subtitle: '${residence.city} • ${residence.price} FCFA/nuit',
      trailing: residence.isAvailable ? 'Disponible' : 'Indisponible',
      query: query,
      onTap: onTap,
      image: residence.images.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                residence.images.first.url,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(Icons.home, color: Colors.grey),
                  );
                },
              ),
            )
          : null,
    );
  }

  factory SearchResultCard.reservation({
    required Reservation reservation,
    required String query,
    required VoidCallback onTap,
  }) {
    final checkInDate = DateFormat('dd/MM/yyyy').format(reservation.checkIn);
    return SearchResultCard(
      icon: Icons.calendar_today,
      iconColor: Colors.green,
      title: 'Réservation #${reservation.id.substring(0, 8)}',
      subtitle: 'Check-in: $checkInDate • ${reservation.totalAmount} FCFA',
      trailing: reservation.status.displayName,
      query: query,
      onTap: onTap,
    );
  }

  factory SearchResultCard.conversation({
    required Conversation conversation,
    required String query,
    required VoidCallback onTap,
  }) {
    final participantName = conversation.title ?? 
        (conversation.participants.isNotEmpty ? conversation.participants.first.name : 'Conversation');
    final lastMessageText = conversation.lastMessage?.content ?? 'Aucun message';
    
    return SearchResultCard(
      icon: Icons.message,
      iconColor: Colors.purple,
      title: participantName,
      subtitle: lastMessageText,
      trailing: conversation.unreadCount > 0 ? '${conversation.unreadCount} non lu' : null,
      query: query,
      onTap: onTap,
    );
  }

  factory SearchResultCard.notification({
    required NotificationModel notification,
    required String query,
    required VoidCallback onTap,
  }) {
    return SearchResultCard(
      icon: Icons.notifications,
      iconColor: Colors.orange,
      title: notification.title,
      subtitle: notification.message,
      trailing: notification.isRead ? null : 'Nouveau',
      query: query,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: image ??
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
        title: Text(
          _highlightQuery(title, query),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: trailing != null
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(trailing!).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(trailing!).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  trailing!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(trailing!),
                  ),
                ),
              )
            : const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  String _highlightQuery(String text, String query) {
    // Pour l'instant, on retourne juste le texte
    // En production, on pourrait utiliser RichText pour surligner les correspondances
    return text;
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('actif') || statusLower.contains('confirmé')) {
      return Colors.green;
    } else if (statusLower.contains('en attente') || statusLower.contains('pending')) {
      return Colors.orange;
    } else if (statusLower.contains('annulé') || statusLower.contains('refusé')) {
      return Colors.red;
    } else if (statusLower.contains('nouveau') || statusLower.contains('non lu')) {
      return Colors.blue;
    }
    return Colors.grey;
  }
}

