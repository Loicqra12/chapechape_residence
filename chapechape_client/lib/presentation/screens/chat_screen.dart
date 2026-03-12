import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../core/blocs/chat/chat_bloc.dart' as chat;
import '../../core/models/chat_model.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/onesignal_service.dart';
import '../widgets/loading_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:chapechape_client/presentation/widgets/common/empty_state_widget.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/text_styles.dart';

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
                return const EmptyStateWidget(
                  imagePath: 'assets/images/empty_states/empty_chat_illustration.png',
                  title: 'Aucune conversation',
                  subtitle: 'Contactez un propriétaire pour poser vos questions et réserver en toute confiance',
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
                        _getConversationTitle(conversation),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                              style: AppTextStyles.caption.copyWith(
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

  String _getConversationTitle(ChatConversation conversation) {
    // Si nous avons un nom de résidence, utilisons-le en priorité
    if (conversation.residenceName != null && conversation.residenceName!.isNotEmpty) {
      return "Conversation - ${conversation.residenceName}";
    }
    
    // Sinon, essayons de trouver un participant qui n'est pas l'utilisateur courant
    // En supposant que l'utilisateur est généralement celui qui n'a pas le rôle "partner"
    final partner = conversation.participants.firstWhere(
      (p) => p.role == 'partner',
      orElse: () => conversation.participants.firstWhere(
        (p) => p.role != 'user' && p.role != 'client',
        orElse: () => conversation.participants.isNotEmpty 
          ? conversation.participants[0] 
          : ChatParticipant(id: '', name: 'Inconnu', role: 'unknown'),
      ),
    );
    
    return "Conversation avec ${partner.name}";
  }
}