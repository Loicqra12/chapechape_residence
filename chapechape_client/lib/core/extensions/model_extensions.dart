import 'package:chapechape_client/core/models/residence_model.dart';
import 'package:chapechape_client/core/constants/app_assets.dart' as assets;
import '../models/residence_type_enum.dart';

/// NOTE IMPORTANTE: 
/// La plupart des extensions sur Residence ont été déplacées directement dans la classe Residence
/// ou dans residence_model_alias.dart pour rationaliser le code et éviter les doublons.
/// 
/// Voir:
/// - lib/core/models/residence_model.dart: Pour les méthodes principales
/// - lib/core/models/residence_model_alias.dart: Pour la compatibilité
/// - lib/core/models/residence_type_enum.dart: Pour les extensions de types

// Ces extensions ont été conservées temporairement pour référence

// SUPPRIMÉ: Cette extension est déjà définie dans residence_model.dart
// Garder cette note pour la documentation

/// Extensions supplémentaires pour le modèle Residence qui ne sont pas déjà présentes ailleurs
extension ResidenceFormatting on Residence {
  /// Retourne une description courte formatée
  String get shortDescriptionText {
    final buffer = StringBuffer();
    buffer.write('$bedrooms chambre${bedrooms > 1 ? 's' : ''} • ');
    buffer.write('$bathrooms salle${bathrooms > 1 ? 's' : ''} de bain • ');
    buffer.write('${squareMeters.toStringAsFixed(0)} m²');
    return buffer.toString();
  }
  
  /// Retourne une description de la capacité
  String get capacityDescription {
    final baseGuests = bedrooms * 2;
    return 'Jusqu\'à $baseGuests personnes';
  }
  
  /// Conversion entre le ResidenceType du modèle et le type d'assets
  assets.ResidenceType toAssetResidenceType() {
    return assets.convertModelTypeToAssetType(type);
  }
  
  /// Retourne une estimation du prix total pour un séjour donné
  double estimateTotalPrice(DateTime checkIn, DateTime checkOut) {
    // Différence en jours
    final days = checkOut.difference(checkIn).inDays;
    
    if (days <= 0) {
      return 0;
    }
    
    // Calcul du prix en fonction du type de période
    switch (pricePeriod.toLowerCase()) {
      case 'hour':
        return hourlyRate * 24 * days;
      case 'day':
        return fullDayRate * days;
      case 'week':
        final weeks = (days / 7).ceil();
        return price * weeks;
      case 'month':
        final months = (days / 30).ceil();
        return price * months;
      default:
        return price;
    }
  }
}

/// Extension pour la gestion des adresses (implémentation simplifiée)
extension AddressExtension on String {
  /// Retourne une version courte de l'adresse (quartier/ville)
  String get shortAddress {
    final parts = split(',');
    if (parts.length > 1) {
      return parts[0].trim();
    }
    return this;
  }
  
  /// Retourne la ville d'une adresse
  String get city {
    final parts = split(',');
    if (parts.length > 1) {
      return parts[1].trim();
    }
    return this;
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
  
  String toTitleCase() {
    return split(' ').map((word) => word.capitalize()).join(' ');
  }
  
  ResidenceType toResidenceType() {
    return ResidenceTypeExtension.fromString(this);
  }
}

extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
