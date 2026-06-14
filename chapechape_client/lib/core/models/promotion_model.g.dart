// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PromotionImpl _$$PromotionImplFromJson(Map<String, dynamic> json) =>
    _$PromotionImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      discountPercentage: (json['discountPercentage'] as num).toDouble(),
      discountCode: json['discountCode'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      imageUrl: json['imageUrl'] as String,
      residenceId: json['residenceId'] as String,
      residence: json['residence'] == null
          ? null
          : Residence.fromJson(json['residence'] as Map<String, dynamic>),
      badge: json['badge'] as String?,
      isExclusive: json['isExclusive'] as bool? ?? false,
      type: $enumDecodeNullable(_$PromotionTypeEnumMap, json['type']) ??
          PromotionType.discount,
      termsAndConditions: json['termsAndConditions'] as String?,
    );

Map<String, dynamic> _$$PromotionImplToJson(_$PromotionImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'title': instance.title,
    'description': instance.description,
    'discountPercentage': instance.discountPercentage,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('discountCode', instance.discountCode);
  val['startDate'] = instance.startDate.toIso8601String();
  val['endDate'] = instance.endDate.toIso8601String();
  val['imageUrl'] = instance.imageUrl;
  val['residenceId'] = instance.residenceId;
  writeNotNull('residence', instance.residence?.toJson());
  writeNotNull('badge', instance.badge);
  val['isExclusive'] = instance.isExclusive;
  val['type'] = _$PromotionTypeEnumMap[instance.type]!;
  writeNotNull('termsAndConditions', instance.termsAndConditions);
  return val;
}

const _$PromotionTypeEnumMap = {
  PromotionType.discount: 'discount',
  PromotionType.flash: 'flash',
  PromotionType.seasonal: 'seasonal',
  PromotionType.bundle: 'bundle',
  PromotionType.exclusive: 'exclusive',
  PromotionType.newUser: 'newUser',
};
