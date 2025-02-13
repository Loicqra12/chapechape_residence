// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'residence_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Residence _$ResidenceFromJson(Map<String, dynamic> json) {
  return _Residence.fromJson(json);
}

/// @nodoc
mixin _$Residence {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  String get address => throw _privateConstructorUsedError;
  String get city => throw _privateConstructorUsedError;
  String get country => throw _privateConstructorUsedError;
  List<String> get images => throw _privateConstructorUsedError;
  int get bedrooms => throw _privateConstructorUsedError;
  int get bathrooms => throw _privateConstructorUsedError;
  double get surface => throw _privateConstructorUsedError;
  bool get isAvailable => throw _privateConstructorUsedError;
  Map<String, dynamic> get location => throw _privateConstructorUsedError;
  List<String> get amenities => throw _privateConstructorUsedError;
  List<String> get rules => throw _privateConstructorUsedError;
  double? get rating => throw _privateConstructorUsedError;
  int? get reviewCount => throw _privateConstructorUsedError;
  String? get ownerId => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Residence to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Residence
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ResidenceCopyWith<Residence> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ResidenceCopyWith<$Res> {
  factory $ResidenceCopyWith(Residence value, $Res Function(Residence) then) =
      _$ResidenceCopyWithImpl<$Res, Residence>;
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      double price,
      String address,
      String city,
      String country,
      List<String> images,
      int bedrooms,
      int bathrooms,
      double surface,
      bool isAvailable,
      Map<String, dynamic> location,
      List<String> amenities,
      List<String> rules,
      double? rating,
      int? reviewCount,
      String? ownerId,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class _$ResidenceCopyWithImpl<$Res, $Val extends Residence>
    implements $ResidenceCopyWith<$Res> {
  _$ResidenceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Residence
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? price = null,
    Object? address = null,
    Object? city = null,
    Object? country = null,
    Object? images = null,
    Object? bedrooms = null,
    Object? bathrooms = null,
    Object? surface = null,
    Object? isAvailable = null,
    Object? location = null,
    Object? amenities = null,
    Object? rules = null,
    Object? rating = freezed,
    Object? reviewCount = freezed,
    Object? ownerId = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      country: null == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String,
      images: null == images
          ? _value.images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      bedrooms: null == bedrooms
          ? _value.bedrooms
          : bedrooms // ignore: cast_nullable_to_non_nullable
              as int,
      bathrooms: null == bathrooms
          ? _value.bathrooms
          : bathrooms // ignore: cast_nullable_to_non_nullable
              as int,
      surface: null == surface
          ? _value.surface
          : surface // ignore: cast_nullable_to_non_nullable
              as double,
      isAvailable: null == isAvailable
          ? _value.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      location: null == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      amenities: null == amenities
          ? _value.amenities
          : amenities // ignore: cast_nullable_to_non_nullable
              as List<String>,
      rules: null == rules
          ? _value.rules
          : rules // ignore: cast_nullable_to_non_nullable
              as List<String>,
      rating: freezed == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double?,
      reviewCount: freezed == reviewCount
          ? _value.reviewCount
          : reviewCount // ignore: cast_nullable_to_non_nullable
              as int?,
      ownerId: freezed == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ResidenceImplCopyWith<$Res>
    implements $ResidenceCopyWith<$Res> {
  factory _$$ResidenceImplCopyWith(
          _$ResidenceImpl value, $Res Function(_$ResidenceImpl) then) =
      __$$ResidenceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      double price,
      String address,
      String city,
      String country,
      List<String> images,
      int bedrooms,
      int bathrooms,
      double surface,
      bool isAvailable,
      Map<String, dynamic> location,
      List<String> amenities,
      List<String> rules,
      double? rating,
      int? reviewCount,
      String? ownerId,
      DateTime? createdAt,
      DateTime? updatedAt});
}

/// @nodoc
class __$$ResidenceImplCopyWithImpl<$Res>
    extends _$ResidenceCopyWithImpl<$Res, _$ResidenceImpl>
    implements _$$ResidenceImplCopyWith<$Res> {
  __$$ResidenceImplCopyWithImpl(
      _$ResidenceImpl _value, $Res Function(_$ResidenceImpl) _then)
      : super(_value, _then);

  /// Create a copy of Residence
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? price = null,
    Object? address = null,
    Object? city = null,
    Object? country = null,
    Object? images = null,
    Object? bedrooms = null,
    Object? bathrooms = null,
    Object? surface = null,
    Object? isAvailable = null,
    Object? location = null,
    Object? amenities = null,
    Object? rules = null,
    Object? rating = freezed,
    Object? reviewCount = freezed,
    Object? ownerId = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$ResidenceImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      address: null == address
          ? _value.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      city: null == city
          ? _value.city
          : city // ignore: cast_nullable_to_non_nullable
              as String,
      country: null == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String,
      images: null == images
          ? _value._images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      bedrooms: null == bedrooms
          ? _value.bedrooms
          : bedrooms // ignore: cast_nullable_to_non_nullable
              as int,
      bathrooms: null == bathrooms
          ? _value.bathrooms
          : bathrooms // ignore: cast_nullable_to_non_nullable
              as int,
      surface: null == surface
          ? _value.surface
          : surface // ignore: cast_nullable_to_non_nullable
              as double,
      isAvailable: null == isAvailable
          ? _value.isAvailable
          : isAvailable // ignore: cast_nullable_to_non_nullable
              as bool,
      location: null == location
          ? _value._location
          : location // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      amenities: null == amenities
          ? _value._amenities
          : amenities // ignore: cast_nullable_to_non_nullable
              as List<String>,
      rules: null == rules
          ? _value._rules
          : rules // ignore: cast_nullable_to_non_nullable
              as List<String>,
      rating: freezed == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double?,
      reviewCount: freezed == reviewCount
          ? _value.reviewCount
          : reviewCount // ignore: cast_nullable_to_non_nullable
              as int?,
      ownerId: freezed == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ResidenceImpl implements _Residence {
  const _$ResidenceImpl(
      {required this.id,
      required this.name,
      required this.description,
      required this.price,
      required this.address,
      required this.city,
      required this.country,
      required final List<String> images,
      required this.bedrooms,
      required this.bathrooms,
      required this.surface,
      required this.isAvailable,
      required final Map<String, dynamic> location,
      final List<String> amenities = const [],
      final List<String> rules = const [],
      this.rating,
      this.reviewCount,
      this.ownerId,
      this.createdAt,
      this.updatedAt})
      : _images = images,
        _location = location,
        _amenities = amenities,
        _rules = rules;

  factory _$ResidenceImpl.fromJson(Map<String, dynamic> json) =>
      _$$ResidenceImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  @override
  final double price;
  @override
  final String address;
  @override
  final String city;
  @override
  final String country;
  final List<String> _images;
  @override
  List<String> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  @override
  final int bedrooms;
  @override
  final int bathrooms;
  @override
  final double surface;
  @override
  final bool isAvailable;
  final Map<String, dynamic> _location;
  @override
  Map<String, dynamic> get location {
    if (_location is EqualUnmodifiableMapView) return _location;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_location);
  }

  final List<String> _amenities;
  @override
  @JsonKey()
  List<String> get amenities {
    if (_amenities is EqualUnmodifiableListView) return _amenities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_amenities);
  }

  final List<String> _rules;
  @override
  @JsonKey()
  List<String> get rules {
    if (_rules is EqualUnmodifiableListView) return _rules;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rules);
  }

  @override
  final double? rating;
  @override
  final int? reviewCount;
  @override
  final String? ownerId;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'Residence(id: $id, name: $name, description: $description, price: $price, address: $address, city: $city, country: $country, images: $images, bedrooms: $bedrooms, bathrooms: $bathrooms, surface: $surface, isAvailable: $isAvailable, location: $location, amenities: $amenities, rules: $rules, rating: $rating, reviewCount: $reviewCount, ownerId: $ownerId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ResidenceImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.city, city) || other.city == city) &&
            (identical(other.country, country) || other.country == country) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            (identical(other.bedrooms, bedrooms) ||
                other.bedrooms == bedrooms) &&
            (identical(other.bathrooms, bathrooms) ||
                other.bathrooms == bathrooms) &&
            (identical(other.surface, surface) || other.surface == surface) &&
            (identical(other.isAvailable, isAvailable) ||
                other.isAvailable == isAvailable) &&
            const DeepCollectionEquality().equals(other._location, _location) &&
            const DeepCollectionEquality()
                .equals(other._amenities, _amenities) &&
            const DeepCollectionEquality().equals(other._rules, _rules) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.reviewCount, reviewCount) ||
                other.reviewCount == reviewCount) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        name,
        description,
        price,
        address,
        city,
        country,
        const DeepCollectionEquality().hash(_images),
        bedrooms,
        bathrooms,
        surface,
        isAvailable,
        const DeepCollectionEquality().hash(_location),
        const DeepCollectionEquality().hash(_amenities),
        const DeepCollectionEquality().hash(_rules),
        rating,
        reviewCount,
        ownerId,
        createdAt,
        updatedAt
      ]);

  /// Create a copy of Residence
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ResidenceImplCopyWith<_$ResidenceImpl> get copyWith =>
      __$$ResidenceImplCopyWithImpl<_$ResidenceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ResidenceImplToJson(
      this,
    );
  }
}

abstract class _Residence implements Residence {
  const factory _Residence(
      {required final String id,
      required final String name,
      required final String description,
      required final double price,
      required final String address,
      required final String city,
      required final String country,
      required final List<String> images,
      required final int bedrooms,
      required final int bathrooms,
      required final double surface,
      required final bool isAvailable,
      required final Map<String, dynamic> location,
      final List<String> amenities,
      final List<String> rules,
      final double? rating,
      final int? reviewCount,
      final String? ownerId,
      final DateTime? createdAt,
      final DateTime? updatedAt}) = _$ResidenceImpl;

  factory _Residence.fromJson(Map<String, dynamic> json) =
      _$ResidenceImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  double get price;
  @override
  String get address;
  @override
  String get city;
  @override
  String get country;
  @override
  List<String> get images;
  @override
  int get bedrooms;
  @override
  int get bathrooms;
  @override
  double get surface;
  @override
  bool get isAvailable;
  @override
  Map<String, dynamic> get location;
  @override
  List<String> get amenities;
  @override
  List<String> get rules;
  @override
  double? get rating;
  @override
  int? get reviewCount;
  @override
  String? get ownerId;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of Residence
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ResidenceImplCopyWith<_$ResidenceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
