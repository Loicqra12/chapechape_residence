import 'package:chapechape_client/core/models/residence_model.dart';
import 'package:chapechape_client/core/constants/app_assets.dart';

/// Extensions pour le modèle Residence
extension ResidenceProperties on Residence {
  /// Retourne l'URL de la première image ou une image par défaut
  String get imageUrl {
    if (images != null && images!.isNotEmpty && images!.first.isNotEmpty) {
      return images!.first;
    }
    return getDefaultImageByType();
  }

  /// Alias pour le nom de la résidence
  String get title => name ?? 'Résidence sans nom';

  /// Retourne "available" ou "unavailable" selon l'état isAvailable
  String get status => isAvailable ? 'available' : 'unavailable';

  /// Indique si la résidence a une piscine
  bool get hasPool {
    return amenities != null && amenities!.contains('pool');
  }

  /// Indique si c'est une résidence de vacances
  bool get isVacationResidence {
    return type == ResidenceType.villa || type == ResidenceType.bungalow || 
           (amenities != null && amenities!.contains('vacation'));
  }

  /// Indique si c'est une résidence spéciale
  bool get isSpecialResidence {
    return type == ResidenceType.luxury || type == ResidenceType.penthouse ||
           (amenities != null && amenities!.contains('special'));
  }
}

/// Extension pour extraire l'adresse formatée d'un dictionnaire de localisation
extension LocationExtension on Map<String, dynamic> {
  /// Extrait l'adresse formatée du dictionnaire de localisation
  String get displayAddress {
    final String street = this['street'] ?? '';
    final String city = this['city'] ?? '';
    final String country = this['country'] ?? '';
    
    if (street.isNotEmpty && city.isNotEmpty) {
      return '$street, $city${country.isNotEmpty ? ', $country' : ''}';
    } else if (city.isNotEmpty) {
      return city + (country.isNotEmpty ? ', $country' : '');
    } else if (country.isNotEmpty) {
      return country;
    }
    
    return this['formatted'] ?? this['display'] ?? 'Adresse non disponible';
  }
}
