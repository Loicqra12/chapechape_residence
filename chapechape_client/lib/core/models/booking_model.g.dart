// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BookingImpl _$$BookingImplFromJson(Map<String, dynamic> json) =>
    _$BookingImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      residenceId: json['residenceId'] as String,
      checkIn: DateTime.parse(json['checkIn'] as String),
      checkOut: DateTime.parse(json['checkOut'] as String),
      numberOfGuests: (json['numberOfGuests'] as num).toInt(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      paymentId: json['paymentId'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$BookingImplToJson(_$BookingImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'residenceId': instance.residenceId,
      'checkIn': instance.checkIn.toIso8601String(),
      'checkOut': instance.checkOut.toIso8601String(),
      'numberOfGuests': instance.numberOfGuests,
      'totalPrice': instance.totalPrice,
      'status': instance.status,
      if (instance.paymentId case final value?) 'paymentId': value,
      if (instance.paymentStatus case final value?) 'paymentStatus': value,
      if (instance.cancellationReason case final value?)
        'cancellationReason': value,
      if (instance.createdAt?.toIso8601String() case final value?)
        'createdAt': value,
      if (instance.updatedAt?.toIso8601String() case final value?)
        'updatedAt': value,
    };
