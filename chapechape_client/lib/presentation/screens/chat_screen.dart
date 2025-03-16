import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/blocs/chat/chat_bloc.dart' as chat;
import '../../core/models/chat_model.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/api_service.dart';
import '../widgets/loading_widget.dart';
import 'package:go_router/go_router.dart';

class ChatScreen extends StatelessWidget {
  final ChatService chatService;
  final ApiService apiService;

  const ChatScreen({
    Key? key,
    required this.chatService,
    required this.apiService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final chatBloc = chat.ChatBloc(
          chatService: chatService,
        );
        chatBloc.add(const chat.LoadConversations());
        return chatBloc;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: BlocBuilder<chat.ChatBloc, chat.ChatState>(
          builder: (context, state) {
            if (state is chat.ChatLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is chat.ChatError) {
              return Center(
                child: Text('Erreur: ${state.message}'),
              );
            }

            if (state is chat.ChatLoaded) {
              if (state.conversations.isEmpty) {
                return const Center(
                  child: Text('Aucune conversation'),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<chat.ChatBloc>().add(const chat.LoadConversations());
                },
                child: ListView.builder(
                  itemCount: state.conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = state.conversations[index];
                    final lastMessage = conversation.messages.isNotEmpty ? conversation.messages.last : null;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        child: Icon(Icons.home),
                      ),
                      title: Text(
                        'Conversation ${conversation.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (lastMessage != null)
                            Text(
                              lastMessage.content,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: !lastMessage.isRead
                                    ? Colors.black87
                                    : Colors.grey[600],
                                fontWeight: !lastMessage.isRead
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (lastMessage != null)
                            Text(
                              _formatLastMessageTime(lastMessage.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: !lastMessage.isRead
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        context.read<chat.ChatBloc>().add(
                              chat.LoadMessages(conversationId: conversation.id),
                            );
                        GoRouter.of(context).go('/chat/conversation/${conversation.id}');
                      },
                    );
                  },
                ),
              );
            }

            return const Center(
              child: Text('Something went wrong'),
            );
          },
        ),
      ),
    );
  }

  String _formatLastMessageTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(time);
    } else if (messageDate == yesterday) {
      return 'Hier';
    } else if (now.difference(time).inDays < 7) {
      return DateFormat('EEEE', 'fr_FR').format(time);
    } else {
      return DateFormat('dd/MM/yyyy').format(time);
    }
  }
}