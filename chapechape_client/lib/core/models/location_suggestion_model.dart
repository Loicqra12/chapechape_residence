import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'location_suggestion_model.freezed.dart';
part 'location_suggestion_model.g.dart';

@freezed
class LocationSuggestionModel with _$LocationSuggestionModel {
  const factory LocationSuggestionModel({
    required String id,
    required String name,
    required String fullAddress,
    String? city,
    String? district,
    String? country,
    double? latitude,
    double? longitude,
    @Default(false) bool isPopular,
    @Default(0) int searchCount,
  }) = _LocationSuggestionModel;

  factory LocationSuggestionModel.fromJson(Map<String, dynamic> json) => 
      _$LocationSuggestionModelFromJson(json);
}
