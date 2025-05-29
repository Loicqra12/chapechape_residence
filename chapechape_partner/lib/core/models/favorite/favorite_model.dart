import 'package:equatable/equatable.dart';
import '../residence/residence.dart';

/// Modèle représentant une résidence mise en favoris par un partenaire
class FavoriteModel extends Equatable {
  final String id;
  final String residenceId;
  final String partnerId;
  final DateTime createdAt;
  final Residence? residence; // Détails optionnels de la résidence
  
  const FavoriteModel({
    required this.id,
    required this.residenceId,
    required this.partnerId,
    required this.createdAt,
    this.residence,
  });
  
  @override
  List<Object?> get props => [id, residenceId, partnerId, createdAt, residence];
  
  /// Crée un objet FavoriteModel à partir d'une réponse JSON de l'API
  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['_id'] ?? json['id'] ?? '',
      residenceId: json['residenceId'] ?? '',
      partnerId: json['partnerId'] ?? json['userId'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      residence: json['residence'] != null 
          ? Residence.fromJson(json['residence']) 
          : null,
    );
  }
  
  /// Convertit l'objet en format JSON pour l'API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'residenceId': residenceId,
      'partnerId': partnerId,
      'createdAt': createdAt.toIso8601String(),
      if (residence != null) 'residence': residence?.toJson(),
    };
  }
  
  /// Crée une copie de l'objet avec certains champs modifiés
  FavoriteModel copyWith({
    String? id,
    String? residenceId,
    String? partnerId,
    DateTime? createdAt,
    Residence? residence,
  }) {
    return FavoriteModel(
      id: id ?? this.id,
      residenceId: residenceId ?? this.residenceId,
      partnerId: partnerId ?? this.partnerId,
      createdAt: createdAt ?? this.createdAt,
      residence: residence ?? this.residence,
    );
  }
}
