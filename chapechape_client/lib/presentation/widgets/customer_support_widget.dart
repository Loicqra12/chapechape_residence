import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/blocs/chat/chat_bloc.dart';
import '../../core/blocs/chat/chat_state.dart';
import '../../core/blocs/chat/chat_event.dart';
import '../../core/models/chat_model.dart';
import '../../core/theme/app_theme.dart';

class CustomerSupportWidget extends StatefulWidget {
  const CustomerSupportWidget({super.key});

  @override
  State<CustomerSupportWidget> createState() => _CustomerSupportWidgetState();
}

class _CustomerSupportWidgetState extends State<CustomerSupportWidget> {
  final TextEditingController _messageController = TextEditingController();
  ChatConversation? _currentConversation;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (state is ChatInitial) {
          context.read<ChatBloc>().add(const LoadConversations());
          return const Center(child: CircularProgressIndicator());
        } else if (state is ChatLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ConversationsLoaded) {
          if (state.conversations.isEmpty) {
            return _buildStartChatButton(context);
          }
          _currentConversation = state.conversations.firstWhere(
            (conv) => !conv.isArchived,
            orElse: () => state.conversations.last,
          );
          return _buildChatInterface(context, _currentConversation!);
        } else if (state is ChatError) {
          return Center(
            child: Text(
              'Erreur: ${state.message}',
              style: AppTheme.errorTextStyle,
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget _buildStartChatButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          context.read<ChatBloc>().add(CreateConversation('agent2'));
        },
        icon: const Icon(Icons.chat),
        label: const Text('Démarrer une conversation'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildChatInterface(BuildContext context, ChatConversation conversation) {
    return Column(
      children: [
        _buildChatHeader(context, conversation),
        Expanded(
          child: _buildChatMessages(context, conversation),
        ),
        _buildChatInput(context, conversation),
      ],
    );
  }

  Widget _buildChatHeader(BuildContext context, ChatConversation conversation) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).primaryColor,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(
              Icons.support_agent,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Support Client',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!conversation.isArchived)
            IconButton(
              onPressed: () {
                context.read<ChatBloc>().add(MarkAllAsRead(
                      conversation.id,
                    ));
              },
              icon: const Icon(
                Icons.close,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatMessages(BuildContext context, ChatConversation conversation) {
    // Ici, nous devrions charger les messages de la conversation
    // Pour l'instant, nous affichons un message fictif
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMessageBubble(
          'Bonjour, comment puis-je vous aider aujourd\'hui?',
          isUser: false,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(String message, {required bool isUser, required DateTime timestamp}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            Text(
              '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput(BuildContext context, ChatConversation conversation) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Tapez votre message...',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {
              if (_messageController.text.trim().isNotEmpty) {
                context.read<ChatBloc>().add(SendMessage(
                      conversationId: conversation.id,
                      content: _messageController.text,
                    ));
                _messageController.clear();
              }
            },
            icon: const Icon(Icons.send),
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }
}
