import 'package:flutter/material.dart';
import '../../../core/models/chat_model.dart';
import '../../../core/utils/date_formatter.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 50 : 8,
          right: isMe ? 8 : 50,
          top: 4,
          bottom: 4,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).primaryColor
              : Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isMe ? 12 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            _buildMessageContent(context),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormatter.formatMessageTime(message.createdAt),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 16,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    // Messages texte
    if (message.type == 'text' || message.type == null) {
      return Text(
        message.content,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black,
          fontSize: 16,
        ),
      );
    }
    
    // Images
    else if (message.type == 'image') {
      if (message.fileUrl == null || message.fileUrl!.isEmpty) {
        return const Text(
          "Erreur: l'URL de l'image est manquante",
          style: TextStyle(
            color: Colors.red,
            fontStyle: FontStyle.italic,
          ),
        );
      }
      
      return GestureDetector(
        onTap: () {
          // Ouvrir l'image en plein écran
          _showFullScreenImage(context, message.fileUrl!);
        },
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.content.isNotEmpty && message.content != message.fileUrl)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                message.fileUrl!,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey.shade300,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(height: 8),
                      Text(
                        "Impossible de charger l'image",
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.black54,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Fichiers
    else if (message.type == 'file') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.attach_file),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                decoration: TextDecoration.underline,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      );
    }
    
    // Type inconnu
    else {
      return Text(
        message.content,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black,
          fontSize: 16,
        ),
      );
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        "Impossible de charger l'image",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
