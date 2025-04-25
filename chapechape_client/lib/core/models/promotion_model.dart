import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'residence_model.dart';

part 'promotion_model.freezed.dart';
part 'promotion_model.g.dart';

/// Modèle représentant une offre ou promotion exclusive
@freezed
class Promotion with _$Promotion {
  const factory Promotion({
    required String id,
    required String title,
    required String description,
    required double discountPercentage,
    String? discountCode,
    required DateTime startDate,
    required DateTime endDate,
    required String imageUrl,
    required String residenceId,
    Residence? residence,
    String? badge,
    @Default(false) bool isExclusive,
    @Default(PromotionType.discount) PromotionType type,
    String? termsAndConditions,
  }) = _Promotion;

  factory Promotion.fromJson(Map<String, dynamic> json) => 
      _$PromotionFromJson(json);
}

/// Types de promotions disponibles
enum PromotionType {
  discount,    // Réduction de prix standard
  flash,       // Offre flash limitée dans le temps
  seasonal,    // Promotion saisonnière
  bundle,      // Forfait incluant plusieurs services
  exclusive,   // Offre exclusive pour membres VIP
  newUser      // Offre spéciale pour nouveaux utilisateurs
}

/// Extensions sur le type PromotionType pour faciliter l'affichage
extension PromotionTypeExtension on PromotionType {
  String get displayName {
    switch (this) {
      case PromotionType.discount:
        return 'Réduction';
      case PromotionType.flash:
        return 'Offre Flash';
      case PromotionType.seasonal:
        return 'Offre Saisonnière';
      case PromotionType.bundle:
        return 'Forfait';
      case PromotionType.exclusive:
        return 'Exclusivité';
      case PromotionType.newUser:
        return 'Nouveau Client';
    }
  }
  
  String get badgeColor {
    switch (this) {
      case PromotionType.discount:
        return '#4CAF50'; // Vert
      case PromotionType.flash:
        return '#F44336'; // Rouge
      case PromotionType.seasonal:
        return '#2196F3'; // Bleu
      case PromotionType.bundle:
        return '#9C27B0'; // Violet
      case PromotionType.exclusive:
        return '#FFC107'; // Jaune doré
      case PromotionType.newUser:
        return '#00BCD4'; // Cyan
    }
  }
  
  String get icon {
    switch (this) {
      case PromotionType.discount:
        return 'assets/icons/discount.png';
      case PromotionType.flash:
        return 'assets/icons/flash.png';
      case PromotionType.seasonal:
        return 'assets/icons/seasonal.png';
      case PromotionType.bundle:
        return 'assets/icons/bundle.png';
      case PromotionType.exclusive:
        return 'assets/icons/exclusive.png';
      case PromotionType.newUser:
        return 'assets/icons/new_user.png';
    }
  }
}

/// Extension sur le modèle Promotion pour ajouter des fonctionnalités utiles
extension PromotionExtension on Promotion {
  /// Vérifie si la promotion est active à la date donnée (ou aujourd'hui par défaut)
  bool isActive([DateTime? date]) {
    final now = date ?? DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
  
  /// Calcule le prix après réduction pour un montant donné
  double calculateDiscountedPrice(double originalPrice) {
    return originalPrice * (1 - discountPercentage / 100);
  }
  
  /// Retourne le temps restant sous forme de texte
  String get timeRemaining {
    final now = DateTime.now();
    final difference = endDate.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    }
  }
  
  /// Détermine si c'est une offre de dernière minute (moins de 24h restantes)
  bool get isLastMinute {
    final now = DateTime.now();
    final difference = endDate.difference(now);
    return difference.inHours < 24 && difference.inHours > 0;
  }
}
