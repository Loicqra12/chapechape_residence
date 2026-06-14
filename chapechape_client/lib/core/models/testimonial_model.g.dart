// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'testimonial_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TestimonialModelImpl _$$TestimonialModelImplFromJson(
        Map<String, dynamic> json) =>
    _$TestimonialModelImpl(
      id: json['id'] as String?,
      userName: json['userName'] as String?,
      userAvatar: json['userAvatar'] as String?,
      residenceName: json['residenceName'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      content: json['content'] as String?,
      date:
          json['date'] == null ? null : DateTime.parse(json['date'] as String),
    );

Map<String, dynamic> _$$TestimonialModelImplToJson(
    _$TestimonialModelImpl instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  writeNotNull('userName', instance.userName);
  writeNotNull('userAvatar', instance.userAvatar);
  writeNotNull('residenceName', instance.residenceName);
  writeNotNull('rating', instance.rating);
  writeNotNull('content', instance.content);
  writeNotNull('date', instance.date?.toIso8601String());
  return val;
}
