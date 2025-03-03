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

  @override
  Widget build(BuildContext context) {
    final lastMessage = conversation.messages.isNotEmpty ? conversation.messages.last : null;
    final unreadCount = conversation.messages.where((m) => !m.isRead).length;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        child: Text(
          conversation.participants.isNotEmpty && conversation.participants[1].name.isNotEmpty 
              ? conversation.participants[1].name[0].toUpperCase() 
              : 'A',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        conversation.participants.isNotEmpty && conversation.participants.length > 1
            ? conversation.participants[1].name
            : 'Agent',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: lastMessage != null
          ? Text(
              lastMessage.content ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (lastMessage != null)
            Text(
              DateFormatter.formatMessageTime(lastMessage.timestamp),
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
