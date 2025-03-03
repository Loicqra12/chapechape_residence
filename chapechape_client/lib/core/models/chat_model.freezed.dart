// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChatParticipant _$ChatParticipantFromJson(Map<String, dynamic> json) {
  return _ChatParticipant.fromJson(json);
}

/// @nodoc
mixin _$ChatParticipant {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  bool get isOnline => throw _privateConstructorUsedError;
  DateTime? get lastSeen => throw _privateConstructorUsedError;
  bool get isTyping => throw _privateConstructorUsedError;

  /// Serializes this ChatParticipant to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatParticipant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatParticipantCopyWith<ChatParticipant> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatParticipantCopyWith<$Res> {
  factory $ChatParticipantCopyWith(
          ChatParticipant value, $Res Function(ChatParticipant) then) =
      _$ChatParticipantCopyWithImpl<$Res, ChatParticipant>;
  @useResult
  $Res call(
      {String id,
      String name,
      String? avatarUrl,
      bool isOnline,
      DateTime? lastSeen,
      bool isTyping});
}

/// @nodoc
class _$ChatParticipantCopyWithImpl<$Res, $Val extends ChatParticipant>
    implements $ChatParticipantCopyWith<$Res> {
  _$ChatParticipantCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatParticipant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? avatarUrl = freezed,
    Object? isOnline = null,
    Object? lastSeen = freezed,
    Object? isTyping = null,
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
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isOnline: null == isOnline
          ? _value.isOnline
          : isOnline // ignore: cast_nullable_to_non_nullable
              as bool,
      lastSeen: freezed == lastSeen
          ? _value.lastSeen
          : lastSeen // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isTyping: null == isTyping
          ? _value.isTyping
          : isTyping // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatParticipantImplCopyWith<$Res>
    implements $ChatParticipantCopyWith<$Res> {
  factory _$$ChatParticipantImplCopyWith(_$ChatParticipantImpl value,
          $Res Function(_$ChatParticipantImpl) then) =
      __$$ChatParticipantImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String? avatarUrl,
      bool isOnline,
      DateTime? lastSeen,
      bool isTyping});
}

/// @nodoc
class __$$ChatParticipantImplCopyWithImpl<$Res>
    extends _$ChatParticipantCopyWithImpl<$Res, _$ChatParticipantImpl>
    implements _$$ChatParticipantImplCopyWith<$Res> {
  __$$ChatParticipantImplCopyWithImpl(
      _$ChatParticipantImpl _value, $Res Function(_$ChatParticipantImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatParticipant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? avatarUrl = freezed,
    Object? isOnline = null,
    Object? lastSeen = freezed,
    Object? isTyping = null,
  }) {
    return _then(_$ChatParticipantImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      isOnline: null == isOnline
          ? _value.isOnline
          : isOnline // ignore: cast_nullable_to_non_nullable
              as bool,
      lastSeen: freezed == lastSeen
          ? _value.lastSeen
          : lastSeen // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isTyping: null == isTyping
          ? _value.isTyping
          : isTyping // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatParticipantImpl
    with DiagnosticableTreeMixin
    implements _ChatParticipant {
  const _$ChatParticipantImpl(
      {required this.id,
      required this.name,
      this.avatarUrl,
      this.isOnline = false,
      this.lastSeen,
      this.isTyping = false});

  factory _$ChatParticipantImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatParticipantImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? avatarUrl;
  @override
  @JsonKey()
  final bool isOnline;
  @override
  final DateTime? lastSeen;
  @override
  @JsonKey()
  final bool isTyping;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ChatParticipant(id: $id, name: $name, avatarUrl: $avatarUrl, isOnline: $isOnline, lastSeen: $lastSeen, isTyping: $isTyping)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'ChatParticipant'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('avatarUrl', avatarUrl))
      ..add(DiagnosticsProperty('isOnline', isOnline))
      ..add(DiagnosticsProperty('lastSeen', lastSeen))
      ..add(DiagnosticsProperty('isTyping', isTyping));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatParticipantImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.isOnline, isOnline) ||
                other.isOnline == isOnline) &&
            (identical(other.lastSeen, lastSeen) ||
                other.lastSeen == lastSeen) &&
            (identical(other.isTyping, isTyping) ||
                other.isTyping == isTyping));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, avatarUrl, isOnline, lastSeen, isTyping);

  /// Create a copy of ChatParticipant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatParticipantImplCopyWith<_$ChatParticipantImpl> get copyWith =>
      __$$ChatParticipantImplCopyWithImpl<_$ChatParticipantImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatParticipantImplToJson(
      this,
    );
  }
}

abstract class _ChatParticipant implements ChatParticipant {
  const factory _ChatParticipant(
      {required final String id,
      required final String name,
      final String? avatarUrl,
      final bool isOnline,
      final DateTime? lastSeen,
      final bool isTyping}) = _$ChatParticipantImpl;

  factory _ChatParticipant.fromJson(Map<String, dynamic> json) =
      _$ChatParticipantImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get avatarUrl;
  @override
  bool get isOnline;
  @override
  DateTime? get lastSeen;
  @override
  bool get isTyping;

  /// Create a copy of ChatParticipant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatParticipantImplCopyWith<_$ChatParticipantImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) {
  return _ChatMessage.fromJson(json);
}

/// @nodoc
mixin _$ChatMessage {
  String get id => throw _privateConstructorUsedError;
  String get senderId => throw _privateConstructorUsedError;
  String? get text => throw _privateConstructorUsedError;
  String? get content => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  bool get isRead => throw _privateConstructorUsedError;
  String? get attachmentUrl => throw _privateConstructorUsedError;
  String? get attachmentType => throw _privateConstructorUsedError;
  MessageStatus get status => throw _privateConstructorUsedError;

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatMessageCopyWith<ChatMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatMessageCopyWith<$Res> {
  factory $ChatMessageCopyWith(
          ChatMessage value, $Res Function(ChatMessage) then) =
      _$ChatMessageCopyWithImpl<$Res, ChatMessage>;
  @useResult
  $Res call(
      {String id,
      String senderId,
      String? text,
      String? content,
      DateTime timestamp,
      bool isRead,
      String? attachmentUrl,
      String? attachmentType,
      MessageStatus status});
}

/// @nodoc
class _$ChatMessageCopyWithImpl<$Res, $Val extends ChatMessage>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? senderId = null,
    Object? text = freezed,
    Object? content = freezed,
    Object? timestamp = null,
    Object? isRead = null,
    Object? attachmentUrl = freezed,
    Object? attachmentType = freezed,
    Object? status = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      text: freezed == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String?,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isRead: null == isRead
          ? _value.isRead
          : isRead // ignore: cast_nullable_to_non_nullable
              as bool,
      attachmentUrl: freezed == attachmentUrl
          ? _value.attachmentUrl
          : attachmentUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      attachmentType: freezed == attachmentType
          ? _value.attachmentType
          : attachmentType // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as MessageStatus,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatMessageImplCopyWith<$Res>
    implements $ChatMessageCopyWith<$Res> {
  factory _$$ChatMessageImplCopyWith(
          _$ChatMessageImpl value, $Res Function(_$ChatMessageImpl) then) =
      __$$ChatMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String senderId,
      String? text,
      String? content,
      DateTime timestamp,
      bool isRead,
      String? attachmentUrl,
      String? attachmentType,
      MessageStatus status});
}

/// @nodoc
class __$$ChatMessageImplCopyWithImpl<$Res>
    extends _$ChatMessageCopyWithImpl<$Res, _$ChatMessageImpl>
    implements _$$ChatMessageImplCopyWith<$Res> {
  __$$ChatMessageImplCopyWithImpl(
      _$ChatMessageImpl _value, $Res Function(_$ChatMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? senderId = null,
    Object? text = freezed,
    Object? content = freezed,
    Object? timestamp = null,
    Object? isRead = null,
    Object? attachmentUrl = freezed,
    Object? attachmentType = freezed,
    Object? status = null,
  }) {
    return _then(_$ChatMessageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      text: freezed == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String?,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String?,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isRead: null == isRead
          ? _value.isRead
          : isRead // ignore: cast_nullable_to_non_nullable
              as bool,
      attachmentUrl: freezed == attachmentUrl
          ? _value.attachmentUrl
          : attachmentUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      attachmentType: freezed == attachmentType
          ? _value.attachmentType
          : attachmentType // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as MessageStatus,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatMessageImpl with DiagnosticableTreeMixin implements _ChatMessage {
  const _$ChatMessageImpl(
      {required this.id,
      required this.senderId,
      this.text,
      this.content,
      required this.timestamp,
      this.isRead = false,
      this.attachmentUrl,
      this.attachmentType,
      this.status = MessageStatus.sent});

  factory _$ChatMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatMessageImplFromJson(json);

  @override
  final String id;
  @override
  final String senderId;
  @override
  final String? text;
  @override
  final String? content;
  @override
  final DateTime timestamp;
  @override
  @JsonKey()
  final bool isRead;
  @override
  final String? attachmentUrl;
  @override
  final String? attachmentType;
  @override
  @JsonKey()
  final MessageStatus status;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ChatMessage(id: $id, senderId: $senderId, text: $text, content: $content, timestamp: $timestamp, isRead: $isRead, attachmentUrl: $attachmentUrl, attachmentType: $attachmentType, status: $status)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'ChatMessage'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('senderId', senderId))
      ..add(DiagnosticsProperty('text', text))
      ..add(DiagnosticsProperty('content', content))
      ..add(DiagnosticsProperty('timestamp', timestamp))
      ..add(DiagnosticsProperty('isRead', isRead))
      ..add(DiagnosticsProperty('attachmentUrl', attachmentUrl))
      ..add(DiagnosticsProperty('attachmentType', attachmentType))
      ..add(DiagnosticsProperty('status', status));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.isRead, isRead) || other.isRead == isRead) &&
            (identical(other.attachmentUrl, attachmentUrl) ||
                other.attachmentUrl == attachmentUrl) &&
            (identical(other.attachmentType, attachmentType) ||
                other.attachmentType == attachmentType) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, senderId, text, content,
      timestamp, isRead, attachmentUrl, attachmentType, status);

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      __$$ChatMessageImplCopyWithImpl<_$ChatMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatMessageImplToJson(
      this,
    );
  }
}

abstract class _ChatMessage implements ChatMessage {
  const factory _ChatMessage(
      {required final String id,
      required final String senderId,
      final String? text,
      final String? content,
      required final DateTime timestamp,
      final bool isRead,
      final String? attachmentUrl,
      final String? attachmentType,
      final MessageStatus status}) = _$ChatMessageImpl;

  factory _ChatMessage.fromJson(Map<String, dynamic> json) =
      _$ChatMessageImpl.fromJson;

  @override
  String get id;
  @override
  String get senderId;
  @override
  String? get text;
  @override
  String? get content;
  @override
  DateTime get timestamp;
  @override
  bool get isRead;
  @override
  String? get attachmentUrl;
  @override
  String? get attachmentType;
  @override
  MessageStatus get status;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ChatConversation _$ChatConversationFromJson(Map<String, dynamic> json) {
  return _ChatConversation.fromJson(json);
}

/// @nodoc
mixin _$ChatConversation {
  String get id => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  List<String>? get participantIds => throw _privateConstructorUsedError;
  List<ChatMessage> get messages => throw _privateConstructorUsedError;
  DateTime? get lastMessageTime => throw _privateConstructorUsedError;
  String? get lastMessageText => throw _privateConstructorUsedError;
  String? get lastMessageSenderId => throw _privateConstructorUsedError;
  bool get isSupport => throw _privateConstructorUsedError;
  bool get isArchived => throw _privateConstructorUsedError;
  int get unreadCount => throw _privateConstructorUsedError;
  List<ChatParticipant> get participants => throw _privateConstructorUsedError;
  ChatMessage? get lastMessage => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ChatConversation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatConversation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatConversationCopyWith<ChatConversation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatConversationCopyWith<$Res> {
  factory $ChatConversationCopyWith(
          ChatConversation value, $Res Function(ChatConversation) then) =
      _$ChatConversationCopyWithImpl<$Res, ChatConversation>;
  @useResult
  $Res call(
      {String id,
      String? title,
      List<String>? participantIds,
      List<ChatMessage> messages,
      DateTime? lastMessageTime,
      String? lastMessageText,
      String? lastMessageSenderId,
      bool isSupport,
      bool isArchived,
      int unreadCount,
      List<ChatParticipant> participants,
      ChatMessage? lastMessage,
      DateTime? updatedAt});

  $ChatMessageCopyWith<$Res>? get lastMessage;
}

/// @nodoc
class _$ChatConversationCopyWithImpl<$Res, $Val extends ChatConversation>
    implements $ChatConversationCopyWith<$Res> {
  _$ChatConversationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatConversation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = freezed,
    Object? participantIds = freezed,
    Object? messages = null,
    Object? lastMessageTime = freezed,
    Object? lastMessageText = freezed,
    Object? lastMessageSenderId = freezed,
    Object? isSupport = null,
    Object? isArchived = null,
    Object? unreadCount = null,
    Object? participants = null,
    Object? lastMessage = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      participantIds: freezed == participantIds
          ? _value.participantIds
          : participantIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      messages: null == messages
          ? _value.messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<ChatMessage>,
      lastMessageTime: freezed == lastMessageTime
          ? _value.lastMessageTime
          : lastMessageTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastMessageText: freezed == lastMessageText
          ? _value.lastMessageText
          : lastMessageText // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessageSenderId: freezed == lastMessageSenderId
          ? _value.lastMessageSenderId
          : lastMessageSenderId // ignore: cast_nullable_to_non_nullable
              as String?,
      isSupport: null == isSupport
          ? _value.isSupport
          : isSupport // ignore: cast_nullable_to_non_nullable
              as bool,
      isArchived: null == isArchived
          ? _value.isArchived
          : isArchived // ignore: cast_nullable_to_non_nullable
              as bool,
      unreadCount: null == unreadCount
          ? _value.unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as int,
      participants: null == participants
          ? _value.participants
          : participants // ignore: cast_nullable_to_non_nullable
              as List<ChatParticipant>,
      lastMessage: freezed == lastMessage
          ? _value.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as ChatMessage?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  /// Create a copy of ChatConversation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ChatMessageCopyWith<$Res>? get lastMessage {
    if (_value.lastMessage == null) {
      return null;
    }

    return $ChatMessageCopyWith<$Res>(_value.lastMessage!, (value) {
      return _then(_value.copyWith(lastMessage: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ChatConversationImplCopyWith<$Res>
    implements $ChatConversationCopyWith<$Res> {
  factory _$$ChatConversationImplCopyWith(_$ChatConversationImpl value,
          $Res Function(_$ChatConversationImpl) then) =
      __$$ChatConversationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String? title,
      List<String>? participantIds,
      List<ChatMessage> messages,
      DateTime? lastMessageTime,
      String? lastMessageText,
      String? lastMessageSenderId,
      bool isSupport,
      bool isArchived,
      int unreadCount,
      List<ChatParticipant> participants,
      ChatMessage? lastMessage,
      DateTime? updatedAt});

  @override
  $ChatMessageCopyWith<$Res>? get lastMessage;
}

/// @nodoc
class __$$ChatConversationImplCopyWithImpl<$Res>
    extends _$ChatConversationCopyWithImpl<$Res, _$ChatConversationImpl>
    implements _$$ChatConversationImplCopyWith<$Res> {
  __$$ChatConversationImplCopyWithImpl(_$ChatConversationImpl _value,
      $Res Function(_$ChatConversationImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatConversation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = freezed,
    Object? participantIds = freezed,
    Object? messages = null,
    Object? lastMessageTime = freezed,
    Object? lastMessageText = freezed,
    Object? lastMessageSenderId = freezed,
    Object? isSupport = null,
    Object? isArchived = null,
    Object? unreadCount = null,
    Object? participants = null,
    Object? lastMessage = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$ChatConversationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      participantIds: freezed == participantIds
          ? _value._participantIds
          : participantIds // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      messages: null == messages
          ? _value._messages
          : messages // ignore: cast_nullable_to_non_nullable
              as List<ChatMessage>,
      lastMessageTime: freezed == lastMessageTime
          ? _value.lastMessageTime
          : lastMessageTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      lastMessageText: freezed == lastMessageText
          ? _value.lastMessageText
          : lastMessageText // ignore: cast_nullable_to_non_nullable
              as String?,
      lastMessageSenderId: freezed == lastMessageSenderId
          ? _value.lastMessageSenderId
          : lastMessageSenderId // ignore: cast_nullable_to_non_nullable
              as String?,
      isSupport: null == isSupport
          ? _value.isSupport
          : isSupport // ignore: cast_nullable_to_non_nullable
              as bool,
      isArchived: null == isArchived
          ? _value.isArchived
          : isArchived // ignore: cast_nullable_to_non_nullable
              as bool,
      unreadCount: null == unreadCount
          ? _value.unreadCount
          : unreadCount // ignore: cast_nullable_to_non_nullable
              as int,
      participants: null == participants
          ? _value._participants
          : participants // ignore: cast_nullable_to_non_nullable
              as List<ChatParticipant>,
      lastMessage: freezed == lastMessage
          ? _value.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as ChatMessage?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatConversationImpl
    with DiagnosticableTreeMixin
    implements _ChatConversation {
  const _$ChatConversationImpl(
      {required this.id,
      this.title,
      final List<String>? participantIds,
      final List<ChatMessage> messages = const [],
      this.lastMessageTime,
      this.lastMessageText,
      this.lastMessageSenderId,
      this.isSupport = false,
      this.isArchived = false,
      this.unreadCount = 0,
      final List<ChatParticipant> participants = const [],
      this.lastMessage,
      this.updatedAt})
      : _participantIds = participantIds,
        _messages = messages,
        _participants = participants;

  factory _$ChatConversationImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatConversationImplFromJson(json);

  @override
  final String id;
  @override
  final String? title;
  final List<String>? _participantIds;
  @override
  List<String>? get participantIds {
    final value = _participantIds;
    if (value == null) return null;
    if (_participantIds is EqualUnmodifiableListView) return _participantIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<ChatMessage> _messages;
  @override
  @JsonKey()
  List<ChatMessage> get messages {
    if (_messages is EqualUnmodifiableListView) return _messages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_messages);
  }

  @override
  final DateTime? lastMessageTime;
  @override
  final String? lastMessageText;
  @override
  final String? lastMessageSenderId;
  @override
  @JsonKey()
  final bool isSupport;
  @override
  @JsonKey()
  final bool isArchived;
  @override
  @JsonKey()
  final int unreadCount;
  final List<ChatParticipant> _participants;
  @override
  @JsonKey()
  List<ChatParticipant> get participants {
    if (_participants is EqualUnmodifiableListView) return _participants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_participants);
  }

  @override
  final ChatMessage? lastMessage;
  @override
  final DateTime? updatedAt;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ChatConversation(id: $id, title: $title, participantIds: $participantIds, messages: $messages, lastMessageTime: $lastMessageTime, lastMessageText: $lastMessageText, lastMessageSenderId: $lastMessageSenderId, isSupport: $isSupport, isArchived: $isArchived, unreadCount: $unreadCount, participants: $participants, lastMessage: $lastMessage, updatedAt: $updatedAt)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'ChatConversation'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('title', title))
      ..add(DiagnosticsProperty('participantIds', participantIds))
      ..add(DiagnosticsProperty('messages', messages))
      ..add(DiagnosticsProperty('lastMessageTime', lastMessageTime))
      ..add(DiagnosticsProperty('lastMessageText', lastMessageText))
      ..add(DiagnosticsProperty('lastMessageSenderId', lastMessageSenderId))
      ..add(DiagnosticsProperty('isSupport', isSupport))
      ..add(DiagnosticsProperty('isArchived', isArchived))
      ..add(DiagnosticsProperty('unreadCount', unreadCount))
      ..add(DiagnosticsProperty('participants', participants))
      ..add(DiagnosticsProperty('lastMessage', lastMessage))
      ..add(DiagnosticsProperty('updatedAt', updatedAt));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatConversationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality()
                .equals(other._participantIds, _participantIds) &&
            const DeepCollectionEquality().equals(other._messages, _messages) &&
            (identical(other.lastMessageTime, lastMessageTime) ||
                other.lastMessageTime == lastMessageTime) &&
            (identical(other.lastMessageText, lastMessageText) ||
                other.lastMessageText == lastMessageText) &&
            (identical(other.lastMessageSenderId, lastMessageSenderId) ||
                other.lastMessageSenderId == lastMessageSenderId) &&
            (identical(other.isSupport, isSupport) ||
                other.isSupport == isSupport) &&
            (identical(other.isArchived, isArchived) ||
                other.isArchived == isArchived) &&
            (identical(other.unreadCount, unreadCount) ||
                other.unreadCount == unreadCount) &&
            const DeepCollectionEquality()
                .equals(other._participants, _participants) &&
            (identical(other.lastMessage, lastMessage) ||
                other.lastMessage == lastMessage) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      const DeepCollectionEquality().hash(_participantIds),
      const DeepCollectionEquality().hash(_messages),
      lastMessageTime,
      lastMessageText,
      lastMessageSenderId,
      isSupport,
      isArchived,
      unreadCount,
      const DeepCollectionEquality().hash(_participants),
      lastMessage,
      updatedAt);

  /// Create a copy of ChatConversation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatConversationImplCopyWith<_$ChatConversationImpl> get copyWith =>
      __$$ChatConversationImplCopyWithImpl<_$ChatConversationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatConversationImplToJson(
      this,
    );
  }
}

abstract class _ChatConversation implements ChatConversation {
  const factory _ChatConversation(
      {required final String id,
      final String? title,
      final List<String>? participantIds,
      final List<ChatMessage> messages,
      final DateTime? lastMessageTime,
      final String? lastMessageText,
      final String? lastMessageSenderId,
      final bool isSupport,
      final bool isArchived,
      final int unreadCount,
      final List<ChatParticipant> participants,
      final ChatMessage? lastMessage,
      final DateTime? updatedAt}) = _$ChatConversationImpl;

  factory _ChatConversation.fromJson(Map<String, dynamic> json) =
      _$ChatConversationImpl.fromJson;

  @override
  String get id;
  @override
  String? get title;
  @override
  List<String>? get participantIds;
  @override
  List<ChatMessage> get messages;
  @override
  DateTime? get lastMessageTime;
  @override
  String? get lastMessageText;
  @override
  String? get lastMessageSenderId;
  @override
  bool get isSupport;
  @override
  bool get isArchived;
  @override
  int get unreadCount;
  @override
  List<ChatParticipant> get participants;
  @override
  ChatMessage? get lastMessage;
  @override
  DateTime? get updatedAt;

  /// Create a copy of ChatConversation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatConversationImplCopyWith<_$ChatConversationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
