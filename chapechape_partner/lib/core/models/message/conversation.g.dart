// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConversationParticipant _$ConversationParticipantFromJson(
  Map<String, dynamic> json,
) => ConversationParticipant(
  id: json['id'] as String,
  name: json['name'] as String,
  avatar: json['avatar'] as String?,
  role: json['role'] as String,
  isActive: json['isActive'] as bool,
);

Map<String, dynamic> _$ConversationParticipantToJson(
  ConversationParticipant instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'avatar': instance.avatar,
  'role': instance.role,
  'isActive': instance.isActive,
};

Conversation _$ConversationFromJson(Map<String, dynamic> json) => Conversation(
  id: json['id'] as String,
  title: json['title'] as String?,
  participants: (json['participants'] as List<dynamic>)
      .map((e) => ConversationParticipant.fromJson(e as Map<String, dynamic>))
      .toList(),
  lastMessage: json['lastMessage'] == null
      ? null
      : Message.fromJson(json['lastMessage'] as Map<String, dynamic>),
  unreadCount: (json['unreadCount'] as num).toInt(),
  booking: json['booking'] == null
      ? null
      : Booking.fromJson(json['booking'] as Map<String, dynamic>),
  residenceId: json['residenceId'] as String?,
  residenceName: json['residenceName'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ConversationToJson(Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'participants': instance.participants,
      'lastMessage': instance.lastMessage,
      'unreadCount': instance.unreadCount,
      'booking': instance.booking,
      'residenceId': instance.residenceId,
      'residenceName': instance.residenceName,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'metadata': instance.metadata,
    };
