import 'package:equatable/equatable.dart';
import '../../models/chat_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ConversationsLoaded extends ChatState {
  final List<ChatConversation> conversations;

  const ConversationsLoaded(this.conversations);

  @override
  List<Object?> get props => [conversations];
}

class MessagesLoaded extends ChatState {
  final List<ChatConversation> conversations;
  final List<ChatMessage> messages;
  final String currentConversationId;

  const MessagesLoaded({
    required this.conversations,
    required this.messages,
    required this.currentConversationId,
  });

  @override
  List<Object?> get props => [conversations, messages, currentConversationId];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}