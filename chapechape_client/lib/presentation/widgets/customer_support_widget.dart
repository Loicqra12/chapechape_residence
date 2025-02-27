import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/blocs/chat/chat_bloc.dart';
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
        return state.maybeWhen(
          initial: () {
            context.read<ChatBloc>().add(const ChatEvent.started());
            return const Center(child: CircularProgressIndicator());
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          loaded: (conversations) {
            if (conversations.isEmpty) {
              return _buildStartChatButton(context);
            }
            _currentConversation = conversations.firstWhere(
              (conv) => !conv.isResolved,
              orElse: () => conversations.last,
            );
            return _buildChatInterface(context, _currentConversation!);
          },
          error: (message) => Center(
            child: Text(
              'Erreur: $message',
              style: AppTheme.errorTextStyle,
            ),
          ),
          orElse: () => const SizedBox(),
        );
      },
    );
  }

  Widget _buildStartChatButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          context.read<ChatBloc>().add(const ChatEvent.startConversation());
        },
        icon: const Icon(Icons.chat),
        label: const Text('Démarrer une conversation'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildChatInterface(
    BuildContext context,
    ChatConversation conversation,
  ) {
    return Column(
      children: [
        _buildChatHeader(context, conversation),
        Expanded(
          child: _buildMessagesList(conversation),
        ),
        if (!conversation.isResolved) _buildMessageInput(context, conversation),
      ],
    );
  }

  Widget _buildChatHeader(
    BuildContext context,
    ChatConversation conversation,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.support_agent,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Support Client',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!conversation.isResolved)
            IconButton(
              onPressed: () {
                context.read<ChatBloc>().add(
                  ChatEvent.endConversation(
                    conversationId: conversation.id,
                  ),
                );
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

  Widget _buildMessagesList(ChatConversation conversation) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conversation.messages.length,
      itemBuilder: (context, index) {
        final message = conversation.messages[index];
        final isUserMessage = message.senderId == 'user_id'; // TODO: Get from auth

        return Align(
          alignment: isUserMessage
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isUserMessage
                  ? Theme.of(context).primaryColor
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: isUserMessage ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput(
    BuildContext context,
    ChatConversation conversation,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Écrivez votre message...',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () {
              if (_messageController.text.trim().isNotEmpty) {
                context.read<ChatBloc>().add(
                  ChatEvent.sendMessage(
                    conversationId: conversation.id,
                    content: _messageController.text.trim(),
                  ),
                );
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
