part of 'chat_bloc.dart';

@freezed
class ChatEvent with _$ChatEvent {
  const factory ChatEvent.loadConversations() = LoadConversations;
  
  const factory ChatEvent.createConversation({
    required String userId,
    String? residenceId,
    String? reservationId,
  }) = CreateConversation;
  
  const factory ChatEvent.sendMessage({
    required String conversationId,
    required String content,
  }) = SendMessage;
  
  const factory ChatEvent.sendFile({
    required String conversationId,
    required String filePath,
    String? type,
  }) = SendFile;
  
  const factory ChatEvent.sendImage({
    required String conversationId,
    required String imagePath,
  }) = SendImage;
  
  const factory ChatEvent.loadMessages({
    required String conversationId,
  }) = LoadMessages;
  
  const factory ChatEvent.markAsRead({
    required String messageId,
    required String conversationId,
  }) = MarkAsRead;
  
  const factory ChatEvent.markAllAsRead({
    required String conversationId,
  }) = MarkAllAsRead;
}