import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'testimonial_model.freezed.dart';
part 'testimonial_model.g.dart';

@freezed
class TestimonialModel with _$TestimonialModel {
  const factory TestimonialModel({
    String? id,
    String? userName,
    String? userAvatar,
    String? residenceName,
    double? rating,
    String? content,
    DateTime? date,
  }) = _TestimonialModel;

  factory TestimonialModel.fromJson(Map<String, dynamic> json) => 
      _$TestimonialModelFromJson(json);
}
