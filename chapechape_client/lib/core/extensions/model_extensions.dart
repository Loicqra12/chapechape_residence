import 'package:chapechape_client/core/models/residence_model.dart';
import 'package:chapechape_client/core/constants/app_assets.dart' as assets;

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
    return type == ResidenceType.luxury || type == ResidenceType.hotel ||
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

/// Extensions supplémentaires pour le modèle Residence
/// Note: La plupart des extensions ont été déplacées directement dans la classe Residence
extension ResidenceExtensions on Residence {
  /// Retourne le nom d'affichage pour le type de résidence
  String get typeDisplayName {
    final assetType = toAssetResidenceType();
    switch (assetType) {
      case assets.ResidenceType.apartment:
        return 'Appartement';
      case assets.ResidenceType.studio:
        return 'Studio';
      case assets.ResidenceType.villa:
        return 'Villa';
      case assets.ResidenceType.bungalow:
        return 'Bungalow';
      case assets.ResidenceType.luxury:
        return 'Résidence de Luxe';
      case assets.ResidenceType.hotel:
        return 'Hôtel';
      default:
        return 'Résidence';
    }
  }
  
  /// Retourne une description courte
  String get shortDescription {
    final buffer = StringBuffer();
    buffer.write('$bedrooms chambre${bedrooms > 1 ? 's' : ''} • ');
    buffer.write('$bathrooms salle${bathrooms > 1 ? 's' : ''} de bain • ');
    buffer.write('${surface.toStringAsFixed(0)} m²');
    return buffer.toString();
  }
  
  /// Retourne une description de la capacité
  String get capacityDescription {
    final baseGuests = bedrooms * 2;
    return 'Jusqu\'à $baseGuests personnes';
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
