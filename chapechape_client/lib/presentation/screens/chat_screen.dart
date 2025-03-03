import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/blocs/chat/chat_bloc.dart';
import '../../core/blocs/chat/chat_event.dart';
import '../../core/blocs/chat/chat_state.dart';
import '../../core/models/chat_model.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

  static const Color goldColor = Color(0xFFFFD700);
  static const Color darkGold = Color(0xFFCCAC00);
  static const Color orangeColor = Color(0xFFFF8C00);
  static const Color blackColor = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final chatService = context.read<ChatBloc>().chatService;
    
    return BlocProvider(
      create: (context) => ChatBloc(
        chatService: chatService,
      )..add(const LoadConversations()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: ChatScreen.goldColor,
        ),
        body: BlocConsumer<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state is MessagesLoaded) {
              // Faire défiler vers le bas lorsque de nouveaux messages sont chargés
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom(context);
              });
            }
          },
          builder: (context, state) {
            if (state is ChatLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ConversationsLoaded) {
              return _buildConversationsList(context, state.conversations);
            } else if (state is MessagesLoaded) {
              return _buildChatMessages(context, state);
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
                        context.read<ChatBloc>().add(const LoadConversations());
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text('Aucune conversation'));
          },
        ),
      ),
    );
  }

  void _scrollToBottom(BuildContext context) {
    final _scrollController = ScrollController();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildConversationsList(BuildContext context, List<ChatConversation> conversations) {
    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune conversation',
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
                'Commencez à discuter avec les propriétaires et agents immobiliers',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ChatBloc>().add(const LoadConversations());
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return _buildConversationItem(context, conversation);
        },
      ),
    );
  }

  Widget _buildConversationItem(BuildContext context, ChatConversation conversation) {
    // Trouver le participant qui n'est pas l'utilisateur actuel
    final otherParticipant = conversation.participants.firstWhere(
      (p) => p.id != 'user1',
      orElse: () => conversation.participants.first,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          context.read<ChatBloc>().add(SelectConversation(conversation.id));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildAvatar(otherParticipant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          otherParticipant.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          conversation.updatedAt != null ? _formatTimestamp(conversation.updatedAt!) : '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage?.content ?? 'Nouvelle conversation',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: conversation.unreadCount > 0
                                  ? Colors.black
                                  : Colors.grey[600],
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (conversation.unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ChatScreen.goldColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              conversation.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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

  Widget _buildChatMessages(BuildContext context, MessagesLoaded state) {
    // Trouver la conversation actuelle
    final currentConversation = state.conversations.firstWhere(
      (c) => c.id == state.currentConversationId,
      orElse: () => ChatConversation(
        id: state.currentConversationId,
        participants: [
          ChatParticipant(id: 'user1', name: 'Vous'),
          ChatParticipant(id: 'unknown', name: 'Inconnu'),
        ],
        lastMessage: null,
        unreadCount: 0,
        updatedAt: DateTime.now(),
        isArchived: false,
      ),
    );

    // Trouver le participant qui n'est pas l'utilisateur actuel
    final otherParticipant = currentConversation.participants.firstWhere(
      (p) => p.id != 'user1',
      orElse: () => currentConversation.participants.first,
    );

    return Column(
      children: [
        // En-tête de la conversation
        AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.read<ChatBloc>().add(const LoadConversations());
            },
          ),
          title: Row(
            children: [
              _buildAvatar(otherParticipant),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherParticipant.name,
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'En ligne',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[200],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: ChatScreen.goldColor,
          actions: [
            IconButton(
              icon: const Icon(Icons.phone),
              onPressed: () {
                // Fonctionnalité d'appel à implémenter
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Menu d'options à implémenter
              },
            ),
          ],
        ),
        
        // Liste des messages
        Expanded(
          child: state.messages.isEmpty
              ? _buildEmptyChat()
              : ListView.builder(
                  controller: ScrollController(),
                  padding: const EdgeInsets.all(16),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    final isUserMessage = message.senderId == 'user1';
                    
                    // Vérifier si le message précédent est du même expéditeur
                    final bool showAvatar = index == 0 || 
                        state.messages[index - 1].senderId != message.senderId;
                    
                    return _buildMessageItem(
                      context,
                      message,
                      isUserMessage,
                      showAvatar,
                      otherParticipant,
                    );
                  },
                ),
        ),
        
        // Zone de saisie de message
        _buildMessageInput(context, state.currentConversationId),
      ],
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Commencez la conversation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Envoyez un message pour démarrer la discussion',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(
    BuildContext context,
    ChatMessage message,
    bool isUserMessage,
    bool showAvatar,
    ChatParticipant otherParticipant,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUserMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUserMessage && showAvatar)
            _buildAvatar(otherParticipant)
          else if (!isUserMessage)
            const SizedBox(width: 40),
            
          if (!isUserMessage) const SizedBox(width: 8),
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUserMessage
                    ? ChatScreen.goldColor.withOpacity(0.9)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content ?? '',
                    style: TextStyle(
                      color: isUserMessage ? Colors.black : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isUserMessage
                              ? Colors.black.withOpacity(0.6)
                              : Colors.grey[600],
                        ),
                      ),
                      if (isUserMessage) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _getStatusIcon(message.status),
                          size: 12,
                          color: message.status == MessageStatus.read
                              ? Colors.blue
                              : Colors.grey[600],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isUserMessage) const SizedBox(width: 8),
          
          if (isUserMessage && showAvatar)
            const CircleAvatar(
              radius: 16,
              backgroundColor: ChatScreen.goldColor,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            )
          else if (isUserMessage)
            const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context, String conversationId) {
    final _messageController = TextEditingController();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            icon: const Icon(Icons.send),
            color: ChatScreen.goldColor,
            onPressed: () {
              if (_messageController.text.trim().isNotEmpty) {
                context.read<ChatBloc>().add(
                  SendMessage(
                    conversationId: conversationId,
                    content: _messageController.text.trim(),
                  ),
                );
                _messageController.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ChatParticipant participant) {
    if (participant.avatarUrl != null) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: AssetImage(participant.avatarUrl!),
      );
    } else {
      return CircleAvatar(
        radius: 20,
        backgroundColor: ChatScreen.goldColor,
        child: Text(
          participant.name.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays == 0) {
      // Aujourd'hui: afficher l'heure
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      // Hier
      return 'Hier';
    } else if (difference.inDays < 7) {
      // Cette semaine: afficher le jour
      return DateFormat('EEEE').format(timestamp);
    } else {
      // Plus ancien: afficher la date
      return DateFormat('dd/MM/yyyy').format(timestamp);
    }
  }

  String _formatMessageTime(DateTime timestamp) {
    return DateFormat('HH:mm').format(timestamp);
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.check;
      case MessageStatus.read:
        return Icons.done_all;
      default:
        return Icons.access_time;
    }
  }
}