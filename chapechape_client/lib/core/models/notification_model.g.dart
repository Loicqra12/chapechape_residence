// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NotificationModelImpl _$$NotificationModelImplFromJson(
        Map<String, dynamic> json) =>
    _$NotificationModelImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
      actionUrl: json['actionUrl'] as String?,
      type: json['type'] as String?,
      metadata: json['data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$NotificationModelImplToJson(
    _$NotificationModelImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'title': instance.title,
    'message': instance.message,
    'timestamp': instance.timestamp.toIso8601String(),
    'isRead': instance.isRead,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('imageUrl', instance.imageUrl);
  writeNotNull('actionUrl', instance.actionUrl);
  writeNotNull('type', instance.type);
  writeNotNull('data', instance.metadata);
  return val;
}
