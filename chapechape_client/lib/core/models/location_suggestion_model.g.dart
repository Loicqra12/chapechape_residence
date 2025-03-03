// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_suggestion_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LocationSuggestionModelImpl _$$LocationSuggestionModelImplFromJson(
        Map<String, dynamic> json) =>
    _$LocationSuggestionModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      fullAddress: json['fullAddress'] as String,
      city: json['city'] as String?,
      district: json['district'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isPopular: json['isPopular'] as bool? ?? false,
      searchCount: (json['searchCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$LocationSuggestionModelImplToJson(
        _$LocationSuggestionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'fullAddress': instance.fullAddress,
      if (instance.city case final value?) 'city': value,
      if (instance.district case final value?) 'district': value,
      if (instance.country case final value?) 'country': value,
      if (instance.latitude case final value?) 'latitude': value,
      if (instance.longitude case final value?) 'longitude': value,
      'isPopular': instance.isPopular,
      'searchCount': instance.searchCount,
    };
