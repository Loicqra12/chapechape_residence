import 'package:equatable/equatable.dart';
import '../residence/residence.dart';

/// Types de promotions disponibles
enum PromotionType {
  discount, // Réduction simple sur le prix
  flash,    // Promotion de courte durée
  seasonal, // Promotion saisonnière
  bundle,   // Bundle d'offres
  exclusive, // Offre exclusive
  newUser   // Promotion pour nouveaux utilisateurs
}

/// Extension pour convertir le type de promotion en string
extension PromotionTypeExtension on PromotionType {
  String get value {
    switch (this) {
      case PromotionType.discount: return 'discount';
      case PromotionType.flash: return 'flash';
      case PromotionType.seasonal: return 'seasonal';
      case PromotionType.bundle: return 'bundle';
      case PromotionType.exclusive: return 'exclusive';
      case PromotionType.newUser: return 'newUser';
    }
  }
  
  static PromotionType fromString(String value) {
    switch (value) {
      case 'discount': return PromotionType.discount;
      case 'flash': return PromotionType.flash;
      case 'seasonal': return PromotionType.seasonal;
      case 'bundle': return PromotionType.bundle;
      case 'exclusive': return PromotionType.exclusive;
      case 'newUser': return PromotionType.newUser;
      default: return PromotionType.discount;
    }
  }
}

/// Modèle représentant une promotion ou offre spéciale
class PromotionModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final PromotionType type;
  final double discountPercentage;
  final double? discountAmount;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool isExclusive;
  final String? residenceId;
  final Residence? residence;
  final String? code;
  final int usageLimit;
  final int usageCount;
  final String? imageUrl;
  
  const PromotionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.discountPercentage,
    this.discountAmount,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.isExclusive,
    this.residenceId,
    this.residence,
    this.code,
    required this.usageLimit,
    required this.usageCount,
    this.imageUrl,
  });
  
  @override
  List<Object?> get props => [
    id, title, description, type, discountPercentage, discountAmount,
    startDate, endDate, isActive, isExclusive, residenceId, residence,
    code, usageLimit, usageCount, imageUrl
  ];
  
  /// Crée un objet PromotionModel à partir d'une réponse JSON de l'API
  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] != null 
          ? PromotionTypeExtension.fromString(json['type']) 
          : PromotionType.discount,
      discountPercentage: json['discountPercentage']?.toDouble() ?? 0.0,
      discountAmount: json['discountAmount']?.toDouble(),
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate']) 
          : DateTime.now(),
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate']) 
          : DateTime.now().add(const Duration(days: 30)),
      isActive: json['isActive'] ?? false,
      isExclusive: json['isExclusive'] ?? false,
      residenceId: json['residenceId'],
      residence: json['residence'] != null 
          ? Residence.fromJson(json['residence']) 
          : null,
      code: json['code'],
      usageLimit: json['usageLimit'] ?? 0,
      usageCount: json['usageCount'] ?? 0,
      imageUrl: json['imageUrl'],
    );
  }
  
  /// Convertit l'objet en format JSON pour l'API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.value,
      'discountPercentage': discountPercentage,
      if (discountAmount != null) 'discountAmount': discountAmount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'isExclusive': isExclusive,
      if (residenceId != null) 'residenceId': residenceId,
      if (code != null) 'code': code,
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
  
  /// Crée une copie de l'objet avec certains champs modifiés
  PromotionModel copyWith({
    String? id,
    String? title,
    String? description,
    PromotionType? type,
    double? discountPercentage,
    double? discountAmount,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? isExclusive,
    String? residenceId,
    Residence? residence,
    String? code,
    int? usageLimit,
    int? usageCount,
    String? imageUrl,
  }) {
    return PromotionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountAmount: discountAmount ?? this.discountAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      isExclusive: isExclusive ?? this.isExclusive,
      residenceId: residenceId ?? this.residenceId,
      residence: residence ?? this.residence,
      code: code ?? this.code,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
  
  /// Vérifie si la promotion est en cours (entre les dates de début et de fin)
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }
  
  /// Calcule le montant de la réduction pour un prix donné
  double calculateDiscount(double price) {
    if (discountAmount != null) {
      return discountAmount!;
    }
    return price * (discountPercentage / 100);
  }
  
  /// Calcule le prix après réduction
  double calculateDiscountedPrice(double originalPrice) {
    final discount = calculateDiscount(originalPrice);
    return originalPrice - discount;
  }
}
