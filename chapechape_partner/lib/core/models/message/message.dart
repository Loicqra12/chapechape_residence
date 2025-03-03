import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final String receiverName;
  final String receiverRole;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? attachmentUrl;
  final String messageType;
  final Map<String, dynamic>? metadata;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.receiverName,
    required this.receiverRole,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.attachmentUrl,
    this.messageType = 'text',
    this.metadata,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      receiverName: json['receiverName'] ?? '',
      receiverRole: json['receiverRole'] ?? 'client',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null 
        ? DateTime.parse(json['timestamp']) 
        : DateTime.now(),
      isRead: json['isRead'] ?? false,
      attachmentUrl: json['attachmentUrl'],
      messageType: json['messageType'] ?? 'text',
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverRole': receiverRole,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'attachmentUrl': attachmentUrl,
      'messageType': messageType,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
    id,
    senderId,
    receiverId,
    receiverName,
    receiverRole,
    content,
    timestamp,
    isRead,
    attachmentUrl,
    messageType,
    metadata,
  ];

  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? receiverName,
    String? receiverRole,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    String? attachmentUrl,
    String? messageType,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverRole: receiverRole ?? this.receiverRole,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      messageType: messageType ?? this.messageType,
      metadata: metadata ?? this.metadata,
    );
  }
}
