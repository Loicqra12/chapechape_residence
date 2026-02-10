import 'package:flutter/foundation.dart';

/// Modèle pour une notification (version simplifiée)
class NotificationModel {
  /// Identifiant unique de la notification
  final String id;
  
  /// Titre de la notification
  final String title;
  
  /// Message/contenu de la notification
  final String message;
  
  /// Date et heure de la notification
  final DateTime timestamp;
  
  /// Si la notification a été lue
  final bool isRead;
  
  /// URL d'image à afficher (optionnelle)
  final String? imageUrl;
  
  /// URL d'action au clic sur la notification
  final String? actionUrl;
  
  /// Données additionnelles associées à la notification
  final Map<String, dynamic>? actionData;
  
  /// Type de notification (ex: residence, booking, message)
  final String type;
  
  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.actionUrl,
    this.actionData,
    required this.type,
  });
  
  /// Crée une copie avec certaines valeurs modifiées
  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
    String? actionUrl,
    Map<String, dynamic>? actionData,
    String? type,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      actionData: actionData ?? this.actionData,
      type: type ?? this.type,
    );
  }
  
  /// Convertit l'objet en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'actionData': actionData,
      'type': type,
    };
  }
  
  /// Crée un objet à partir du JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? json['data']?['title'] ?? 'Notification',
      message: json['message'] ?? '',
      timestamp: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : (json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now()),
      isRead: json['read'] ?? json['isRead'] ?? false,
      imageUrl: json['imageUrl'] ?? json['data']?['imageUrl'],
      actionUrl: json['actionUrl'] ?? json['data']?['actionUrl'],
      actionData: json['data'] != null 
          ? Map<String, dynamic>.from(json['data']) 
          : null,
      type: json['type'] ?? 'system',
    );
  }
  
  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: $type, isRead: $isRead)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}

/// Modèle pour la réponse paginée des notifications
class PaginatedNotifications {
  final List<NotificationModel> notifications;
  final int total;
  final int page;
  final int pages;
  final int unreadCount;

  PaginatedNotifications({
    required this.notifications,
    required this.total,
    required this.page,
    required this.pages,
    this.unreadCount = 0,
  });

  factory PaginatedNotifications.fromJson(Map<String, dynamic> json) {
    final List<dynamic> list = json['notifications'] ?? [];
    final notifications = list.map((item) => NotificationModel.fromJson(item)).toList();
    
    return PaginatedNotifications(
      notifications: notifications,
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pages: json['pages'] ?? 1,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
} 