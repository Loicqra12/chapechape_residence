import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/message/message_thread.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';
import 'package:intl/intl.dart';

class MessageThreadCard extends StatelessWidget {
  final MessageThread thread;
  final VoidCallback onTap;
  final bool isOnline;

  const MessageThreadCard({
    super.key,
    required this.thread,
    required this.onTap,
    this.isOnline = false,
  });

  String _formatLastMessage(String? content, List<dynamic>? attachments) {
    if (content?.isNotEmpty ?? false) return content!;
    if (attachments?.isNotEmpty ?? false) {
      final count = attachments!.length;
      if (count == 1) return '📎 Pièce jointe';
      return '📎 $count pièces jointes';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = thread.unreadCount > 0;
    final lastMessage = thread.messages.isNotEmpty ? thread.messages.last : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: thread.clientAvatar != null
                        ? CachedNetworkImageProvider(thread.clientAvatar!)
                        : null,
                    child: thread.clientAvatar == null
                        ? Text(
                            thread.clientName.characters.first.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          )
                        : null,
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            thread.clientName,
                            style: AppTextStyles.regularBold.copyWith(
                              color: hasUnread
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(thread.lastMessageTime),
                          style: AppTextStyles.tiny.copyWith(
                            color: hasUnread
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (thread.residenceName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        thread.residenceName!,
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _formatLastMessage(
                              lastMessage?.content,
                              lastMessage?.attachments,
                            ),
                            style: AppTextStyles.small.copyWith(
                              color: hasUnread
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight:
                                  hasUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              thread.unreadCount.toString(),
                              style: AppTextStyles.tiny.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes}min';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays < 2) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(time);
    } else {
      return DateFormat('dd/MM').format(time);
    }
  }
}

class MessageThreadCardSkeleton extends StatelessWidget {
  const MessageThreadCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 40,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 12,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
