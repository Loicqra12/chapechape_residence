// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageAttachment _$MessageAttachmentFromJson(Map<String, dynamic> json) =>
    MessageAttachment(
      id: json['id'] as String,
      url: json['url'] as String,
      type: json['type'] as String,
      name: json['name'] as String?,
      size: (json['size'] as num).toInt(),
    );

Map<String, dynamic> _$MessageAttachmentToJson(MessageAttachment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'type': instance.type,
      'name': instance.name,
      'size': instance.size,
    };

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      content: json['content'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderAvatar: json['senderAvatar'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      read: json['read'] as bool,
      attachments: (json['attachments'] as List<dynamic>)
          .map((e) => MessageAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
      reservationId: json['reservationId'] as String?,
      reservationStatus: json['reservationStatus'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      conversation: json['conversation'] == null
          ? null
          : Conversation.fromJson(json['conversation'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'id': instance.id,
      'conversationId': instance.conversationId,
      'content': instance.content,
      'senderId': instance.senderId,
      'senderName': instance.senderName,
      'senderAvatar': instance.senderAvatar,
      'timestamp': instance.timestamp.toIso8601String(),
      'read': instance.read,
      'attachments': instance.attachments,
      'reservationId': instance.reservationId,
      'reservationStatus': instance.reservationStatus,
      'metadata': instance.metadata,
      'conversation': instance.conversation,
    };
