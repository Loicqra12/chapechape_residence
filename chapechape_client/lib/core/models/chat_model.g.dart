// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatMessageImpl _$$ChatMessageImplFromJson(Map<String, dynamic> json) =>
    _$ChatMessageImpl(
      id: json['id'] as String,
      content: json['content'] as String,
      senderId: json['senderId'] as String,
      conversationId: json['conversationId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      type: json['type'] as String? ?? 'text',
      fileUrl: json['fileUrl'] as String?,
      isRead: json['isRead'] as bool? ?? false,
    );

Map<String, dynamic> _$$ChatMessageImplToJson(_$ChatMessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'senderId': instance.senderId,
      'conversationId': instance.conversationId,
      'createdAt': instance.createdAt.toIso8601String(),
      'type': instance.type,
      if (instance.fileUrl case final value?) 'fileUrl': value,
      'isRead': instance.isRead,
    };

_$ChatParticipantImpl _$$ChatParticipantImplFromJson(
        Map<String, dynamic> json) =>
    _$ChatParticipantImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'user',
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] == null
          ? null
          : DateTime.parse(json['lastSeen'] as String),
    );

Map<String, dynamic> _$$ChatParticipantImplToJson(
        _$ChatParticipantImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      if (instance.avatarUrl case final value?) 'avatarUrl': value,
      'role': instance.role,
      'isOnline': instance.isOnline,
      if (instance.lastSeen?.toIso8601String() case final value?)
        'lastSeen': value,
    };

_$ChatConversationImpl _$$ChatConversationImplFromJson(
        Map<String, dynamic> json) =>
    _$ChatConversationImpl(
      id: json['id'] as String,
      participants: (json['participants'] as List<dynamic>)
          .map((e) => ChatParticipant.fromJson(e as Map<String, dynamic>))
          .toList(),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      residenceId: json['residenceId'] as String?,
      residenceName: json['residenceName'] as String?,
      reservationId: json['reservationId'] as String?,
      isUnread: json['isUnread'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ChatConversationImplToJson(
        _$ChatConversationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'participants': instance.participants.map((e) => e.toJson()).toList(),
      'messages': instance.messages.map((e) => e.toJson()).toList(),
      if (instance.residenceId case final value?) 'residenceId': value,
      if (instance.residenceName case final value?) 'residenceName': value,
      if (instance.reservationId case final value?) 'reservationId': value,
      'isUnread': instance.isUnread,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
