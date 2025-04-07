import 'package:flutter/foundation.dart';
import '../../config/twilio_config.dart';

/// Modèle pour les préférences de notification d'un utilisateur (version simplifiée)
class NotificationPreference {
  /// ID de l'utilisateur
  final String userId;
  
  /// Types de notifications activés (ex: residence_created: true)
  final Map<String, bool> types;
  
  /// Canaux activés (ex: sms: true)
  final Map<String, bool> channels;
  
  /// Numéro de téléphone pour les SMS (si différent du numéro principal)
  final String? phoneNumber;
  
  /// Email pour les notifications (si différent de l'email principal)
  final String? email;
  
  /// Ne pas déranger: début (heure de la journée, format 24h)
  final int quietHoursStart;
  
  /// Ne pas déranger: fin
  final int quietHoursEnd;
  
  /// Date de dernière mise à jour
  final DateTime updatedAt;

  NotificationPreference({
    required this.userId,
    Map<String, bool>? types,
    Map<String, bool>? channels,
    this.phoneNumber,
    this.email,
    this.quietHoursStart = 22,
    this.quietHoursEnd = 7,
    required this.updatedAt,
  }) : 
    this.types = types ?? {},
    this.channels = channels ?? {};

  /// Crée une copie avec certaines valeurs modifiées
  NotificationPreference copyWith({
    String? userId,
    Map<String, bool>? types,
    Map<String, bool>? channels,
    String? phoneNumber,
    String? email,
    int? quietHoursStart,
    int? quietHoursEnd,
    DateTime? updatedAt,
  }) {
    return NotificationPreference(
      userId: userId ?? this.userId,
      types: types ?? Map.from(this.types),
      channels: channels ?? Map.from(this.channels),
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// Convertit l'objet en JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'types': types,
      'channels': channels,
      'phoneNumber': phoneNumber,
      'email': email,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  /// Crée un objet à partir du JSON
  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      userId: json['userId'],
      types: Map<String, bool>.from(json['types'] ?? {}),
      channels: Map<String, bool>.from(json['channels'] ?? {}),
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      quietHoursStart: json['quietHoursStart'] ?? 22,
      quietHoursEnd: json['quietHoursEnd'] ?? 7,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }
  
  /// Crée une instance par défaut pour un utilisateur
  factory NotificationPreference.defaultForUser(String userId) {
    return NotificationPreference(
      userId: userId,
      types: Map<String, bool>.from(TwilioConfig.defaultNotificationPreferences),
      channels: Map<String, bool>.from(TwilioConfig.defaultChannels),
      updatedAt: DateTime.now(),
    );
  }
  
  @override
  String toString() {
    return 'NotificationPreference(userId: $userId, types: $types, channels: $channels)';
  }
} 