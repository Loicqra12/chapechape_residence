import 'package:flutter/material.dart';
import '../../core/models/chat_model.dart';
import 'chat/message_bubble.dart';

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showAvatar;

  const ChatMessageWidget({
    Key? key,
    required this.message,
    required this.isMe,
    this.showAvatar = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.white),
            ),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: MessageBubble(
              message: message,
              isMe: isMe,
            ),
          ),
          if (isMe) const SizedBox(width: 8),
          if (isMe && showAvatar)
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.person, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
