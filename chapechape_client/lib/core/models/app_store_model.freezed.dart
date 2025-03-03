// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_store_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AppStoreModel _$AppStoreModelFromJson(Map<String, dynamic> json) {
  return _AppStoreModel.fromJson(json);
}

/// @nodoc
mixin _$AppStoreModel {
  String get name => throw _privateConstructorUsedError;
  String get logoUrl => throw _privateConstructorUsedError;
  String get downloadUrl => throw _privateConstructorUsedError;
  String? get qrCodeUrl => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  /// Serializes this AppStoreModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppStoreModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppStoreModelCopyWith<AppStoreModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppStoreModelCopyWith<$Res> {
  factory $AppStoreModelCopyWith(
          AppStoreModel value, $Res Function(AppStoreModel) then) =
      _$AppStoreModelCopyWithImpl<$Res, AppStoreModel>;
  @useResult
  $Res call(
      {String name,
      String logoUrl,
      String downloadUrl,
      String? qrCodeUrl,
      String? description});
}

/// @nodoc
class _$AppStoreModelCopyWithImpl<$Res, $Val extends AppStoreModel>
    implements $AppStoreModelCopyWith<$Res> {
  _$AppStoreModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppStoreModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? logoUrl = null,
    Object? downloadUrl = null,
    Object? qrCodeUrl = freezed,
    Object? description = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      logoUrl: null == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String,
      downloadUrl: null == downloadUrl
          ? _value.downloadUrl
          : downloadUrl // ignore: cast_nullable_to_non_nullable
              as String,
      qrCodeUrl: freezed == qrCodeUrl
          ? _value.qrCodeUrl
          : qrCodeUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppStoreModelImplCopyWith<$Res>
    implements $AppStoreModelCopyWith<$Res> {
  factory _$$AppStoreModelImplCopyWith(
          _$AppStoreModelImpl value, $Res Function(_$AppStoreModelImpl) then) =
      __$$AppStoreModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String logoUrl,
      String downloadUrl,
      String? qrCodeUrl,
      String? description});
}

/// @nodoc
class __$$AppStoreModelImplCopyWithImpl<$Res>
    extends _$AppStoreModelCopyWithImpl<$Res, _$AppStoreModelImpl>
    implements _$$AppStoreModelImplCopyWith<$Res> {
  __$$AppStoreModelImplCopyWithImpl(
      _$AppStoreModelImpl _value, $Res Function(_$AppStoreModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppStoreModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? logoUrl = null,
    Object? downloadUrl = null,
    Object? qrCodeUrl = freezed,
    Object? description = freezed,
  }) {
    return _then(_$AppStoreModelImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      logoUrl: null == logoUrl
          ? _value.logoUrl
          : logoUrl // ignore: cast_nullable_to_non_nullable
              as String,
      downloadUrl: null == downloadUrl
          ? _value.downloadUrl
          : downloadUrl // ignore: cast_nullable_to_non_nullable
              as String,
      qrCodeUrl: freezed == qrCodeUrl
          ? _value.qrCodeUrl
          : qrCodeUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AppStoreModelImpl
    with DiagnosticableTreeMixin
    implements _AppStoreModel {
  const _$AppStoreModelImpl(
      {required this.name,
      required this.logoUrl,
      required this.downloadUrl,
      this.qrCodeUrl,
      this.description});

  factory _$AppStoreModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppStoreModelImplFromJson(json);

  @override
  final String name;
  @override
  final String logoUrl;
  @override
  final String downloadUrl;
  @override
  final String? qrCodeUrl;
  @override
  final String? description;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'AppStoreModel(name: $name, logoUrl: $logoUrl, downloadUrl: $downloadUrl, qrCodeUrl: $qrCodeUrl, description: $description)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'AppStoreModel'))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('logoUrl', logoUrl))
      ..add(DiagnosticsProperty('downloadUrl', downloadUrl))
      ..add(DiagnosticsProperty('qrCodeUrl', qrCodeUrl))
      ..add(DiagnosticsProperty('description', description));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppStoreModelImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl) &&
            (identical(other.downloadUrl, downloadUrl) ||
                other.downloadUrl == downloadUrl) &&
            (identical(other.qrCodeUrl, qrCodeUrl) ||
                other.qrCodeUrl == qrCodeUrl) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, name, logoUrl, downloadUrl, qrCodeUrl, description);

  /// Create a copy of AppStoreModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppStoreModelImplCopyWith<_$AppStoreModelImpl> get copyWith =>
      __$$AppStoreModelImplCopyWithImpl<_$AppStoreModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppStoreModelImplToJson(
      this,
    );
  }
}

abstract class _AppStoreModel implements AppStoreModel {
  const factory _AppStoreModel(
      {required final String name,
      required final String logoUrl,
      required final String downloadUrl,
      final String? qrCodeUrl,
      final String? description}) = _$AppStoreModelImpl;

  factory _AppStoreModel.fromJson(Map<String, dynamic> json) =
      _$AppStoreModelImpl.fromJson;

  @override
  String get name;
  @override
  String get logoUrl;
  @override
  String get downloadUrl;
  @override
  String? get qrCodeUrl;
  @override
  String? get description;

  /// Create a copy of AppStoreModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppStoreModelImplCopyWith<_$AppStoreModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
