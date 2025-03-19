import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/blocs/chat/chat_bloc.dart';
import '../../core/services/api_service.dart';
import '../../core/services/chat_service.dart';
import '../screens/chat_conversation_screen.dart';

class CustomerSupportWidget extends StatelessWidget {
  final String userId;
  final String? residenceId;
  final String? bookingId;
  final ApiService apiService;
  final ChatService chatService;

  const CustomerSupportWidget({
    super.key,
    required this.userId,
    this.residenceId,
    this.bookingId,
    required this.apiService,
    required this.chatService,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc(
        chatService: chatService,
      ),
      child: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatLoaded && state.selectedConversation != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatConversationScreen(
                  conversation: state.selectedConversation!,
                  apiService: apiService,
                  chatService: chatService,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return ElevatedButton.icon(
            onPressed: () {
              context.read<ChatBloc>().add(CreateConversation(
                    userId: userId,
                    residenceId: residenceId,
                    reservationId: bookingId,
                  ));
            },
            icon: const Icon(Icons.support_agent),
            label: const Text('Contacter le support'),
          );
        },
      ),
    );
  }
}
