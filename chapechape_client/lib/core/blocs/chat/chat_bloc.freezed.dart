// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ChatEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadConversations,
    required TResult Function(
            String userId, String? residenceId, String? reservationId)
        createConversation,
    required TResult Function(String conversationId, String content)
        sendMessage,
    required TResult Function(
            String conversationId, String filePath, String? type)
        sendFile,
    required TResult Function(String conversationId, String imagePath)
        sendImage,
    required TResult Function(String conversationId) loadMessages,
    required TResult Function(String messageId, String conversationId)
        markAsRead,
    required TResult Function(String conversationId) markAllAsRead,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadConversations,
    TResult? Function(
            String userId, String? residenceId, String? reservationId)?
        createConversation,
    TResult? Function(String conversationId, String content)? sendMessage,
    TResult? Function(String conversationId, String filePath, String? type)?
        sendFile,
    TResult? Function(String conversationId, String imagePath)? sendImage,
    TResult? Function(String conversationId)? loadMessages,
    TResult? Function(String messageId, String conversationId)? markAsRead,
    TResult? Function(String conversationId)? markAllAsRead,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadConversations,
    TResult Function(String userId, String? residenceId, String? reservationId)?
        createConversation,
    TResult Function(String conversationId, String content)? sendMessage,
    TResult Function(String conversationId, String filePath, String? type)?
        sendFile,
    TResult Function(String conversationId, String imagePath)? sendImage,
    TResult Function(String conversationId)? loadMessages,
    TResult Function(String messageId, String conversationId)? markAsRead,
    TResult Function(String conversationId)? markAllAsRead,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadConversations value) loadConversations,
    required TResult Function(CreateConversation value) createConversation,
    required TResult Function(SendMessage value) sendMessage,
    required TResult Function(SendFile value) sendFile,
    required TResult Function(SendImage value) sendImage,
    required TResult Function(LoadMessages value) loadMessages,
    required TResult Function(MarkAsRead value) markAsRead,
    required TResult Function(MarkAllAsRead value) markAllAsRead,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadConversations value)? loadConversations,
    TResult? Function(CreateConversation value)? createConversation,
    TResult? Function(SendMessage value)? sendMessage,
    TResult? Function(SendFile value)? sendFile,
    TResult? Function(SendImage value)? sendImage,
    TResult? Function(LoadMessages value)? loadMessages,
    TResult? Function(MarkAsRead value)? markAsRead,
    TResult? Function(MarkAllAsRead value)? markAllAsRead,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadConversations value)? loadConversations,
    TResult Function(CreateConversation value)? createConversation,
    TResult Function(SendMessage value)? sendMessage,
    TResult Function(SendFile value)? sendFile,
    TResult Function(SendImage value)? sendImage,
    TResult Function(LoadMessages value)? loadMessages,
    TResult Function(MarkAsRead value)? markAsRead,
    TResult Function(MarkAllAsRead value)? markAllAsRead,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatEventCopyWith<$Res> {
  factory $ChatEventCopyWith(ChatEvent value, $Res Function(ChatEvent) then) =
      _$ChatEventCopyWithImpl<$Res, ChatEvent>;
}

/// @nodoc
class _$ChatEventCopyWithImpl<$Res, $Val extends ChatEvent>
    implements $ChatEventCopyWith<$Res> {
  _$ChatEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$LoadConversationsImplCopyWith<$Res> {
  factory _$$LoadConversationsImplCopyWith(_$LoadConversationsImpl value,
          $Res Function(_$LoadConversationsImpl) then) =
      __$$LoadConversationsImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadConversationsImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$LoadConversationsImpl>
    implements _$$LoadConversationsImplCopyWith<$Res> {
  __$$LoadConversationsImplCopyWithImpl(_$LoadConversationsImpl _value,
      $Res Function(_$LoadConversationsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadConversationsImpl implements LoadConversations {
  const _$LoadConversationsImpl();

  @override
  String toString() {
    return 'ChatEvent.loadConversations()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadConversationsImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadConversations,
    required TResult Function(
            String userId, String? residenceId, String? reservationId)
        createConversation,
    required TResult Function(String conversationId, String content)
        sendMessage,
    required TResult Function(
            String conversationId, String filePath, String? type)
        sendFile,
    required TResult Function(String conversationId, String imagePath)
        sendImage,
    required TResult Function(String conversationId) loadMessages,
    required TResult Function(String messageId, String conversationId)
        markAsRead,
    required TResult Function(String conversationId) markAllAsRead,
  }) {
    return loadConversations();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadConversations,
    TResult? Function(
            String userId, String? residenceId, String? reservationId)?
        createConversation,
    TResult? Function(String conversationId, String content)? sendMessage,
    TResult? Function(String conversationId, String filePath, String? type)?
        sendFile,
    TResult? Function(String conversationId, String imagePath)? sendImage,
    TResult? Function(String conversationId)? loadMessages,
    TResult? Function(String messageId, String conversationId)? markAsRead,
    TResult? Function(String conversationId)? markAllAsRead,
  }) {
    return loadConversations?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadConversations,
    TResult Function(String userId, String? residenceId, String? reservationId)?
        createConversation,
    TResult Function(String conversationId, String content)? sendMessage,
    TResult Function(String conversationId, String filePath, String? type)?
        sendFile,
    TResult Function(String conversationId, String imagePath)? sendImage,
    TResult Function(String conversationId)? loadMessages,
    TResult Function(String messageId, String conversationId)? markAsRead,
    TResult Function(String conversationId)? markAllAsRead,
    required TResult orElse(),
  }) {
    if (loadConversations != null) {
      return loadConversations();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadConversations value) loadConversations,
    required TResult Function(CreateConversation value) createConversation,
    required TResult Function(SendMessage value) sendMessage,
    required TResult Function(SendFile value) sendFile,
    required TResult Function(SendImage value) sendImage,
    required TResult Function(LoadMessages value) loadMessages,
    required TResult Function(MarkAsRead value) markAsRead,
    required TResult Function(MarkAllAsRead value) markAllAsRead,
  }) {
    return loadConversations(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadConversations value)? loadConversations,
    TResult? Function(CreateConversation value)? createConversation,
    TResult? Function(SendMessage value)? sendMessage,
    TResult? Function(SendFile value)? sendFile,
    TResult? Function(SendImage value)? sendImage,
    TResult? Function(LoadMessages value)? loadMessages,
    TResult? Function(MarkAsRead value)? markAsRead,
    TResult? Function(MarkAllAsRead value)? markAllAsRead,
  }) {
    return loadConversations?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadConversations value)? loadConversations,
    TResult Function(CreateConversation value)? createConversation,
    TResult Function(SendMessage value)? sendMessage,
    TResult Function(SendFile value)? sendFile,
    TResult Function(SendImage value)? sendImage,
    TResult Function(LoadMessages value)? loadMessages,
    TResult Function(MarkAsRead value)? markAsRead,
    TResult Function(MarkAllAsRead value)? markAllAsRead,
    required TResult orElse(),
  }) {
    if (loadConversations != null) {
      return loadConversations(this);
    }
    return orElse();
  }
}

abstract class LoadConversations implements ChatEvent {
  const factory LoadConversations() = _$LoadConversationsImpl;
}

/// @nodoc
abstract class _$$CreateConversationImplCopyWith<$Res> {
  factory _$$CreateConversationImplCopyWith(_$CreateConversationImpl value,
          $Res Function(_$CreateConversationImpl) then) =
      __$$CreateConversationImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String userId, String? residenceId, String? reservationId});
}

/// @nodoc
class __$$CreateConversationImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$CreateConversationImpl>
    implements _$$CreateConversationImplCopyWith<$Res> {
  __$$CreateConversationImplCopyWithImpl(_$CreateConversationImpl _value,
      $Res Function(_$CreateConversationImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? residenceId = freezed,
    Object? reservationId = freezed,
  }) {
    return _then(_$CreateConversationImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      residenceId: freezed == residenceId
          ? _value.residenceId
          : residenceId // ignore: cast_nullable_to_non_nullable
              as String?,
      reservationId: freezed == reservationId
          ? _value.reservationId
          : reservationId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$CreateConversationImpl implements CreateConversation {
  const _$CreateConversationImpl(
      {required this.userId, this.residenceId, this.reservationId});

  @override
  final String userId;
  @override
  final String? residenceId;
  @override
  final String? reservationId;

  @override
  String toString() {
    return 'ChatEvent.createConversation(userId: $userId, residenceId: $residenceId, reservationId: $reservationId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreateConversationImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.residenceId, residenceId) ||
                other.residenceId == residenceId) &&
            (identical(other.reservationId, reservationId) ||
                other.reservationId == reservationId));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, userId, residenceId, reservationId);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreateConversationImplCopyWith<_$CreateConversationImpl> get copyWith =>
      __$$CreateConversationImplCopyWithImpl<_$CreateConversationImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadConversations,
    required TResult Function(
            String userId, String? residenceId, String? reservationId)
        createConversation,
    required TResult Function(String conversationId, String content)
        sendMessage,
    required TResult Function(
            String conversationId, String filePath, String? type)
        sendFile,
    required TResult Function(String conversationId, String imagePath)
        sendImage,
    required TResult Function(String conversationId) loadMessages,
    required TResult Function(String messageId, String conversationId)
        markAsRead,
    required TResult Function(String conversationId) markAllAsRead,
  }) {
    return createConversation(userId, residenceId, reservationId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadConversations,
    TResult? Function(
            String userId, String? residenceId, String? reservationId)?
        createConversation,
    TResult? Function(String conversationId, String content)? sendMessage,
    TResult? Function(String conversationId, String filePath, String? type)?
        sendFile,
    TResult? Function(String conversationId, String imagePath)? sendImage,
    TResult? Function(String conversationId)? loadMessages,
    TResult? Function(String messageId, String conversationId)? markAsRead,
    TResult? Function(String conversationId)? markAllAsRead,
  }) {
    return createConversation?.call(userId, residenceId, reservationId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadConversations,
    TResult Function(String userId, String? residenceId, String? reservationId)?
        createConversation,
    TResult Function(String conversationId, String content)? sendMessage,
    TResult Function(String conversationId, String filePath, String? type)?
        sendFile,
    TResult Function(String conversationId, String imagePath)? sendImage,
    TResult Function(String conversationId)? loadMessages,
    TResult Function(String messageId, String conversationId)? markAsRead,
    TResult Function(String conversationId)? markAllAsRead,
    required TResult orElse(),
  }) {
    if (createConversation != null) {
      return createConversation(userId, residenceId, reservationId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadConversations value) loadConversations,
    required TResult Function(CreateConversation value) createConversation,
    required TResult Function(SendMessage value) sendMessage,
    required TResult Function(SendFile value) sendFile,
    required TResult Function(SendImage value) sendImage,
    required TResult Function(LoadMessages value) loadMessages,
    required TResult Function(MarkAsRead value) markAsRead,
    required TResult Function(MarkAllAsRead value) markAllAsRead,
  }) {
    return createConversation(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadConversations value)? loadConversations,
    TResult? Function(CreateConversation value)? createConversation,
    TResult? Function(SendMessage value)? sendMessage,
    TResult? Function(SendFile value)? sendFile,
    TResult? Function(SendImage value)? sendImage,
    TResult? Function(LoadMessages value)? loadMessages,
    TResult? Function(MarkAsRead value)? markAsRead,
    TResult? Function(MarkAllAsRead value)? markAllAsRead,
  }) {
    return createConversation?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadConversations value)? loadConversations,
    TResult Function(CreateConversation value)? createConversation,
    TResult Function(SendMessage value)? sendMessage,
    TResult Function(SendFile value)? sendFile,
    TResult Function(SendImage value)? sendImage,
    TResult Function(LoadMessages value)? loadMessages,
    TResult Function(MarkAsRead value)? markAsRead,
    TResult Function(MarkAllAsRead value)? markAllAsRead,
    required TResult orElse(),
  }) {
    if (createConversation != null) {
      return createConversation(this);
    }
    return orElse();
  }
}

abstract class CreateConversation implements ChatEvent {
  const factory CreateConversation(
      {required final String userId,
      final String? residenceId,
      final String? reservationId}) = _$CreateConversationImpl;

  String get userId;
  String? get residenceId;
  String? get reservationId;

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreateConversationImplCopyWith<_$CreateConversationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SendMessageImplCopyWith<$Res> {
  factory _$$SendMessageImplCopyWith(
          _$SendMessageImpl value, $Res Function(_$SendMessageImpl) then) =
      __$$SendMessageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String conversationId, String content});
}

/// @nodoc
class __$$SendMessageImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$SendMessageImpl>
    implements _$$SendMessageImplCopyWith<$Res> {
  __$$SendMessageImplCopyWithImpl(
      _$SendMessageImpl _value, $Res Function(_$SendMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? conversationId = null,
    Object? content = null,
  }) {
    return _then(_$SendMessageImpl(
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SendMessageImpl implements SendMessage {
  const _$SendMessageImpl(
      {required this.conversationId, required this.content});

  @override
  final String conversationId;
  @override
  final String content;

  @override
  String toString() {
    return 'ChatEvent.sendMessage(conversationId: $conversationId, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SendMessageImpl &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            (identical(other.content, content) || other.content == content));
  }

  @override
  int get hashCode => Object.hash(runtimeType, conversationId, content);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SendMessageImplCopyWith<_$SendMessageImpl> get copyWith =>
      __$$SendMessageImplCopyWithImpl<_$SendMessageImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadConversations,
    required TResult Function(
            String userId, String? residenceId, String? reservationId)
        createConversation,
    required TResult Function(String conversationId, String content)
        sendMessage,
    required TResult Function(
            String conversationId, String filePath, String? type)
        sendFile,
    required TResult Function(String conversationId, String imagePath)
        sendImage,
    required TResult Function(String conversationId) loadMessages,
    required TResult Function(String messageId, String conversationId)
        markAsRead,
    required TResult Function(String conversationId) markAllAsRead,
  }) {
    return sendMessage(conversationId, content);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadConversations,
    TResult? Function(
            String userId, String? residenceId, String? reservationId)?
        createConversation,
    TResult? Function(String conversationId, String content)? sendMessage,
    TResult? Function(String conversationId, String filePath, String? type)?
        sendFile,
    TResult? Function(String conversationId, String imagePath)? sendImage,
    TResult? Function(String conversationId)? loadMessages,
    TResult? Function(String messageId, String conversationId)? markAsRead,
    TResult? Function(String conversationId)? markAllAsRead,
  }) {
    return sendMessage?.call(conversationId, content);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadConversations,
    TResult Function(String userId, String? residenceId, String? reservationId)?
        createConversation,
    TResult Function(String conversationId, String content)? sendMessage,
    TResult Function(String conversationId, String filePath, String? type)?
        sendFile,
    TResult Function(String conversationId, String imagePath)? sendImage,
    TResult Function(String conversationId)? loadMessages,
    TResult Function(String messageId, String conversationId)? markAsRead,
    TResult Function(String conversationId)? markAllAsRead,
    required TResult orElse(),
  }) {
    if (sendMessage != null) {
      return sendMessage(conversationId, content);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadConversations value) loadConversations,
    required TResult Function(CreateConversation value) createConversation,
    required TResult Function(SendMessage value) sendMessage,
    required TResult Function(SendFile value) sendFile,
    required TResult Function(SendImage value) sendImage,
    required TResult Function(LoadMessages value) loadMessages,
    required TResult Function(MarkAsRead value) markAsRead,
    required TResult Function(MarkAllAsRead value) markAllAsRead,
  }) {
    return sendMessage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadConversations value)? loadConversations,
    TResult? Function(CreateConversation value)? createConversation,
    TResult? Function(SendMessage value)? sendMessage,
    TResult? Function(SendFile value)? sendFile,
    TResult? Function(SendImage value)? sendImage,
    TResult? Function(LoadMessages value)? loadMessages,
    TResult? Function(MarkAsRead value)? markAsRead,
    TResult? Function(MarkAllAsRead value)? markAllAsRead,
  }) {
    return sendMessage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadConversations value)? loadConversations,
    TResult Function(CreateConversation value)? createConversation,
    TResult Function(SendMessage value)? sendMessage,
    TResult Function(SendFile value)? sendFile,
    TResult Function(SendImage value)? sendImage,
    TResult Function(LoadMessages value)? loadMessages,
    TResult Function(MarkAsRead value)? markAsRead,
    TResult Function(MarkAllAsRead value)? markAllAsRead,
    required TResult orElse(),
  }) {
    if (sendMessage != null) {
      return sendMessage(this);
    }
    return orElse();
  }
}

abstract class SendMessage implements ChatEvent {
  const factory SendMessage(
      {required final String conversationId,
      required final String content}) = _$SendMessageImpl;

  String get conversationId;
  String get content;

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SendMessageImplCopyWith<_$SendMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SendFileImplCopyWith<$Res> {
  factory _$$SendFileImplCopyWith(
          _$SendFileImpl value, $Res Function(_$SendFileImpl) then) =
      __$$SendFileImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String conversationId, String filePath, String? type});
}

/// @nodoc
class __$$SendFileImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$SendFileImpl>
    implements _$$SendFileImplCopyWith<$Res> {
  __$$SendFileImplCopyWithImpl(
      _$SendFileImpl _value, $Res Function(_$SendFileImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? conversationId = null,
    Object? filePath = null,
    Object? type = freezed,
  }) {
    return _then(_$SendFileImpl(
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
      filePath: null == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      type: freezed == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$SendFileImpl implements SendFile {
  const _$SendFileImpl(
      {required this.conversationId, required this.filePath, this.type});

  @override
  final String conversationId;
  @override
  final String filePath;
  @override
  final String? type;

  @override
  String toString() {
    return 'ChatEvent.sendFile(conversationId: $conversationId, filePath: $filePath, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SendFileImpl &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.type, type) || other.type == type));
  }

  @override
  int get hashCode => Object.hash(runtimeType, conversationId, filePath, type);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SendFileImplCopyWith<_$SendFileImpl> get copyWith =>
      __$$SendFileImplCopyWithImpl<_$SendFileImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadConversations,
    required TResult Function(
            String userId, String? residenceId, String? reservationId)
        createConversation,
    required TResult Function(String conversationId, String content)
        sendMessage,
    required TResult Function(
            String conversationId, String filePath, String? type)
        sendFile,
    required TResult Function(String conversationId, String imagePath)
        sendImage,
    required TResult Function(String conversationId) loadMessages,
    required TResult Function(String messageId, String conversationId)
        markAsRead,
    required TResult Function(String conversationId) markAllAsRead,
  }) {
    return sendFile(conversationId, filePath, type);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadConversations,
    TResult? Function(
            String userId, String? residenceId, String? reservationId)?
        createConversation,
    TResult? Function(String conversationId, String content)? sendMessage,
    TResult? Function(String conversationId, String filePath, String? type)?
        sendFile,
    TResult? Function(String conversationId, String imagePath)? sendImage,
    TResult? Function(String conversationId)? loadMessages,
    TResult? Function(String messageId, String conversationId)? markAsRead,
    TResult? Function(String conversationId)? markAllAsRead,
  }) {
    return sendFile?.call(conversationId, filePath, type);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadConversations,
    TResult Function(String userId, String? residenceId, String? reservationId)?
        createConversation,
    TResult Function(String conversationId, String content)? sendMessage,
    TResult Function(String conversationId, String filePath, String? type)?
        sendFile,
    TResult Function(String conversationId, String imagePath)? sendImage,
    TResult Function(String conversationId)? loadMessages,
    TResult Function(String messageId, String conversationId)? markAsRead,
    TResult Function(String conversationId)? markAllAsRead,
    required TResult orElse(),
  }) {
    if (sendFile != null) {
      return sendFile(conversationId, filePath, type);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadConversations value) loadConversations,
    required TResult Function(CreateConversation value) createConversation,
    required TResult Function(SendMessage value) sendMessage,
    required TResult Function(SendFile value) sendFile,
    required TResult Function(SendImage value) sendImage,
    required TResult Function(LoadMessages value) loadMessages,
    required TResult Function(MarkAsRead value) markAsRead,
    required TResult Function(MarkAllAsRead value) markAllAsRead,
  }) {
    return sendFile(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadConversations value)? loadConversations,
    TResult? Function(CreateConversation value)? createConversation,
    TResult? Function(SendMessage value)? sendMessage,
    TResult? Function(SendFile value)? sendFile,
    TResult? Function(SendImage value)? sendImage,
    TResult? Function(LoadMessages value)? loadMessages,
    TResult? Function(MarkAsRead value)? markAsRead,
    TResult? Function(MarkAllAsRead value)? markAllAsRead,
  }) {
    return sendFile?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadConversations value)? loadConversations,
    TResult Function(CreateConversation value)? createConversation,
    TResult Function(SendMessage value)? sendMessage,
    TResult Function(SendFile value)? sendFile,
    TResult Function(SendImage value)? sendImage,
    TResult Function(LoadMessages value)? loadMessages,
    TResult Function(MarkAsRead value)? markAsRead,
    TResult Function(MarkAllAsRead value)? markAllAsRead,
    required TResult orElse(),
  }) {
    if (sendFile != null) {
      return sendFile(this);
    }
    return orElse();
  }
}

abstract class SendFile implements ChatEvent {
  const factory SendFile(
      {required final String conversationId,
      required final String filePath,
      final String? type}) = _$SendFileImpl;

  String get conversationId;
  String get filePath;
  String? get type;

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SendFileImplCopyWith<_$SendFileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SendImageImplCopyWith<$Res> {
  factory _$$SendImageImplCopyWith(
          _$SendImageImpl value, $Res Function(_$SendImageImpl) then) =
      __$$SendImageImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String conversationId, String imagePath});
}

/// @nodoc
class __$$SendImageImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$SendImageImpl>
    implements _$$SendImageImplCopyWith<$Res> {
  __$$SendImageImplCopyWithImpl(
      _$SendImageImpl _value, $Res Function(_$SendImageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? conversationId = null,
    Object? imagePath = null,
  }) {
    return _then(_$SendImageImpl(
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
      imagePath: null == imagePath
          ? _value.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SendImageImpl implements SendImage {
  const _$SendImageImpl(
      {required this.conversationId, required this.imagePath});

  @override
  final String conversationId;
  @override
  final String imagePath;

  @override
  String toString() {
    return 'ChatEvent.sendImage(conversationId: $conversationId, imagePath: $imagePath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SendImageImpl &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId) &&
            (identical(other.imagePath, imagePath) ||
                other.imagePath == imagePath));
  }

  @override
  int get hashCode => Object.hash(runtimeType, conversationId, imagePath);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SendImageImplCopyWith<_$SendImageImpl> get copyWith =>
      __$$SendImageImplCopyWithImpl<_$SendImageImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadConversations,
    required TResult Function(
            String userId, String? residenceId, String? reservationId)
        createConversation,
    required TResult Function(String conversationId, String content)
        sendMessage,
    required TResult Function(
            String conversationId, String filePath, String? type)
        sendFile,
    required TResult Function(String conversationId, String imagePath)
        sendImage,
    required TResult Function(String conversationId) loadMessages,
    required TResult Function(String messageId, String conversationId)
        markAsRead,
    required TResult Function(String conversationId) markAllAsRead,
  }) {
    return sendImage(conversationId, imagePath);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadConversations,
    TResult? Function(
            String userId, String? residenceId, String? reservationId)?
        createConversation,
    TResult? Function(String conversationId, String content)? sendMessage,
    TResult? Function(String conversationId, String filePath, String? type)?
        sendFile,
    TResult? Function(String conversationId, String imagePath)? sendImage,
    TResult? Function(String conversationId)? loadMessages,
    TResult? Function(String messageId, String conversationId)? markAsRead,
    TResult? Function(String conversationId)? markAllAsRead,
  }) {
    return sendImage?.call(conversationId, imagePath);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadConversations,
    TResult Function(String userId, String? residenceId, String? reservationId)?
        createConversation,
    TResult Function(String conversationId, String content)? sendMessage,
    TResult Function(String conversationId, String filePath, String? type)?
        sendFile,
    TResult Function(String conversationId, String imagePath)? sendImage,
    TResult Function(String conversationId)? loadMessages,
    TResult Function(String messageId, String conversationId)? markAsRead,
    TResult Function(String conversationId)? markAllAsRead,
    required TResult orElse(),
  }) {
    if (sendImage != null) {
      return sendImage(conversationId, imagePath);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadConversations value) loadConversations,
    required TResult Function(CreateConversation value) createConversation,
    required TResult Function(SendMessage value) sendMessage,
    required TResult Function(SendFile value) sendFile,
    required TResult Function(SendImage value) sendImage,
    required TResult Function(LoadMessages value) loadMessages,
    required TResult Function(MarkAsRead value) markAsRead,
    required TResult Function(MarkAllAsRead value) markAllAsRead,
  }) {
    return sendImage(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadConversations value)? loadConversations,
    TResult? Function(CreateConversation value)? createConversation,
    TResult? Function(SendMessage value)? sendMessage,
    TResult? Function(SendFile value)? sendFile,
    TResult? Function(SendImage value)? sendImage,
    TResult? Function(LoadMessages value)? loadMessages,
    TResult? Function(MarkAsRead value)? markAsRead,
    TResult? Function(MarkAllAsRead value)? markAllAsRead,
  }) {
    return sendImage?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadConversations value)? loadConversations,
    TResult Function(CreateConversation value)? createConversation,
    TResult Function(SendMessage value)? sendMessage,
    TResult Function(SendFile value)? sendFile,
    TResult Function(SendImage value)? sendImage,
    TResult Function(LoadMessages value)? loadMessages,
    TResult Function(MarkAsRead value)? markAsRead,
    TResult Function(MarkAllAsRead value)? markAllAsRead,
    required TResult orElse(),
  }) {
    if (sendImage != null) {
      return sendImage(this);
    }
    return orElse();
  }
}

abstract class SendImage implements ChatEvent {
  const factory SendImage(
      {required final String conversationId,
      required final String imagePath}) = _$SendImageImpl;

  String get conversationId;
  String get imagePath;

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SendImageImplCopyWith<_$SendImageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LoadMessagesImplCopyWith<$Res> {
  factory _$$LoadMessagesImplCopyWith(
          _$LoadMessagesImpl value, $Res Function(_$LoadMessagesImpl) then) =
      __$$LoadMessagesImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String conversationId});
}

/// @nodoc
class __$$LoadMessagesImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$LoadMessagesImpl>
    implements _$$LoadMessagesImplCopyWith<$Res> {
  __$$LoadMessagesImplCopyWithImpl(
      _$LoadMessagesImpl _value, $Res Function(_$LoadMessagesImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? conversationId = null,
  }) {
    return _then(_$LoadMessagesImpl(
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$LoadMessagesImpl implements LoadMessages {
  const _$LoadMessagesImpl({required this.conversationId});

  @override
  final String conversationId;

  @override
  String toString() {
    return 'ChatEvent.loadMessages(conversationId: $conversationId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadMessagesImpl &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, conversationId);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadMessagesImplCopyWith<_$LoadMessagesImpl> get copyWith =>
      __$$LoadMessagesImplCopyWithImpl<_$LoadMessagesImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadConversations,
    required TResult Function(
            String userId, String? residenceId, String? reservationId)
        createConversation,
    required TResult Function(String conversationId, String content)
        sendMessage,
    required TResult Function(
            String conversationId, String filePath, String? type)
        sendFile,
    required TResult Function(String conversationId, String imagePath)
        sendImage,
    required TResult Function(String conversationId) loadMessages,
    required TResult Function(String messageId, String conversationId)
        markAsRead,
    required TResult Function(String conversationId) markAllAsRead,
  }) {
    return loadMessages(conversationId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadConversations,
    TResult? Function(
            String userId, String? residenceId, String? reservationId)?
        createConversation,
    TResult? Function(String conversationId, String content)? sendMessage,
    TResult? Function(String conversationId, String filePath, String? type)?
        sendFile,
    TResult? Function(String conversationId, String imagePath)? sendImage,
    TResult? Function(String conversationId)? loadMessages,
    TResult? Function(String messageId, String conversationId)? markAsRead,
    TResult? Function(String conversationId)? markAllAsRead,
  }) {
    return loadMessages?.call(conversationId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadConversations,
    TResult Function(String userId, String? residenceId, String? reservationId)?
        createConversation,
    TResult Function(String conversationId, String content)? sendMessage,
    TResult Function(String conversationId, String filePath, String? type)?
        sendFile,
    TResult Function(String conversationId, String imagePath)? sendImage,
    TResult Function(String conversationId)? loadMessages,
    TResult Function(String messageId, String conversationId)? markAsRead,
    TResult Function(String conversationId)? markAllAsRead,
    required TResult orElse(),
  }) {
    if (loadMessages != null) {
      return loadMessages(conversationId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadConversations value) loadConversations,
    required TResult Function(CreateConversation value) createConversation,
    required TResult Function(SendMessage value) sendMessage,
    required TResult Function(SendFile value) sendFile,
    required TResult Function(SendImage value) sendImage,
    required TResult Function(LoadMessages value) loadMessages,
    required TResult Function(MarkAsRead value) markAsRead,
    required TResult Function(MarkAllAsRead value) markAllAsRead,
  }) {
    return loadMessages(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadConversations value)? loadConversations,
    TResult? Function(CreateConversation value)? createConversation,
    TResult? Function(SendMessage value)? sendMessage,
    TResult? Function(SendFile value)? sendFile,
    TResult? Function(SendImage value)? sendImage,
    TResult? Function(LoadMessages value)? loadMessages,
    TResult? Function(MarkAsRead value)? markAsRead,
    TResult? Function(MarkAllAsRead value)? markAllAsRead,
  }) {
    return loadMessages?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadConversations value)? loadConversations,
    TResult Function(CreateConversation value)? createConversation,
    TResult Function(SendMessage value)? sendMessage,
    TResult Function(SendFile value)? sendFile,
    TResult Function(SendImage value)? sendImage,
    TResult Function(LoadMessages value)? loadMessages,
    TResult Function(MarkAsRead value)? markAsRead,
    TResult Function(MarkAllAsRead value)? markAllAsRead,
    required TResult orElse(),
  }) {
    if (loadMessages != null) {
      return loadMessages(this);
    }
    return orElse();
  }
}

abstract class LoadMessages implements ChatEvent {
  const factory LoadMessages({required final String conversationId}) =
      _$LoadMessagesImpl;

  String get conversationId;

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoadMessagesImplCopyWith<_$LoadMessagesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MarkAsReadImplCopyWith<$Res> {
  factory _$$MarkAsReadImplCopyWith(
          _$MarkAsReadImpl value, $Res Function(_$MarkAsReadImpl) then) =
      __$$MarkAsReadImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String messageId, String conversationId});
}

/// @nodoc
class __$$MarkAsReadImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$MarkAsReadImpl>
    implements _$$MarkAsReadImplCopyWith<$Res> {
  __$$MarkAsReadImplCopyWithImpl(
      _$MarkAsReadImpl _value, $Res Function(_$MarkAsReadImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messageId = null,
    Object? conversationId = null,
  }) {
    return _then(_$MarkAsReadImpl(
      messageId: null == messageId
          ? _value.messageId
          : messageId // ignore: cast_nullable_to_non_nullable
              as String,
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$MarkAsReadImpl implements MarkAsRead {
  const _$MarkAsReadImpl(
      {required this.messageId, required this.conversationId});

  @override
  final String messageId;
  @override
  final String conversationId;

  @override
  String toString() {
    return 'ChatEvent.markAsRead(messageId: $messageId, conversationId: $conversationId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MarkAsReadImpl &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId) &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, messageId, conversationId);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MarkAsReadImplCopyWith<_$MarkAsReadImpl> get copyWith =>
      __$$MarkAsReadImplCopyWithImpl<_$MarkAsReadImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadConversations,
    required TResult Function(
            String userId, String? residenceId, String? reservationId)
        createConversation,
    required TResult Function(String conversationId, String content)
        sendMessage,
    required TResult Function(
            String conversationId, String filePath, String? type)
        sendFile,
    required TResult Function(String conversationId, String imagePath)
        sendImage,
    required TResult Function(String conversationId) loadMessages,
    required TResult Function(String messageId, String conversationId)
        markAsRead,
    required TResult Function(String conversationId) markAllAsRead,
  }) {
    return markAsRead(messageId, conversationId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadConversations,
    TResult? Function(
            String userId, String? residenceId, String? reservationId)?
        createConversation,
    TResult? Function(String conversationId, String content)? sendMessage,
    TResult? Function(String conversationId, String filePath, String? type)?
        sendFile,
    TResult? Function(String conversationId, String imagePath)? sendImage,
    TResult? Function(String conversationId)? loadMessages,
    TResult? Function(String messageId, String conversationId)? markAsRead,
    TResult? Function(String conversationId)? markAllAsRead,
  }) {
    return markAsRead?.call(messageId, conversationId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadConversations,
    TResult Function(String userId, String? residenceId, String? reservationId)?
        createConversation,
    TResult Function(String conversationId, String content)? sendMessage,
    TResult Function(String conversationId, String filePath, String? type)?
        sendFile,
    TResult Function(String conversationId, String imagePath)? sendImage,
    TResult Function(String conversationId)? loadMessages,
    TResult Function(String messageId, String conversationId)? markAsRead,
    TResult Function(String conversationId)? markAllAsRead,
    required TResult orElse(),
  }) {
    if (markAsRead != null) {
      return markAsRead(messageId, conversationId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadConversations value) loadConversations,
    required TResult Function(CreateConversation value) createConversation,
    required TResult Function(SendMessage value) sendMessage,
    required TResult Function(SendFile value) sendFile,
    required TResult Function(SendImage value) sendImage,
    required TResult Function(LoadMessages value) loadMessages,
    required TResult Function(MarkAsRead value) markAsRead,
    required TResult Function(MarkAllAsRead value) markAllAsRead,
  }) {
    return markAsRead(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadConversations value)? loadConversations,
    TResult? Function(CreateConversation value)? createConversation,
    TResult? Function(SendMessage value)? sendMessage,
    TResult? Function(SendFile value)? sendFile,
    TResult? Function(SendImage value)? sendImage,
    TResult? Function(LoadMessages value)? loadMessages,
    TResult? Function(MarkAsRead value)? markAsRead,
    TResult? Function(MarkAllAsRead value)? markAllAsRead,
  }) {
    return markAsRead?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadConversations value)? loadConversations,
    TResult Function(CreateConversation value)? createConversation,
    TResult Function(SendMessage value)? sendMessage,
    TResult Function(SendFile value)? sendFile,
    TResult Function(SendImage value)? sendImage,
    TResult Function(LoadMessages value)? loadMessages,
    TResult Function(MarkAsRead value)? markAsRead,
    TResult Function(MarkAllAsRead value)? markAllAsRead,
    required TResult orElse(),
  }) {
    if (markAsRead != null) {
      return markAsRead(this);
    }
    return orElse();
  }
}

abstract class MarkAsRead implements ChatEvent {
  const factory MarkAsRead(
      {required final String messageId,
      required final String conversationId}) = _$MarkAsReadImpl;

  String get messageId;
  String get conversationId;

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MarkAsReadImplCopyWith<_$MarkAsReadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MarkAllAsReadImplCopyWith<$Res> {
  factory _$$MarkAllAsReadImplCopyWith(
          _$MarkAllAsReadImpl value, $Res Function(_$MarkAllAsReadImpl) then) =
      __$$MarkAllAsReadImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String conversationId});
}

/// @nodoc
class __$$MarkAllAsReadImplCopyWithImpl<$Res>
    extends _$ChatEventCopyWithImpl<$Res, _$MarkAllAsReadImpl>
    implements _$$MarkAllAsReadImplCopyWith<$Res> {
  __$$MarkAllAsReadImplCopyWithImpl(
      _$MarkAllAsReadImpl _value, $Res Function(_$MarkAllAsReadImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? conversationId = null,
  }) {
    return _then(_$MarkAllAsReadImpl(
      conversationId: null == conversationId
          ? _value.conversationId
          : conversationId // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$MarkAllAsReadImpl implements MarkAllAsRead {
  const _$MarkAllAsReadImpl({required this.conversationId});

  @override
  final String conversationId;

  @override
  String toString() {
    return 'ChatEvent.markAllAsRead(conversationId: $conversationId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MarkAllAsReadImpl &&
            (identical(other.conversationId, conversationId) ||
                other.conversationId == conversationId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, conversationId);

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MarkAllAsReadImplCopyWith<_$MarkAllAsReadImpl> get copyWith =>
      __$$MarkAllAsReadImplCopyWithImpl<_$MarkAllAsReadImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadConversations,
    required TResult Function(
            String userId, String? residenceId, String? reservationId)
        createConversation,
    required TResult Function(String conversationId, String content)
        sendMessage,
    required TResult Function(
            String conversationId, String filePath, String? type)
        sendFile,
    required TResult Function(String conversationId, String imagePath)
        sendImage,
    required TResult Function(String conversationId) loadMessages,
    required TResult Function(String messageId, String conversationId)
        markAsRead,
    required TResult Function(String conversationId) markAllAsRead,
  }) {
    return markAllAsRead(conversationId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadConversations,
    TResult? Function(
            String userId, String? residenceId, String? reservationId)?
        createConversation,
    TResult? Function(String conversationId, String content)? sendMessage,
    TResult? Function(String conversationId, String filePath, String? type)?
        sendFile,
    TResult? Function(String conversationId, String imagePath)? sendImage,
    TResult? Function(String conversationId)? loadMessages,
    TResult? Function(String messageId, String conversationId)? markAsRead,
    TResult? Function(String conversationId)? markAllAsRead,
  }) {
    return markAllAsRead?.call(conversationId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadConversations,
    TResult Function(String userId, String? residenceId, String? reservationId)?
        createConversation,
    TResult Function(String conversationId, String content)? sendMessage,
    TResult Function(String conversationId, String filePath, String? type)?
        sendFile,
    TResult Function(String conversationId, String imagePath)? sendImage,
    TResult Function(String conversationId)? loadMessages,
    TResult Function(String messageId, String conversationId)? markAsRead,
    TResult Function(String conversationId)? markAllAsRead,
    required TResult orElse(),
  }) {
    if (markAllAsRead != null) {
      return markAllAsRead(conversationId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(LoadConversations value) loadConversations,
    required TResult Function(CreateConversation value) createConversation,
    required TResult Function(SendMessage value) sendMessage,
    required TResult Function(SendFile value) sendFile,
    required TResult Function(SendImage value) sendImage,
    required TResult Function(LoadMessages value) loadMessages,
    required TResult Function(MarkAsRead value) markAsRead,
    required TResult Function(MarkAllAsRead value) markAllAsRead,
  }) {
    return markAllAsRead(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(LoadConversations value)? loadConversations,
    TResult? Function(CreateConversation value)? createConversation,
    TResult? Function(SendMessage value)? sendMessage,
    TResult? Function(SendFile value)? sendFile,
    TResult? Function(SendImage value)? sendImage,
    TResult? Function(LoadMessages value)? loadMessages,
    TResult? Function(MarkAsRead value)? markAsRead,
    TResult? Function(MarkAllAsRead value)? markAllAsRead,
  }) {
    return markAllAsRead?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(LoadConversations value)? loadConversations,
    TResult Function(CreateConversation value)? createConversation,
    TResult Function(SendMessage value)? sendMessage,
    TResult Function(SendFile value)? sendFile,
    TResult Function(SendImage value)? sendImage,
    TResult Function(LoadMessages value)? loadMessages,
    TResult Function(MarkAsRead value)? markAsRead,
    TResult Function(MarkAllAsRead value)? markAllAsRead,
    required TResult orElse(),
  }) {
    if (markAllAsRead != null) {
      return markAllAsRead(this);
    }
    return orElse();
  }
}

abstract class MarkAllAsRead implements ChatEvent {
  const factory MarkAllAsRead({required final String conversationId}) =
      _$MarkAllAsReadImpl;

  String get conversationId;

  /// Create a copy of ChatEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MarkAllAsReadImplCopyWith<_$MarkAllAsReadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ChatState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<ChatConversation> conversations,
            ChatConversation? selectedConversation, bool isLoading)
        loaded,
    required TResult Function(String message) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<ChatConversation> conversations,
            ChatConversation? selectedConversation, bool isLoading)?
        loaded,
    TResult? Function(String message)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<ChatConversation> conversations,
            ChatConversation? selectedConversation, bool isLoading)?
        loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatInitial value) initial,
    required TResult Function(ChatLoading value) loading,
    required TResult Function(ChatLoaded value) loaded,
    required TResult Function(ChatError value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatInitial value)? initial,
    TResult? Function(ChatLoading value)? loading,
    TResult? Function(ChatLoaded value)? loaded,
    TResult? Function(ChatError value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatInitial value)? initial,
    TResult Function(ChatLoading value)? loading,
    TResult Function(ChatLoaded value)? loaded,
    TResult Function(ChatError value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatStateCopyWith<$Res> {
  factory $ChatStateCopyWith(ChatState value, $Res Function(ChatState) then) =
      _$ChatStateCopyWithImpl<$Res, ChatState>;
}

/// @nodoc
class _$ChatStateCopyWithImpl<$Res, $Val extends ChatState>
    implements $ChatStateCopyWith<$Res> {
  _$ChatStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$ChatInitialImplCopyWith<$Res> {
  factory _$$ChatInitialImplCopyWith(
          _$ChatInitialImpl value, $Res Function(_$ChatInitialImpl) then) =
      __$$ChatInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ChatInitialImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$ChatInitialImpl>
    implements _$$ChatInitialImplCopyWith<$Res> {
  __$$ChatInitialImplCopyWithImpl(
      _$ChatInitialImpl _value, $Res Function(_$ChatInitialImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$ChatInitialImpl implements ChatInitial {
  const _$ChatInitialImpl();

  @override
  String toString() {
    return 'ChatState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$ChatInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<ChatConversation> conversations,
            ChatConversation? selectedConversation, bool isLoading)
        loaded,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<ChatConversation> conversations,
            ChatConversation? selectedConversation, bool isLoading)?
        loaded,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<ChatConversation> conversations,
            ChatConversation? selectedConversation, bool isLoading)?
        loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatInitial value) initial,
    required TResult Function(ChatLoading value) loading,
    required TResult Function(ChatLoaded value) loaded,
    required TResult Function(ChatError value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatInitial value)? initial,
    TResult? Function(ChatLoading value)? loading,
    TResult? Function(ChatLoaded value)? loaded,
    TResult? Function(ChatError value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatInitial value)? initial,
    TResult Function(ChatLoading value)? loading,
    TResult Function(ChatLoaded value)? loaded,
    TResult Function(ChatError value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class ChatInitial implements ChatState {
  const factory ChatInitial() = _$ChatInitialImpl;
}

/// @nodoc
abstract class _$$ChatLoadingImplCopyWith<$Res> {
  factory _$$ChatLoadingImplCopyWith(
          _$ChatLoadingImpl value, $Res Function(_$ChatLoadingImpl) then) =
      __$$ChatLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ChatLoadingImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$ChatLoadingImpl>
    implements _$$ChatLoadingImplCopyWith<$Res> {
  __$$ChatLoadingImplCopyWithImpl(
      _$ChatLoadingImpl _value, $Res Function(_$ChatLoadingImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$ChatLoadingImpl implements ChatLoading {
  const _$ChatLoadingImpl();

  @override
  String toString() {
    return 'ChatState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$ChatLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<ChatConversation> conversations,
            ChatConversation? selectedConversation, bool isLoading)
        loaded,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<ChatConversation> conversations,
            ChatConversation? selectedConversation, bool isLoading)?
        loaded,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<ChatConversation> conversations,
            ChatConversation? selectedConversation, bool isLoading)?
        loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatInitial value) initial,
    required TResult Function(ChatLoading value) loading,
    required TResult Function(ChatLoaded value) loaded,
    required TResult Function(ChatError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatInitial value)? initial,
    TResult? Function(ChatLoading value)? loading,
    TResult? Function(ChatLoaded value)? loaded,
    TResult? Function(ChatError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatInitial value)? initial,
    TResult Function(ChatLoading value)? loading,
    TResult Function(ChatLoaded value)? loaded,
    TResult Function(ChatError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class ChatLoading implements ChatState {
  const factory ChatLoading() = _$ChatLoadingImpl;
}

/// @nodoc
abstract class _$$ChatLoadedImplCopyWith<$Res> {
  factory _$$ChatLoadedImplCopyWith(
          _$ChatLoadedImpl value, $Res Function(_$ChatLoadedImpl) then) =
      __$$ChatLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {List<ChatConversation> conversations,
      ChatConversation? selectedConversation,
      bool isLoading});

  $ChatConversationCopyWith<$Res>? get selectedConversation;
}

/// @nodoc
class __$$ChatLoadedImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$ChatLoadedImpl>
    implements _$$ChatLoadedImplCopyWith<$Res> {
  __$$ChatLoadedImplCopyWithImpl(
      _$ChatLoadedImpl _value, $Res Function(_$ChatLoadedImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? conversations = null,
    Object? selectedConversation = freezed,
    Object? isLoading = null,
  }) {
    return _then(_$ChatLoadedImpl(
      conversations: null == conversations
          ? _value._conversations
          : conversations // ignore: cast_nullable_to_non_nullable
              as List<ChatConversation>,
      selectedConversation: freezed == selectedConversation
          ? _value.selectedConversation
          : selectedConversation // ignore: cast_nullable_to_non_nullable
              as ChatConversation?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ChatConversationCopyWith<$Res>? get selectedConversation {
    if (_value.selectedConversation == null) {
      return null;
    }

    return $ChatConversationCopyWith<$Res>(_value.selectedConversation!,
        (value) {
      return _then(_value.copyWith(selectedConversation: value));
    });
  }
}

/// @nodoc

class _$ChatLoadedImpl implements ChatLoaded {
  const _$ChatLoadedImpl(
      {required final List<ChatConversation> conversations,
      this.selectedConversation,
      this.isLoading = false})
      : _conversations = conversations;

  final List<ChatConversation> _conversations;
  @override
  List<ChatConversation> get conversations {
    if (_conversations is EqualUnmodifiableListView) return _conversations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_conversations);
  }

  @override
  final ChatConversation? selectedConversation;
  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString() {
    return 'ChatState.loaded(conversations: $conversations, selectedConversation: $selectedConversation, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatLoadedImpl &&
            const DeepCollectionEquality()
                .equals(other._conversations, _conversations) &&
            (identical(other.selectedConversation, selectedConversation) ||
                other.selectedConversation == selectedConversation) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_conversations),
      selectedConversation,
      isLoading);

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatLoadedImplCopyWith<_$ChatLoadedImpl> get copyWith =>
      __$$ChatLoadedImplCopyWithImpl<_$ChatLoadedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<ChatConversation> conversations,
            ChatConversation? selectedConversation, bool isLoading)
        loaded,
    required TResult Function(String message) error,
  }) {
    return loaded(conversations, selectedConversation, isLoading);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<ChatConversation> conversations,
            ChatConversation? selectedConversation, bool isLoading)?
        loaded,
    TResult? Function(String message)? error,
  }) {
    return loaded?.call(conversations, selectedConversation, isLoading);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<ChatConversation> conversations,
            ChatConversation? selectedConversation, bool isLoading)?
        loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(conversations, selectedConversation, isLoading);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatInitial value) initial,
    required TResult Function(ChatLoading value) loading,
    required TResult Function(ChatLoaded value) loaded,
    required TResult Function(ChatError value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatInitial value)? initial,
    TResult? Function(ChatLoading value)? loading,
    TResult? Function(ChatLoaded value)? loaded,
    TResult? Function(ChatError value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatInitial value)? initial,
    TResult Function(ChatLoading value)? loading,
    TResult Function(ChatLoaded value)? loaded,
    TResult Function(ChatError value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class ChatLoaded implements ChatState {
  const factory ChatLoaded(
      {required final List<ChatConversation> conversations,
      final ChatConversation? selectedConversation,
      final bool isLoading}) = _$ChatLoadedImpl;

  List<ChatConversation> get conversations;
  ChatConversation? get selectedConversation;
  bool get isLoading;

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatLoadedImplCopyWith<_$ChatLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ChatErrorImplCopyWith<$Res> {
  factory _$$ChatErrorImplCopyWith(
          _$ChatErrorImpl value, $Res Function(_$ChatErrorImpl) then) =
      __$$ChatErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ChatErrorImplCopyWithImpl<$Res>
    extends _$ChatStateCopyWithImpl<$Res, _$ChatErrorImpl>
    implements _$$ChatErrorImplCopyWith<$Res> {
  __$$ChatErrorImplCopyWithImpl(
      _$ChatErrorImpl _value, $Res Function(_$ChatErrorImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$ChatErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ChatErrorImpl implements ChatError {
  const _$ChatErrorImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'ChatState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatErrorImplCopyWith<_$ChatErrorImpl> get copyWith =>
      __$$ChatErrorImplCopyWithImpl<_$ChatErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<ChatConversation> conversations,
            ChatConversation? selectedConversation, bool isLoading)
        loaded,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<ChatConversation> conversations,
            ChatConversation? selectedConversation, bool isLoading)?
        loaded,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<ChatConversation> conversations,
            ChatConversation? selectedConversation, bool isLoading)?
        loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatInitial value) initial,
    required TResult Function(ChatLoading value) loading,
    required TResult Function(ChatLoaded value) loaded,
    required TResult Function(ChatError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatInitial value)? initial,
    TResult? Function(ChatLoading value)? loading,
    TResult? Function(ChatLoaded value)? loaded,
    TResult? Function(ChatError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatInitial value)? initial,
    TResult Function(ChatLoading value)? loading,
    TResult Function(ChatLoaded value)? loaded,
    TResult Function(ChatError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class ChatError implements ChatState {
  const factory ChatError({required final String message}) = _$ChatErrorImpl;

  String get message;

  /// Create a copy of ChatState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatErrorImplCopyWith<_$ChatErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
