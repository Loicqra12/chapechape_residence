import 'package:json_annotation/json_annotation.dart';
import '../booking/booking.dart';
import 'message.dart';

part 'conversation.g.dart';

@JsonSerializable()
class ConversationParticipant {
  final String id;
  final String name;
  final String? avatar;
  final String role;
  final bool isActive;

  ConversationParticipant({
    required this.id,
    required this.name,
    this.avatar,
    required this.role,
    required this.isActive,
  });

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) => _$ConversationParticipantFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationParticipantToJson(this);
}

@JsonSerializable()
class Conversation {
  final String id;
  final String? title;
  final List<ConversationParticipant> participants;
  final Message? lastMessage;
  final int unreadCount;
  final Booking? booking;
  final String? residenceId;
  final String? residenceName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  Conversation({
    required this.id,
    this.title,
    required this.participants,
    this.lastMessage,
    required this.unreadCount,
    this.booking,
    this.residenceId,
    this.residenceName,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationToJson(this);

  Conversation copyWith({
    String? id,
    String? title,
    List<ConversationParticipant>? participants,
    Message? lastMessage,
    int? unreadCount,
    Booking? booking,
    String? residenceId,
    String? residenceName,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      booking: booking ?? this.booking,
      residenceId: residenceId ?? this.residenceId,
      residenceName: residenceName ?? this.residenceName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
