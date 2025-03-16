import 'package:equatable/equatable.dart';
import '../residence/residence.dart';
import '../user/user.dart';

/// Représente une réservation dans le système ChapeChape
class Booking extends Equatable {
  final String id;
  final String residenceId;
  final String clientId;
  final String partnerId;
  final String status; // pending, confirmed, cancelled, completed, refunded
  final DateTime visitDate;
  final String visitTime;
  final DateTime createdAt;
  final String? notes;
  final Map<String, dynamic>? metadata;
  
  // Relations optionnelles pour chargement approfondies
  final Residence? residence;
  final User? client;
  final User? partner;

  const Booking({
    required this.id,
    required this.residenceId,
    required this.clientId, 
    required this.partnerId,
    required this.status,
    required this.visitDate,
    required this.visitTime,
    required this.createdAt,
    this.notes,
    this.metadata,
    this.residence,
    this.client,
    this.partner,
  });

  /// Crée une réservation à partir d'un Map JSON
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      residenceId: json['residenceId'] as String,
      clientId: json['clientId'] as String,
      partnerId: json['partnerId'] as String,
      status: json['status'] as String,
      visitDate: DateTime.parse(json['visitDate'] as String),
      visitTime: json['visitTime'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      residence: json['residence'] != null 
          ? Residence.fromJson(json['residence'] as Map<String, dynamic>)
          : null,
      client: json['client'] != null 
          ? User.fromJson(json['client'] as Map<String, dynamic>)
          : null,
      partner: json['partner'] != null 
          ? User.fromJson(json['partner'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convertit la réservation en Map JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'residenceId': residenceId,
      'clientId': clientId,
      'partnerId': partnerId,
      'status': status,
      'visitDate': visitDate.toIso8601String(),
      'visitTime': visitTime,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
      'metadata': metadata,
      // Relations optionnelles
      if (residence != null) 'residence': residence!.toJson(),
      if (client != null) 'client': client!.toJson(),
      if (partner != null) 'partner': partner!.toJson(),
    };
  }

  /// Crée une nouvelle instance avec certaines valeurs modifiées
  Booking copyWith({
    String? id,
    String? residenceId,
    String? clientId,
    String? partnerId,
    String? status,
    DateTime? visitDate,
    String? visitTime,
    DateTime? createdAt,
    String? notes,
    Map<String, dynamic>? metadata,
    Residence? residence,
    User? client,
    User? partner,
  }) {
    return Booking(
      id: id ?? this.id,
      residenceId: residenceId ?? this.residenceId,
      clientId: clientId ?? this.clientId,
      partnerId: partnerId ?? this.partnerId,
      status: status ?? this.status,
      visitDate: visitDate ?? this.visitDate,
      visitTime: visitTime ?? this.visitTime,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      residence: residence ?? this.residence,
      client: client ?? this.client,
      partner: partner ?? this.partner,
    );
  }

  @override
  List<Object?> get props => [
    id, 
    residenceId, 
    clientId, 
    partnerId, 
    status, 
    visitDate, 
    visitTime, 
    createdAt, 
    notes, 
    metadata
  ];
}