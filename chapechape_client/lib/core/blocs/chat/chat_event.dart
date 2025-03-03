import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversations extends ChatEvent {
  const LoadConversations();
}

class LoadMessages extends ChatEvent {
  final String conversationId;
  final bool markAsRead;

  const LoadMessages(this.conversationId, {this.markAsRead = false});

  @override
  List<Object?> get props => [conversationId, markAsRead];
}

class SendMessage extends ChatEvent {
  final String conversationId;
  final String content;

  const SendMessage({
    required this.conversationId,
    required this.content,
  });

  @override
  List<Object?> get props => [conversationId, content];
}

class MarkMessageAsRead extends ChatEvent {
  final String messageId;

  const MarkMessageAsRead(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

class MarkAllAsRead extends ChatEvent {
  final String conversationId;

  const MarkAllAsRead(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class CreateConversation extends ChatEvent {
  final String recipientId;

  const CreateConversation(this.recipientId);

  @override
  List<Object?> get props => [recipientId];
}

class SelectConversation extends ChatEvent {
  final String conversationId;

  const SelectConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}