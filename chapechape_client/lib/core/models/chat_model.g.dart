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

Map<String, dynamic> _$$ChatMessageImplToJson(_$ChatMessageImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'content': instance.content,
    'senderId': instance.senderId,
    'conversationId': instance.conversationId,
    'createdAt': instance.createdAt.toIso8601String(),
    'type': instance.type,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('fileUrl', instance.fileUrl);
  val['isRead'] = instance.isRead;
  return val;
}

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
    _$ChatParticipantImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('avatarUrl', instance.avatarUrl);
  val['role'] = instance.role;
  val['isOnline'] = instance.isOnline;
  writeNotNull('lastSeen', instance.lastSeen?.toIso8601String());
  return val;
}

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
    _$ChatConversationImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'participants': instance.participants.map((e) => e.toJson()).toList(),
    'messages': instance.messages.map((e) => e.toJson()).toList(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('residenceId', instance.residenceId);
  writeNotNull('residenceName', instance.residenceName);
  writeNotNull('reservationId', instance.reservationId);
  val['isUnread'] = instance.isUnread;
  val['createdAt'] = instance.createdAt.toIso8601String();
  val['updatedAt'] = instance.updatedAt.toIso8601String();
  return val;
}
