import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/models/message/message.dart';
import '../../../core/theme/colors.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
  }) : super(key: key);

  Widget _buildAttachmentPreview(MessageAttachment attachment) {
    switch (attachment.type) {
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: attachment.url,
            placeholder: (context, url) =>
                const CircularProgressIndicator(),
            errorWidget: (context, url, error) =>
                const Icon(Icons.error),
            fit: BoxFit.cover,
            width: 200,
            height: 150,
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.attach_file),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.name ?? 'Fichier',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${(attachment.size / 1024).toStringAsFixed(1)} KB',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildStatusIndicator() {
    if (!isMe) return const SizedBox.shrink();
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          message.read ? Icons.done_all : Icons.done,
          size: 14,
          color: message.read ? AppColors.primary : Colors.grey[400],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? AppColors.primary : Colors.grey[300];
    final textColor = isMe ? Colors.white : Colors.black;
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleMargin = isMe
        ? const EdgeInsets.only(left: 48, right: 8, top: 8, bottom: 8)
        : const EdgeInsets.only(left: 8, right: 48, top: 8, bottom: 8);

    return Padding(
      padding: bubbleMargin,
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          if (!isMe) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.senderAvatar != null)
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: CachedNetworkImageProvider(message.senderAvatar!),
                  ),
                const SizedBox(width: 4),
                Text(
                  message.senderName,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          Container(
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.content.isNotEmpty)
                  Text(
                    message.content,
                    style: TextStyle(color: textColor),
                  ),
                if (message.attachments.isNotEmpty) ...[
                  if (message.content.isNotEmpty)
                    const SizedBox(height: 8),
                  ...message.attachments.map(_buildAttachmentPreview),
                ],
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(message.timestamp),
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 10,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      _buildStatusIndicator(),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
