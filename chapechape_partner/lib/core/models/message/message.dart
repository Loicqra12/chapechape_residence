import 'package:json_annotation/json_annotation.dart';
import 'conversation.dart';

part 'message.g.dart';

@JsonSerializable()
class MessageAttachment {
  final String id;
  final String url;
  final String type;
  final String? name;
  final int size;

  MessageAttachment({
    required this.id,
    required this.url,
    required this.type,
    this.name,
    required this.size,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) => _$MessageAttachmentFromJson(json);
  Map<String, dynamic> toJson() => _$MessageAttachmentToJson(this);
}

@JsonSerializable()
class Message {
  final String id;
  final String conversationId;
  final String content;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final DateTime timestamp;
  final bool read;
  final List<MessageAttachment> attachments;
  final String? bookingId;
  final String? bookingStatus;
  final Map<String, dynamic>? metadata;
  final Conversation? conversation;

  Message({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.timestamp,
    required this.read,
    required this.attachments,
    this.bookingId,
    this.bookingStatus,
    this.metadata,
    this.conversation,
  });

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);

  Message copyWith({
    String? id,
    String? conversationId,
    String? content,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    DateTime? timestamp,
    bool? read,
    List<MessageAttachment>? attachments,
    String? bookingId,
    String? bookingStatus,
    Map<String, dynamic>? metadata,
    Conversation? conversation,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
      attachments: attachments ?? this.attachments,
      bookingId: bookingId ?? this.bookingId,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      metadata: metadata ?? this.metadata,
      conversation: conversation ?? this.conversation,
    );
  }
}
