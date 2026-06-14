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
    _$LocationSuggestionModelImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'name': instance.name,
    'fullAddress': instance.fullAddress,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('city', instance.city);
  writeNotNull('district', instance.district);
  writeNotNull('country', instance.country);
  writeNotNull('latitude', instance.latitude);
  writeNotNull('longitude', instance.longitude);
  val['isPopular'] = instance.isPopular;
  val['searchCount'] = instance.searchCount;
  return val;
}
