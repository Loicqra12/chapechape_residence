// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'testimonial_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TestimonialModel _$TestimonialModelFromJson(Map<String, dynamic> json) {
  return _TestimonialModel.fromJson(json);
}

/// @nodoc
mixin _$TestimonialModel {
  String? get id => throw _privateConstructorUsedError;
  String? get userName => throw _privateConstructorUsedError;
  String? get userAvatar => throw _privateConstructorUsedError;
  String? get residenceName => throw _privateConstructorUsedError;
  double? get rating => throw _privateConstructorUsedError;
  String? get content => throw _privateConstructorUsedError;
  DateTime? get date => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TestimonialModelCopyWith<TestimonialModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TestimonialModelCopyWith<$Res> {
  factory $TestimonialModelCopyWith(
          TestimonialModel value, $Res Function(TestimonialModel) then) =
      _$TestimonialModelCopyWithImpl<$Res, TestimonialModel>;
  @useResult
  $Res call(
      {String? id,
      String? userName,
      String? userAvatar,
      String? residenceName,
      double? rating,
      String? content,
      DateTime? date});
}

/// @nodoc
class _$TestimonialModelCopyWithImpl<$Res, $Val extends TestimonialModel>
    implements $TestimonialModelCopyWith<$Res> {
  _$TestimonialModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? userName = freezed,
    Object? userAvatar = freezed,
    Object? residenceName = freezed,
    Object? rating = freezed,
    Object? content = freezed,
    Object? date = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      userName: freezed == userName
          ? _value.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String?,
      userAvatar: freezed == userAvatar
          ? _value.userAvatar
          : userAvatar // ignore: cast_nullable_to_non_nullable
              as String?,
      residenceName: freezed == residenceName
          ? _value.residenceName
          : residenceName // ignore: cast_nullable_to_non_nullable
              as String?,
      rating: freezed == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double?,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String?,
      date: freezed == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TestimonialModelImplCopyWith<$Res>
    implements $TestimonialModelCopyWith<$Res> {
  factory _$$TestimonialModelImplCopyWith(_$TestimonialModelImpl value,
          $Res Function(_$TestimonialModelImpl) then) =
      __$$TestimonialModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? id,
      String? userName,
      String? userAvatar,
      String? residenceName,
      double? rating,
      String? content,
      DateTime? date});
}

/// @nodoc
class __$$TestimonialModelImplCopyWithImpl<$Res>
    extends _$TestimonialModelCopyWithImpl<$Res, _$TestimonialModelImpl>
    implements _$$TestimonialModelImplCopyWith<$Res> {
  __$$TestimonialModelImplCopyWithImpl(_$TestimonialModelImpl _value,
      $Res Function(_$TestimonialModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? userName = freezed,
    Object? userAvatar = freezed,
    Object? residenceName = freezed,
    Object? rating = freezed,
    Object? content = freezed,
    Object? date = freezed,
  }) {
    return _then(_$TestimonialModelImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      userName: freezed == userName
          ? _value.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String?,
      userAvatar: freezed == userAvatar
          ? _value.userAvatar
          : userAvatar // ignore: cast_nullable_to_non_nullable
              as String?,
      residenceName: freezed == residenceName
          ? _value.residenceName
          : residenceName // ignore: cast_nullable_to_non_nullable
              as String?,
      rating: freezed == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double?,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String?,
      date: freezed == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TestimonialModelImpl
    with DiagnosticableTreeMixin
    implements _TestimonialModel {
  const _$TestimonialModelImpl(
      {this.id,
      this.userName,
      this.userAvatar,
      this.residenceName,
      this.rating,
      this.content,
      this.date});

  factory _$TestimonialModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TestimonialModelImplFromJson(json);

  @override
  final String? id;
  @override
  final String? userName;
  @override
  final String? userAvatar;
  @override
  final String? residenceName;
  @override
  final double? rating;
  @override
  final String? content;
  @override
  final DateTime? date;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'TestimonialModel(id: $id, userName: $userName, userAvatar: $userAvatar, residenceName: $residenceName, rating: $rating, content: $content, date: $date)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'TestimonialModel'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('userName', userName))
      ..add(DiagnosticsProperty('userAvatar', userAvatar))
      ..add(DiagnosticsProperty('residenceName', residenceName))
      ..add(DiagnosticsProperty('rating', rating))
      ..add(DiagnosticsProperty('content', content))
      ..add(DiagnosticsProperty('date', date));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TestimonialModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.userAvatar, userAvatar) ||
                other.userAvatar == userAvatar) &&
            (identical(other.residenceName, residenceName) ||
                other.residenceName == residenceName) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.date, date) || other.date == date));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, userName, userAvatar,
      residenceName, rating, content, date);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TestimonialModelImplCopyWith<_$TestimonialModelImpl> get copyWith =>
      __$$TestimonialModelImplCopyWithImpl<_$TestimonialModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TestimonialModelImplToJson(
      this,
    );
  }
}

abstract class _TestimonialModel implements TestimonialModel {
  const factory _TestimonialModel(
      {final String? id,
      final String? userName,
      final String? userAvatar,
      final String? residenceName,
      final double? rating,
      final String? content,
      final DateTime? date}) = _$TestimonialModelImpl;

  factory _TestimonialModel.fromJson(Map<String, dynamic> json) =
      _$TestimonialModelImpl.fromJson;

  @override
  String? get id;
  @override
  String? get userName;
  @override
  String? get userAvatar;
  @override
  String? get residenceName;
  @override
  double? get rating;
  @override
  String? get content;
  @override
  DateTime? get date;
  @override
  @JsonKey(ignore: true)
  _$$TestimonialModelImplCopyWith<_$TestimonialModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
