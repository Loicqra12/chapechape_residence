import 'package:equatable/equatable.dart';
import '../residence/residence.dart';

/// Modèle représentant les détails de notation par catégorie
class RatingDetails extends Equatable {
  final double overall;
  final double cleanliness;
  final double comfort;
  final double facilities;
  final double value;
  final double location;
  
  const RatingDetails({
    required this.overall,
    required this.cleanliness,
    required this.comfort,
    required this.facilities,
    required this.value,
    required this.location,
  });
  
  @override
  List<Object?> get props => [
    overall, cleanliness, comfort, facilities, value, location
  ];
  
  /// Crée un objet RatingDetails à partir d'une réponse JSON de l'API
  factory RatingDetails.fromJson(Map<String, dynamic> json) {
    return RatingDetails(
      overall: json['overall']?.toDouble() ?? 0.0,
      cleanliness: json['cleanliness']?.toDouble() ?? 0.0,
      comfort: json['comfort']?.toDouble() ?? 0.0,
      facilities: json['facilities']?.toDouble() ?? 0.0,
      value: json['value']?.toDouble() ?? 0.0,
      location: json['location']?.toDouble() ?? 0.0,
    );
  }
  
  /// Convertit l'objet en format JSON pour l'API
  Map<String, dynamic> toJson() {
    return {
      'overall': overall,
      'cleanliness': cleanliness,
      'comfort': comfort,
      'facilities': facilities,
      'value': value,
      'location': location,
    };
  }
  
  /// Crée une copie de l'objet avec certains champs modifiés
  RatingDetails copyWith({
    double? overall,
    double? cleanliness,
    double? comfort,
    double? facilities,
    double? value,
    double? location,
  }) {
    return RatingDetails(
      overall: overall ?? this.overall,
      cleanliness: cleanliness ?? this.cleanliness,
      comfort: comfort ?? this.comfort,
      facilities: facilities ?? this.facilities,
      value: value ?? this.value,
      location: location ?? this.location,
    );
  }
  
  /// Calcule la moyenne de toutes les catégories
  double get average {
    return (overall + cleanliness + comfort + facilities + value + location) / 6;
  }
}

/// Modèle représentant un avis sur une résidence
class ReviewModel extends Equatable {
  final String id;
  final String residenceId;
  final String userId;
  final String? userFullName;
  final String? userProfileImage;
  final RatingDetails rating;
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> images;
  final String? response;
  final DateTime? responseDate;
  final Residence? residence;
  
  const ReviewModel({
    required this.id,
    required this.residenceId,
    required this.userId,
    this.userFullName,
    this.userProfileImage,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
    required this.images,
    this.response,
    this.responseDate,
    this.residence,
  });
  
  @override
  List<Object?> get props => [
    id, residenceId, userId, userFullName, userProfileImage, 
    rating, comment, createdAt, updatedAt, images, 
    response, responseDate, residence
  ];
  
  /// Crée un objet ReviewModel à partir d'une réponse JSON de l'API
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    List<String> imagesList = [];
    if (json['images'] != null) {
      imagesList = List<String>.from(json['images']);
    }
    
    return ReviewModel(
      id: json['_id'] ?? json['id'] ?? '',
      residenceId: json['residenceId'] ?? json['residence'] ?? '',
      userId: json['userId'] ?? json['user'] ?? '',
      userFullName: json['userFullName'] ?? json['userName'] ?? '',
      userProfileImage: json['userProfileImage'] ?? json['userImage'],
      rating: json['rating'] != null 
          ? RatingDetails.fromJson(json['rating'])
          : const RatingDetails(
              overall: 0.0,
              cleanliness: 0.0,
              comfort: 0.0,
              facilities: 0.0,
              value: 0.0,
              location: 0.0,
            ),
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      images: imagesList,
      response: json['response'],
      responseDate: json['responseDate'] != null 
          ? DateTime.parse(json['responseDate']) 
          : null,
      residence: json['residence'] != null && json['residence'] is Map<String, dynamic> 
          ? Residence.fromJson(json['residence']) 
          : null,
    );
  }
  
  /// Convertit l'objet en format JSON pour l'API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'residenceId': residenceId,
      'userId': userId,
      if (userFullName != null) 'userFullName': userFullName,
      if (userProfileImage != null) 'userProfileImage': userProfileImage,
      'rating': rating.toJson(),
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'images': images,
      if (response != null) 'response': response,
      if (responseDate != null) 'responseDate': responseDate!.toIso8601String(),
    };
  }
  
  /// Crée une copie de l'objet avec certains champs modifiés
  ReviewModel copyWith({
    String? id,
    String? residenceId,
    String? userId,
    String? userFullName,
    String? userProfileImage,
    RatingDetails? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? images,
    String? response,
    DateTime? responseDate,
    Residence? residence,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      residenceId: residenceId ?? this.residenceId,
      userId: userId ?? this.userId,
      userFullName: userFullName ?? this.userFullName,
      userProfileImage: userProfileImage ?? this.userProfileImage,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      images: images ?? this.images,
      response: response ?? this.response,
      responseDate: responseDate ?? this.responseDate,
      residence: residence ?? this.residence,
    );
  }
}
