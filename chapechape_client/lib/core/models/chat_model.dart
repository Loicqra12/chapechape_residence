import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_model.freezed.dart';
part 'chat_model.g.dart';

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String content,
    required String senderId,
    required String conversationId,
    required DateTime createdAt,
    @Default('text') String type,
    String? fileUrl,
    @Default(false) bool isRead,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}

@freezed
class ChatParticipant with _$ChatParticipant {
  const factory ChatParticipant({
    required String id,
    required String name,
    String? avatarUrl,
    @Default('user') String role,
    @Default(false) bool isOnline,
    DateTime? lastSeen,
  }) = _ChatParticipant;

  factory ChatParticipant.fromJson(Map<String, dynamic> json) =>
      _$ChatParticipantFromJson(json);
}

@freezed
class ChatConversation with _$ChatConversation {
  const factory ChatConversation({
    required String id,
    required List<ChatParticipant> participants,
    @Default([]) List<ChatMessage> messages,
    String? residenceId,
    String? bookingId,
    @Default(false) bool isUnread,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ChatConversation;

  factory ChatConversation.fromJson(Map<String, dynamic> json) =>
      _$ChatConversationFromJson(json);
}
