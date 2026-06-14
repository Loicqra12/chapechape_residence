// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'promotion_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Promotion _$PromotionFromJson(Map<String, dynamic> json) {
  return _Promotion.fromJson(json);
}

/// @nodoc
mixin _$Promotion {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  double get discountPercentage => throw _privateConstructorUsedError;
  String? get discountCode => throw _privateConstructorUsedError;
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime get endDate => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  String get residenceId => throw _privateConstructorUsedError;
  Residence? get residence => throw _privateConstructorUsedError;
  String? get badge => throw _privateConstructorUsedError;
  bool get isExclusive => throw _privateConstructorUsedError;
  PromotionType get type => throw _privateConstructorUsedError;
  String? get termsAndConditions => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PromotionCopyWith<Promotion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PromotionCopyWith<$Res> {
  factory $PromotionCopyWith(Promotion value, $Res Function(Promotion) then) =
      _$PromotionCopyWithImpl<$Res, Promotion>;
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      double discountPercentage,
      String? discountCode,
      DateTime startDate,
      DateTime endDate,
      String imageUrl,
      String residenceId,
      Residence? residence,
      String? badge,
      bool isExclusive,
      PromotionType type,
      String? termsAndConditions});
}

/// @nodoc
class _$PromotionCopyWithImpl<$Res, $Val extends Promotion>
    implements $PromotionCopyWith<$Res> {
  _$PromotionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? discountPercentage = null,
    Object? discountCode = freezed,
    Object? startDate = null,
    Object? endDate = null,
    Object? imageUrl = null,
    Object? residenceId = null,
    Object? residence = freezed,
    Object? badge = freezed,
    Object? isExclusive = null,
    Object? type = null,
    Object? termsAndConditions = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      discountPercentage: null == discountPercentage
          ? _value.discountPercentage
          : discountPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      discountCode: freezed == discountCode
          ? _value.discountCode
          : discountCode // ignore: cast_nullable_to_non_nullable
              as String?,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: null == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      residenceId: null == residenceId
          ? _value.residenceId
          : residenceId // ignore: cast_nullable_to_non_nullable
              as String,
      residence: freezed == residence
          ? _value.residence
          : residence // ignore: cast_nullable_to_non_nullable
              as Residence?,
      badge: freezed == badge
          ? _value.badge
          : badge // ignore: cast_nullable_to_non_nullable
              as String?,
      isExclusive: null == isExclusive
          ? _value.isExclusive
          : isExclusive // ignore: cast_nullable_to_non_nullable
              as bool,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as PromotionType,
      termsAndConditions: freezed == termsAndConditions
          ? _value.termsAndConditions
          : termsAndConditions // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PromotionImplCopyWith<$Res>
    implements $PromotionCopyWith<$Res> {
  factory _$$PromotionImplCopyWith(
          _$PromotionImpl value, $Res Function(_$PromotionImpl) then) =
      __$$PromotionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String description,
      double discountPercentage,
      String? discountCode,
      DateTime startDate,
      DateTime endDate,
      String imageUrl,
      String residenceId,
      Residence? residence,
      String? badge,
      bool isExclusive,
      PromotionType type,
      String? termsAndConditions});
}

/// @nodoc
class __$$PromotionImplCopyWithImpl<$Res>
    extends _$PromotionCopyWithImpl<$Res, _$PromotionImpl>
    implements _$$PromotionImplCopyWith<$Res> {
  __$$PromotionImplCopyWithImpl(
      _$PromotionImpl _value, $Res Function(_$PromotionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = null,
    Object? discountPercentage = null,
    Object? discountCode = freezed,
    Object? startDate = null,
    Object? endDate = null,
    Object? imageUrl = null,
    Object? residenceId = null,
    Object? residence = freezed,
    Object? badge = freezed,
    Object? isExclusive = null,
    Object? type = null,
    Object? termsAndConditions = freezed,
  }) {
    return _then(_$PromotionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      discountPercentage: null == discountPercentage
          ? _value.discountPercentage
          : discountPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      discountCode: freezed == discountCode
          ? _value.discountCode
          : discountCode // ignore: cast_nullable_to_non_nullable
              as String?,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endDate: null == endDate
          ? _value.endDate
          : endDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      residenceId: null == residenceId
          ? _value.residenceId
          : residenceId // ignore: cast_nullable_to_non_nullable
              as String,
      residence: freezed == residence
          ? _value.residence
          : residence // ignore: cast_nullable_to_non_nullable
              as Residence?,
      badge: freezed == badge
          ? _value.badge
          : badge // ignore: cast_nullable_to_non_nullable
              as String?,
      isExclusive: null == isExclusive
          ? _value.isExclusive
          : isExclusive // ignore: cast_nullable_to_non_nullable
              as bool,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as PromotionType,
      termsAndConditions: freezed == termsAndConditions
          ? _value.termsAndConditions
          : termsAndConditions // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PromotionImpl with DiagnosticableTreeMixin implements _Promotion {
  const _$PromotionImpl(
      {required this.id,
      required this.title,
      required this.description,
      required this.discountPercentage,
      this.discountCode,
      required this.startDate,
      required this.endDate,
      required this.imageUrl,
      required this.residenceId,
      this.residence,
      this.badge,
      this.isExclusive = false,
      this.type = PromotionType.discount,
      this.termsAndConditions});

  factory _$PromotionImpl.fromJson(Map<String, dynamic> json) =>
      _$$PromotionImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String description;
  @override
  final double discountPercentage;
  @override
  final String? discountCode;
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;
  @override
  final String imageUrl;
  @override
  final String residenceId;
  @override
  final Residence? residence;
  @override
  final String? badge;
  @override
  @JsonKey()
  final bool isExclusive;
  @override
  @JsonKey()
  final PromotionType type;
  @override
  final String? termsAndConditions;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Promotion(id: $id, title: $title, description: $description, discountPercentage: $discountPercentage, discountCode: $discountCode, startDate: $startDate, endDate: $endDate, imageUrl: $imageUrl, residenceId: $residenceId, residence: $residence, badge: $badge, isExclusive: $isExclusive, type: $type, termsAndConditions: $termsAndConditions)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'Promotion'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('description', description))
      ..add(DiagnosticsProperty('discountPercentage', discountPercentage))
      ..add(DiagnosticsProperty('discountCode', discountCode))
      ..add(DiagnosticsProperty('startDate', startDate))
      ..add(DiagnosticsProperty('endDate', endDate))
      ..add(DiagnosticsProperty('imageUrl', imageUrl))
      ..add(DiagnosticsProperty('residenceId', residenceId))
      ..add(DiagnosticsProperty('residence', residence))
      ..add(DiagnosticsProperty('badge', badge))
      ..add(DiagnosticsProperty('isExclusive', isExclusive))
      ..add(DiagnosticsProperty('type', type))
      ..add(DiagnosticsProperty('termsAndConditions', termsAndConditions));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PromotionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.discountPercentage, discountPercentage) ||
                other.discountPercentage == discountPercentage) &&
            (identical(other.discountCode, discountCode) ||
                other.discountCode == discountCode) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.residenceId, residenceId) ||
                other.residenceId == residenceId) &&
            (identical(other.residence, residence) ||
                other.residence == residence) &&
            (identical(other.badge, badge) || other.badge == badge) &&
            (identical(other.isExclusive, isExclusive) ||
                other.isExclusive == isExclusive) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.termsAndConditions, termsAndConditions) ||
                other.termsAndConditions == termsAndConditions));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      description,
      discountPercentage,
      discountCode,
      startDate,
      endDate,
      imageUrl,
      residenceId,
      residence,
      badge,
      isExclusive,
      type,
      termsAndConditions);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PromotionImplCopyWith<_$PromotionImpl> get copyWith =>
      __$$PromotionImplCopyWithImpl<_$PromotionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PromotionImplToJson(
      this,
    );
  }
}

abstract class _Promotion implements Promotion {
  const factory _Promotion(
      {required final String id,
      required final String title,
      required final String description,
      required final double discountPercentage,
      final String? discountCode,
      required final DateTime startDate,
      required final DateTime endDate,
      required final String imageUrl,
      required final String residenceId,
      final Residence? residence,
      final String? badge,
      final bool isExclusive,
      final PromotionType type,
      final String? termsAndConditions}) = _$PromotionImpl;

  factory _Promotion.fromJson(Map<String, dynamic> json) =
      _$PromotionImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get description;
  @override
  double get discountPercentage;
  @override
  String? get discountCode;
  @override
  DateTime get startDate;
  @override
  DateTime get endDate;
  @override
  String get imageUrl;
  @override
  String get residenceId;
  @override
  Residence? get residence;
  @override
  String? get badge;
  @override
  bool get isExclusive;
  @override
  PromotionType get type;
  @override
  String? get termsAndConditions;
  @override
  @JsonKey(ignore: true)
  _$$PromotionImplCopyWith<_$PromotionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
