// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatParticipantImpl _$$ChatParticipantImplFromJson(
        Map<String, dynamic> json) =>
    _$ChatParticipantImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] == null
          ? null
          : DateTime.parse(json['lastSeen'] as String),
      isTyping: json['isTyping'] as bool? ?? false,
    );

Map<String, dynamic> _$$ChatParticipantImplToJson(
        _$ChatParticipantImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      if (instance.avatarUrl case final value?) 'avatarUrl': value,
      'isOnline': instance.isOnline,
      if (instance.lastSeen?.toIso8601String() case final value?)
        'lastSeen': value,
      'isTyping': instance.isTyping,
    };

_$ChatMessageImpl _$$ChatMessageImplFromJson(Map<String, dynamic> json) =>
    _$ChatMessageImpl(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      text: json['text'] as String?,
      content: json['content'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      attachmentUrl: json['attachmentUrl'] as String?,
      attachmentType: json['attachmentType'] as String?,
      status: $enumDecodeNullable(_$MessageStatusEnumMap, json['status']) ??
          MessageStatus.sent,
    );

Map<String, dynamic> _$$ChatMessageImplToJson(_$ChatMessageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'senderId': instance.senderId,
      if (instance.text case final value?) 'text': value,
      if (instance.content case final value?) 'content': value,
      'timestamp': instance.timestamp.toIso8601String(),
      'isRead': instance.isRead,
      if (instance.attachmentUrl case final value?) 'attachmentUrl': value,
      if (instance.attachmentType case final value?) 'attachmentType': value,
      'status': _$MessageStatusEnumMap[instance.status]!,
    };

const _$MessageStatusEnumMap = {
  MessageStatus.sent: 'sent',
  MessageStatus.delivered: 'delivered',
  MessageStatus.read: 'read',
  MessageStatus.failed: 'failed',
};

_$ChatConversationImpl _$$ChatConversationImplFromJson(
        Map<String, dynamic> json) =>
    _$ChatConversationImpl(
      id: json['id'] as String,
      title: json['title'] as String?,
      participantIds: (json['participantIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      lastMessageTime: json['lastMessageTime'] == null
          ? null
          : DateTime.parse(json['lastMessageTime'] as String),
      lastMessageText: json['lastMessageText'] as String?,
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      isSupport: json['isSupport'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => ChatParticipant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      lastMessage: json['lastMessage'] == null
          ? null
          : ChatMessage.fromJson(json['lastMessage'] as Map<String, dynamic>),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ChatConversationImplToJson(
        _$ChatConversationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      if (instance.title case final value?) 'title': value,
      if (instance.participantIds case final value?) 'participantIds': value,
      'messages': instance.messages.map((e) => e.toJson()).toList(),
      if (instance.lastMessageTime?.toIso8601String() case final value?)
        'lastMessageTime': value,
      if (instance.lastMessageText case final value?) 'lastMessageText': value,
      if (instance.lastMessageSenderId case final value?)
        'lastMessageSenderId': value,
      'isSupport': instance.isSupport,
      'isArchived': instance.isArchived,
      'unreadCount': instance.unreadCount,
      'participants': instance.participants.map((e) => e.toJson()).toList(),
      if (instance.lastMessage?.toJson() case final value?)
        'lastMessage': value,
      if (instance.updatedAt?.toIso8601String() case final value?)
        'updatedAt': value,
    };
