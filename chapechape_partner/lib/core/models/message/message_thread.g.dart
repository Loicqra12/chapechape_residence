// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_thread.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageThread _$MessageThreadFromJson(Map<String, dynamic> json) =>
    MessageThread(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      clientName: json['clientName'] as String,
      clientAvatar: json['clientAvatar'] as String?,
      partnerId: json['partnerId'] as String,
      residenceId: json['residenceId'] as String?,
      residenceName: json['residenceName'] as String?,
      reservationId: json['reservationId'] as String?,
      reservationStatus: json['reservationStatus'] as String?,
      lastMessageTime: DateTime.parse(json['lastMessageTime'] as String),
      unreadCount: (json['unreadCount'] as num).toInt(),
      messages: (json['messages'] as List<dynamic>)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MessageThreadToJson(MessageThread instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clientId': instance.clientId,
      'clientName': instance.clientName,
      'clientAvatar': instance.clientAvatar,
      'partnerId': instance.partnerId,
      'residenceId': instance.residenceId,
      'residenceName': instance.residenceName,
      'reservationId': instance.reservationId,
      'reservationStatus': instance.reservationStatus,
      'lastMessageTime': instance.lastMessageTime.toIso8601String(),
      'unreadCount': instance.unreadCount,
      'messages': instance.messages,
    };
