import 'package:flutter/material.dart';
import '../../core/models/chat_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';
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
      margin: EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.dividerColor,
              child: const Icon(Icons.person, color: AppTheme.textLight),
            ),
          if (!isMe) SizedBox(width: AppSpacing.sm),
          Flexible(
            child: MessageBubble(
              message: message,
              isMe: isMe,
            ),
          ),
          if (isMe) SizedBox(width: AppSpacing.sm),
          if (isMe && showAvatar)
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.person, color: AppTheme.textLight),
            ),
        ],
      ),
    );
  }
}
