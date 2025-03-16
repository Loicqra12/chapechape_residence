import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'message.dart';

part 'message_thread.g.dart';

@JsonSerializable()
class MessageThread extends Equatable {
  final String id;
  final String clientId;
  final String clientName;
  final String? clientAvatar;
  final String partnerId;
  final String? residenceId;
  final String? residenceName;
  final String? bookingId;
  final String? bookingStatus;
  final DateTime lastMessageTime;
  final int unreadCount;
  final List<Message> messages;

  const MessageThread({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientAvatar,
    required this.partnerId,
    this.residenceId,
    this.residenceName,
    this.bookingId,
    this.bookingStatus,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.messages,
  });

  factory MessageThread.fromJson(Map<String, dynamic> json) =>
      _$MessageThreadFromJson(json);

  Map<String, dynamic> toJson() => _$MessageThreadToJson(this);

  MessageThread copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? clientAvatar,
    String? partnerId,
    String? residenceId,
    String? residenceName,
    String? bookingId,
    String? bookingStatus,
    DateTime? lastMessageTime,
    int? unreadCount,
    List<Message>? messages,
  }) {
    return MessageThread(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientAvatar: clientAvatar ?? this.clientAvatar,
      partnerId: partnerId ?? this.partnerId,
      residenceId: residenceId ?? this.residenceId,
      residenceName: residenceName ?? this.residenceName,
      bookingId: bookingId ?? this.bookingId,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      messages: messages ?? this.messages,
    );
  }

  @override
  List<Object?> get props => [
    id,
    clientId,
    clientName,
    clientAvatar,
    partnerId,
    residenceId,
    residenceName,
    bookingId,
    bookingStatus,
    lastMessageTime,
    unreadCount,
    messages,
  ];
}
