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
  final String? reservationId;
  final String? reservationStatus;
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
    this.reservationId,
    this.reservationStatus,
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
    String? reservationId,
    String? reservationStatus,
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
      reservationId: reservationId ?? this.reservationId,
      reservationStatus: reservationStatus ?? this.reservationStatus,
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
    reservationId,
    reservationStatus,
    lastMessageTime,
    unreadCount,
    messages,
  ];
}
