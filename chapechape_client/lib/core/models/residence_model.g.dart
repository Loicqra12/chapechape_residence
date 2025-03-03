// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'residence_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ResidenceImpl _$$ResidenceImplFromJson(Map<String, dynamic> json) =>
    _$ResidenceImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      address: json['address'] as String,
      city: json['city'] as String,
      country: json['country'] as String,
      images:
          (json['images'] as List<dynamic>).map((e) => e as String).toList(),
      bedrooms: (json['bedrooms'] as num).toInt(),
      bathrooms: (json['bathrooms'] as num).toInt(),
      surface: (json['surface'] as num).toDouble(),
      isAvailable: json['isAvailable'] as bool,
      location: json['location'] as Map<String, dynamic>,
      amenities: (json['amenities'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      rules:
          (json['rules'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      isFavorite: json['isFavorite'] as bool? ?? false,
      type: $enumDecodeNullable(_$ResidenceTypeEnumMap, json['type']) ??
          ResidenceType.apartment,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt(),
      ownerId: json['ownerId'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ResidenceImplToJson(_$ResidenceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'address': instance.address,
      'city': instance.city,
      'country': instance.country,
      'images': instance.images,
      'bedrooms': instance.bedrooms,
      'bathrooms': instance.bathrooms,
      'surface': instance.surface,
      'isAvailable': instance.isAvailable,
      'location': instance.location,
      'amenities': instance.amenities,
      'rules': instance.rules,
      'isFavorite': instance.isFavorite,
      'type': _$ResidenceTypeEnumMap[instance.type]!,
      if (instance.rating case final value?) 'rating': value,
      if (instance.reviewCount case final value?) 'reviewCount': value,
      if (instance.ownerId case final value?) 'ownerId': value,
      if (instance.createdAt?.toIso8601String() case final value?)
        'createdAt': value,
      if (instance.updatedAt?.toIso8601String() case final value?)
        'updatedAt': value,
    };

const _$ResidenceTypeEnumMap = {
  ResidenceType.apartment: 'apartment',
  ResidenceType.studio: 'studio',
  ResidenceType.villa: 'villa',
  ResidenceType.room: 'room',
  ResidenceType.bungalow: 'bungalow',
  ResidenceType.penthouse: 'penthouse',
  ResidenceType.hotel: 'hotel',
  ResidenceType.luxury: 'luxury',
  ResidenceType.coworking: 'coworking',
  ResidenceType.student: 'student',
};
