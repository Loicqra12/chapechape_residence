// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_store_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppStoreModelImpl _$$AppStoreModelImplFromJson(Map<String, dynamic> json) =>
    _$AppStoreModelImpl(
      name: json['name'] as String,
      logoUrl: json['logoUrl'] as String,
      downloadUrl: json['downloadUrl'] as String,
      qrCodeUrl: json['qrCodeUrl'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$AppStoreModelImplToJson(_$AppStoreModelImpl instance) {
  final val = <String, dynamic>{
    'name': instance.name,
    'logoUrl': instance.logoUrl,
    'downloadUrl': instance.downloadUrl,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('qrCodeUrl', instance.qrCodeUrl);
  writeNotNull('description', instance.description);
  return val;
}
