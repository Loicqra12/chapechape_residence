import 'package:flutter/material.dart';
import '../../../core/models/chat_model.dart';
import '../../../core/utils/date_formatter.dart';

class ConversationItem extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;

  const ConversationItem({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  String _getLastMessagePreview(ChatMessage message) {
    switch (message.type) {
      case 'image':
        return '📷 Image';
      case 'file':
        return '📎 ${message.content}';
      default:
        return message.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastMessage = conversation.messages.isNotEmpty ? conversation.messages.last : null;
    final unreadCount = conversation.messages.where((m) => !m.isRead).length;
    final otherParticipant = conversation.participants.length > 1 ? 
        conversation.participants.firstWhere(
          (p) => p.role != 'admin',
          orElse: () => conversation.participants[0],
        ) : conversation.participants[0];

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        backgroundImage: otherParticipant.avatarUrl != null ? 
            NetworkImage(otherParticipant.avatarUrl!) : null,
        child: otherParticipant.avatarUrl == null ? Text(
          otherParticipant.name.isNotEmpty ? otherParticipant.name[0].toUpperCase() : 'A',
          style: const TextStyle(color: Colors.white),
        ) : null,
      ),
      title: Text(
        otherParticipant.name,
        style: TextStyle(
          fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lastMessage != null)
            Text(
              _getLastMessagePreview(lastMessage),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unreadCount > 0 ? Colors.black87 : Colors.black54,
              ),
            ),
          if (conversation.residenceId != null || conversation.reservationId != null)
            Text(
              conversation.reservationId != null ? '🏠 Réservation associée' : '🏠 Résidence associée',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).primaryColor,
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (lastMessage != null)
            Text(
              DateFormatter.formatMessageTime(lastMessage.createdAt),
              style: TextStyle(
                color: unreadCount > 0
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
                fontSize: 12,
              ),
            ),
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
