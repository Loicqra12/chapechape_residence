import '../models/residence_model.dart';
import '../models/residence_type_enum.dart' as model;
import '../constants/app_assets.dart';

/// Extensions pour le modèle Residence
extension ResidenceProperties on Residence {
  /// Retourne l'URL de la première image ou une image par défaut
  String get imageUrl => images.isNotEmpty 
      ? images.first 
      : AppAssets.placeholderImage;

  /// Alias pour le nom de la résidence
  String get title => name;

  /// Retourne le statut de disponibilité
  String get status => isAvailable ? "available" : "unavailable";

  /// Vérifie si la résidence a une piscine
  bool get hasPool {
    // Vérification distincte pour chaque type d'amenité
    if (amenities.contains('pool')) return true;
    if (amenities.contains('piscine')) return true;
    return false;
  }

  /// Vérifie si c'est une résidence de vacances
  bool get isVacationResidence => type == 'vacation' || type == 'vacances';

  /// Vérifie si c'est une résidence spéciale
  bool get isSpecial {
    // Utilisation de l'opérateur ?. pour un accès sécurisé à isSpecial
    final isSpecialValue = priceDetails?['isSpecial'];
    return isSpecialValue == true;
  }
  
  /// Obtient le prix avec réduction s'il existe
  double get discountedPrice {
    // Utilisation de l'opérateur ?. pour un accès sécurisé à discountedPrice
    final discounted = priceDetails?['discountedPrice'];
    if (discounted is num && discounted > 0) {
      return discounted.toDouble();
    }
    return price;
  }
}

/// Extension pour extraire l'adresse formatée d'un Map de localisation
extension LocationExtension on Map<String, dynamic>? {
  /// Retourne l'adresse formatée à partir de la map de localisation
  String get displayAddress {
    // Si la map est null, retourner une chaîne vide
    final map = this;
    if (map == null) return '';
    
    // Si une adresse formatée est disponible, la retourner directement
    if (map.containsKey('formattedAddress')) {
      return map['formattedAddress'] as String;
    }
    
    // Sinon, construire l'adresse à partir des composants individuels
    final parts = <String>[];
    
    if (map.containsKey('street')) {
      parts.add(map['street'] as String);
    }
    
    if (map.containsKey('city')) {
      parts.add(map['city'] as String);
    }
    
    if (map.containsKey('country')) {
      parts.add(map['country'] as String);
    }
    
    return parts.join(', ');
  }
}

/// Classe utilitaire pour adapter les modèles de Residence
class ResidenceAdapters {
  /// Récupère le nom d'affichage d'un type de résidence
  static String getTypeDisplayName(dynamic type) {
    if (type == null) return 'Autre';
    
    // Si c'est déjà un ResidenceType, utiliser son displayName
    if (type is ResidenceType) {
      return type.displayName;
    }
    
    // Si c'est une chaîne, convertir en type de l'asset et utiliser son nom
    if (type is String) {
      final assetType = convertModelTypeToAssetType(type);
      return assetType.displayName;
    }
    
    return 'Autre';
  }
  
  /// Récupère le chemin d'icône pour un type de résidence
  static String getTypeIconPath(dynamic type) {
    if (type == null) return AppAssets.iconOther;
    
    if (type is ResidenceType) {
      return type.iconPath;
    }
    
    // Traiter comme une String
    if (type is String) {
      final assetType = convertModelTypeToAssetType(type);
      return assetType.iconPath;
    }
    
    return AppAssets.iconOther;
  }
  
  /// Vérifie si une résidence est de luxe
  static bool isLuxuryResidence(Residence residence) {
    // Vérifier d'abord si la résidence est marquée comme spéciale
    if (residence.isSpecialResidence) {
      return true;
    }
    
    // Vérification combinée avec opérateur conditionnel sécurisé
    return residence.priceDetails?.containsKey('isLuxury') == true && 
           residence.priceDetails?['isLuxury'] == true;
  }
  
  /// Récupère le prix formaté d'une résidence
  static String getFormattedPrice(Residence residence, {bool withCurrency = true}) {
    if (residence.formattedPrice.isNotEmpty) {
      return residence.formattedPrice;
    }
    
    double price = residence.price;
    
    // Note: discountedPrice a été ajouté via l'extension ResidenceProperties
    final priceDetails = residence.priceDetails;
    if (priceDetails != null && priceDetails.containsKey('discountedPrice')) {
      final discounted = priceDetails['discountedPrice'];
      if (discounted is num && discounted > 0) {
        price = discounted.toDouble();
      }
    }
    
    return withCurrency 
        ? '$price FCFA' 
        : price.toString();
  }
  
  /// Récupère une description courte de la résidence
  static String getShortDescription(Residence residence) {
    // Vérifier si une description courte existe déjà
    if (residence.shortDescription.isNotEmpty) {
      return residence.shortDescription;
    }
    
    // Extraire les informations de base
    final bedroomsCount = residence.bedrooms ?? 0;
    final bathroomsCount = residence.bathrooms ?? 0;
    
    // Extraction sécurisée de la surface
    int surface = 0;
    final priceDetails = residence.priceDetails;
    // Utilisation de l'opérateur ?. pour éviter l'avertissement de lint
    if (priceDetails?.containsKey('surface') ?? false) {
      // Utilisation de l'opérateur ?. également ici pour assurer la sécurité du null
      final surfaceValue = priceDetails?['surface'];
      if (surfaceValue is num) {
        surface = surfaceValue.toInt();
      }
    }
    
    return '$bedroomsCount chambres · $bathroomsCount sdb · ${surface}m²';
  }
  
  /// Crée une instance de Residence à partir de données simples
  static Residence createResidence({
    required String id,
    required String title,
    required double price,
    required String imageUrl,
    String? city,
    String? address,
    String? country,
    int? bedrooms,
    int? bathrooms,
    double? squareMeters,
    bool? hasPool,
    bool? hasWifi,
    bool? isVacationResidence,
    bool? isSpecialResidence,
    bool? isFavorite,
    bool? isAvailable,
    bool? isFeatured,
    bool? isPopular,
    bool? isVerified,
    bool? isNew,
    double? rating,
    int? reviewCount,
    String? currency,
    dynamic type,
    int? maxOccupancy,
    String? owner,
  }) {
    final Map<String, dynamic> location = {};
    if (city != null) location['city'] = city;
    if (address != null) location['street'] = address;
    if (country != null) location['country'] = country;
    if (address != null && city != null) {
      location['formattedAddress'] = '$address, $city';
    }
    
    final Map<String, dynamic> priceDetails = {};
    if (squareMeters != null) priceDetails['surface'] = squareMeters;
    if (isFavorite != null) priceDetails['isFavorite'] = isFavorite;
    
    final List<String> amenities = [];
    if (hasPool == true) amenities.add('pool');
    if (hasWifi == true) amenities.add('wifi');
    
    // Convertir le type en string si c'est un ResidenceType
    String typeString = 'other';
    if (type is ResidenceType) {
      typeString = type.toString().split('.').last;
    } else if (type is model.ResidenceType) {
      typeString = type.toString().split('.').last;
    } else if (type is String) {
      typeString = type;
    }
    
    // Convertir en enum ResidenceType
    final model.ResidenceType residenceType = parseResidenceTypeString(typeString);
    
    return Residence(
      id: id,
      title: title,
      description: '',
      shortDescription: '',
      images: [imageUrl],
      price: price,
      location: location,
      bedrooms: bedrooms ?? 0,
      bathrooms: bathrooms ?? 0,
      squareMeters: squareMeters ?? 0.0,
      amenities: amenities,
      hasPool: hasPool ?? false,
      hasWifi: hasWifi ?? false,
      isVacationResidence: isVacationResidence ?? false,
      isSpecialResidence: isSpecialResidence ?? false,
      isAvailable: isAvailable ?? true,
      isFeatured: isFeatured ?? false,
      isPopular: isPopular ?? false,
      isVerified: isVerified ?? false,
      isNew: isNew ?? false,
      rating: rating ?? 0.0,
      reviewCount: reviewCount ?? 0,
      currency: currency ?? 'FCFA',
      type: residenceType,
      maxOccupancy: maxOccupancy ?? 2,
      owner: owner ?? 'ChapeChape',
      pricePeriod: 'night',
      hourlyRate: 0,
      halfDayRate: 0,
      fullDayRate: 0,
      weekendRate: 0,
    );
  }
  
  /// Analyse une chaîne de caractères pour déterminer le type de résidence
  static model.ResidenceType parseResidenceTypeString(String value) {
    switch (value.toLowerCase()) {
      case 'apartment':
      case 'appartement':
      case 'appartement_meuble':
        return model.ResidenceType.apartment;
      case 'house':
      case 'maison':
        return model.ResidenceType.house;
      case 'villa':
      case 'villa_meublee':
        return model.ResidenceType.villa;
      case 'studio':
      case 'studio_meuble':
        return model.ResidenceType.studio;
      case 'bungalow':
      case 'lodge':
      case 'ecolodge':
        return model.ResidenceType.bungalow;
      case 'hotel':
      case 'auberge':
      case 'motel':
        return model.ResidenceType.hotel;
      case 'luxury':
      case 'penthouse':
      case 'luxe':
        return model.ResidenceType.luxury;
      default:
        return model.ResidenceType.other;
    }
  }
}