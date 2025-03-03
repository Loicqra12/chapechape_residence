import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/chat/chat_bloc.dart';
import '../../core/blocs/chat/chat_event.dart';
import '../../core/blocs/chat/chat_state.dart';
import '../../core/models/chat_model.dart';
import '../../core/utils/date_formatter.dart';

class ChatConversationScreen extends StatefulWidget {
  final String conversationId;

  const ChatConversationScreen({
    Key? key,
    required this.conversationId,
  }) : super(key: key);

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatBloc _chatBloc;

  static const Color goldColor = Color(0xFFFFD700);
  static const Color darkGold = Color(0xFFCCAC00);
  static const Color blackColor = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _chatBloc = BlocProvider.of<ChatBloc>(context);
    _chatBloc.add(MarkMessageAsRead(widget.conversationId));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is MessagesLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: goldColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.go('/chat');
              },
            ),
            title: Builder(
              builder: (context) {
                if (state is MessagesLoaded) {
                  final otherParticipant = state.conversations
                      .firstWhere((c) => c.id == widget.conversationId)
                      .participants
                      .firstWhere(
                        (p) => p.id != 'user1',
                        orElse: () => ChatParticipant(id: 'unknown', name: 'Inconnu'),
                      );
                  return Text(otherParticipant.name);
                }
                return const Text('Conversation');
              },
            ),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'archive') {
                    _chatBloc.add(MarkAllAsRead(widget.conversationId));
                    context.go('/chat');
                  } else if (value == 'delete') {
                    _showDeleteConfirmationDialog();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem<String>(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(Icons.archive),
                        SizedBox(width: 8),
                        Text('Archiver'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(ChatState state) {
    if (state is ChatLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (state is MessagesLoaded) {
      return Column(
        children: [
          Expanded(
            child: _buildMessagesList(state.messages),
          ),
          _buildMessageInput(),
        ],
      );
    } else if (state is ChatError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                state.message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _chatBloc.add(LoadMessages(widget.conversationId));
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    } else {
      return const Center(
        child: Text('Chargement de la conversation...'),
      );
    }
  }

  Widget _buildMessagesList(List<ChatMessage> messages) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun message',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Commencez la conversation en envoyant un message',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isUserMessage = message.senderId == 'user1';
        final showAvatar = index == 0 || messages[index - 1].senderId != message.senderId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment:
                isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUserMessage && showAvatar)
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.person, size: 20, color: Colors.white),
                )
              else if (!isUserMessage)
                const SizedBox(width: 32),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isUserMessage ? goldColor : Colors.grey[200],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content ?? '',
                        style: TextStyle(
                          color: isUserMessage ? blackColor : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormatter.formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isUserMessage
                              ? blackColor.withOpacity(0.6)
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isUserMessage && showAvatar)
                CircleAvatar(
                  radius: 16,
                  backgroundColor: goldColor,
                  child: const Icon(Icons.person, size: 20, color: Colors.white),
                )
              else if (isUserMessage)
                const SizedBox(width: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // Fonctionnalité de pièce jointe à implémenter
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Tapez votre message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 5,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: darkGold),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      _chatBloc.add(SendMessage(
        conversationId: widget.conversationId,
        content: message,
      ));
      _messageController.clear();
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer la conversation'),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer cette conversation ? Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.pop();
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                context.pop(); // Fermer la boîte de dialogue
                _chatBloc.add(MarkAllAsRead(widget.conversationId));
                context.go('/chat'); // Retourner à l'écran de chat
              },
              child: const Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
