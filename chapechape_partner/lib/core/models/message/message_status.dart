enum MessageStatus {
  sent,
  delivered,
  read,
  failed
}

class MessageThread {
  final String id;
  final String partnerId;
  final String clientId;
  final String clientName;
  final String clientAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final bool hasUnread;
  final int unreadCount;
  final String? residenceId;
  final String? residenceName;
  final String? reservationId;

  MessageThread({
    required this.id,
    required this.partnerId,
    required this.clientId,
    required this.clientName,
    required this.clientAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.hasUnread,
    required this.unreadCount,
    this.residenceId,
    this.residenceName,
    this.reservationId,
  });

  factory MessageThread.fromJson(Map<String, dynamic> json) {
    return MessageThread(
      id: json['id'],
      partnerId: json['partnerId'],
      clientId: json['clientId'],
      clientName: json['clientName'],
      clientAvatar: json['clientAvatar'],
      lastMessage: json['lastMessage'],
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
      hasUnread: json['hasUnread'],
      unreadCount: json['unreadCount'],
      residenceId: json['residenceId'],
      residenceName: json['residenceName'],
      reservationId: json['reservationId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partnerId': partnerId,
      'clientId': clientId,
      'clientName': clientName,
      'clientAvatar': clientAvatar,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'hasUnread': hasUnread,
      'unreadCount': unreadCount,
      'residenceId': residenceId,
      'residenceName': residenceName,
      'reservationId': reservationId,
    };
  }
}
