import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'chat_model.freezed.dart';
part 'chat_model.g.dart';

enum MessageStatus {
  sent,
  delivered,
  read,
  failed
}

@freezed
class ChatParticipant with _$ChatParticipant {
  const factory ChatParticipant({
    required String id,
    required String name,
    String? avatarUrl,
    @Default(false) bool isOnline,
    DateTime? lastSeen,
    @Default(false) bool isTyping,
  }) = _ChatParticipant;

  factory ChatParticipant.fromJson(Map<String, dynamic> json) => 
      _$ChatParticipantFromJson(json);
}

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String senderId,
    String? text,
    String? content,
    required DateTime timestamp,
    @Default(false) bool isRead,
    String? attachmentUrl,
    String? attachmentType,
    @Default(MessageStatus.sent) MessageStatus status,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => 
      _$ChatMessageFromJson(json);
}

@freezed
class ChatConversation with _$ChatConversation {
  const factory ChatConversation({
    required String id,
    String? title,
    List<String>? participantIds,
    @Default([]) List<ChatMessage> messages,
    DateTime? lastMessageTime,
    String? lastMessageText,
    String? lastMessageSenderId,
    @Default(false) bool isSupport,
    @Default(false) bool isArchived,
    @Default(0) int unreadCount,
    @Default([]) List<ChatParticipant> participants,
    ChatMessage? lastMessage,
    DateTime? updatedAt,
  }) = _ChatConversation;

  factory ChatConversation.fromJson(Map<String, dynamic> json) => 
      _$ChatConversationFromJson(json);
}
