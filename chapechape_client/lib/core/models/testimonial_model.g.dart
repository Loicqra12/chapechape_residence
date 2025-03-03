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
        _$TestimonialModelImpl instance) =>
    <String, dynamic>{
      if (instance.id case final value?) 'id': value,
      if (instance.userName case final value?) 'userName': value,
      if (instance.userAvatar case final value?) 'userAvatar': value,
      if (instance.residenceName case final value?) 'residenceName': value,
      if (instance.rating case final value?) 'rating': value,
      if (instance.content case final value?) 'content': value,
      if (instance.date?.toIso8601String() case final value?) 'date': value,
    };
