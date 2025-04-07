// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modification_fees_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModificationFees _$ModificationFeesFromJson(Map<String, dynamic> json) =>
    ModificationFees(
      baseFee: (json['baseFee'] as num).toDouble(),
      priceDifference: (json['priceDifference'] as num).toDouble(),
      totalFee: (json['totalFee'] as num).toDouble(),
      currency: json['currency'] as String,
    );

Map<String, dynamic> _$ModificationFeesToJson(ModificationFees instance) =>
    <String, dynamic>{
      'baseFee': instance.baseFee,
      'priceDifference': instance.priceDifference,
      'totalFee': instance.totalFee,
      'currency': instance.currency,
    };
