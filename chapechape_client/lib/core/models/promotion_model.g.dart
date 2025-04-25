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

Map<String, dynamic> _$$PromotionImplToJson(_$PromotionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'discountPercentage': instance.discountPercentage,
      if (instance.discountCode case final value?) 'discountCode': value,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'imageUrl': instance.imageUrl,
      'residenceId': instance.residenceId,
      if (instance.residence?.toJson() case final value?) 'residence': value,
      if (instance.badge case final value?) 'badge': value,
      'isExclusive': instance.isExclusive,
      'type': _$PromotionTypeEnumMap[instance.type]!,
      if (instance.termsAndConditions case final value?)
        'termsAndConditions': value,
    };

const _$PromotionTypeEnumMap = {
  PromotionType.discount: 'discount',
  PromotionType.flash: 'flash',
  PromotionType.seasonal: 'seasonal',
  PromotionType.bundle: 'bundle',
  PromotionType.exclusive: 'exclusive',
  PromotionType.newUser: 'newUser',
};
