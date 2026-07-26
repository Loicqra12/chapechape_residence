import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'residence_type_enum.dart';
import '../utils/formatters.dart';
import '../constants/app_assets.dart' as assets;

class Residence {
  final String id;
  final String title;
  final String description;
  final String shortDescription;
  final List<String> images;
  final double price;
  final Map<String, dynamic> location;
  final int bedrooms;
  final int bathrooms;
  final double squareMeters;
  final List<String> amenities;
  final bool hasPool;
  final bool hasWifi;
  final bool isVacationResidence;
  final bool isSpecialResidence;
  final bool isAvailable;
  final bool isFeatured;
  final bool isPopular;
  final bool isVerified;
  final bool isNew;
  final double rating;
  final int reviewCount;
  final String currency;
  final ResidenceType type;
  final int maxOccupancy;
  final String owner;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool allowsPets;
  final bool allowsSmoking;
  final bool allowsParties;
  final Map<String, dynamic>? priceDetails;
  final Map<String, dynamic>? contactInfo;
  final String? videoUrl;
  /// Vidéos structurées (API v2) — liste de Maps avec url, thumbnail, status, _id
  final List<Map<String, dynamic>> videos;
  final String? virtualTourUrl;
  final List<String>? nearbyAttractions;
  final List<String>? rules;
  final String pricePeriod;
  final double hourlyRate;
  final double halfDayRate;
  final double fullDayRate;
  final double weekendRate;
  final bool isVip;
  final String reservationMode;
  final List<String> paymentMethods;
  final bool isFavorite;

  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  double? get discountPrice => priceDetails != null && priceDetails!.containsKey('discountPrice') ? priceDetails!['discountPrice'] as double : null;
  double get discountPercentage => hasDiscount ? ((price - discountPrice!) / price) * 100 : 0;
  String get discountBadge => hasDiscount ? '${discountPercentage.round()}% OFF' : '';
  
  // Getters pour coordonnées GPS
  double? get latitude {
    try {
      if (coordinates.length > 1) {
        // Dans notre getter coordinates, longitude est à l'index 0, latitude à l'index 1
        return coordinates[1];
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur lors de l\'accès à latitude: $e');
      return null;
    }
  }
  
  double? get longitude {
    try {
      if (coordinates.length > 0) {
        // Dans notre getter coordinates, longitude est à l'index 0
        return coordinates[0];
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur lors de l\'accès à longitude: $e');
      return null;
    }
  }
  
  // Formatage des prix
  String get formattedPrice => PriceFormatter.formatPrice(price, withCurrency: true, currency: currency);
  String get formattedDiscountPrice => hasDiscount ? PriceFormatter.formatPrice(discountPrice!, withCurrency: true, currency: currency) : formattedPrice;
  
  // Conversion de devises
  double convertPrice(String targetCurrency) => CurrencyConverter.convert(price, currency, targetCurrency);
  String getFormattedPriceIn(String targetCurrency) => PriceFormatter.formatPriceWithCurrency(
      CurrencyConverter.convert(price, currency, targetCurrency),
      targetCurrency
  );

  // Si un prix réduit existe, le convertir aussi
  String getFormattedDiscountPriceIn(String targetCurrency) {
    if (!hasDiscount) return getFormattedPriceIn(targetCurrency);
    
    final convertedDiscountPrice = CurrencyConverter.convert(
      discountPrice!, 
      currency,
      targetCurrency
    );
    
    return PriceFormatter.formatPriceWithCurrency(
      convertedDiscountPrice,
      targetCurrency
    );
  }
  
  // Informations sur la location
  String get city => location.containsKey('city') ? location['city'] as String : 'Ville non précisée';
  String get country => location.containsKey('country') ? location['country'] as String : '';
  String get neighborhood => location.containsKey('neighborhood') ? location['neighborhood'] as String : '';
  String get address => location.containsKey('address') ? location['address'] as String : '';
  String get formattedAddress => location.displayAddress;
  List<double> get coordinates {
    // Cas 1: Format ancien (liste [longitude, latitude])
    if (location.containsKey('coordinates')) {
      if (location['coordinates'] is List) {
        return (location['coordinates'] as List).map((e) => double.parse(e.toString())).toList();
      } 
      // Cas 2: Nouveau format (objet {latitude, longitude})
      else if (location['coordinates'] is Map) {
        var coords = location['coordinates'] as Map;
        if (coords.containsKey('longitude') && coords.containsKey('latitude')) {
          return [coords['longitude'] is num ? coords['longitude'].toDouble() : double.parse(coords['longitude'].toString()),
                  coords['latitude'] is num ? coords['latitude'].toDouble() : double.parse(coords['latitude'].toString())];
        }
      }
    }
    // Cas 3: Coordonnées directement dans l'objet
    else if (location.containsKey('longitude') && location.containsKey('latitude')) {
      return [location['longitude'] is num ? location['longitude'].toDouble() : double.parse(location['longitude'].toString()),
              location['latitude'] is num ? location['latitude'].toDouble() : double.parse(location['latitude'].toString())];
    }
    // Cas 4: Coordonnées dans locationData
    else if (location.containsKey('locationData') && location['locationData'] is Map) {
      var locData = location['locationData'] as Map;
      if (locData.containsKey('coordinates') && locData['coordinates'] is Map) {
        var coords = locData['coordinates'] as Map;
        if (coords.containsKey('longitude') && coords.containsKey('latitude')) {
          return [coords['longitude'] is num ? coords['longitude'].toDouble() : double.parse(coords['longitude'].toString()),
                  coords['latitude'] is num ? coords['latitude'].toDouble() : double.parse(coords['latitude'].toString())];
        }
      }
    }
    // Valeur par défaut
    return [0.0, 0.0];
  }
  
  // Méthodes d'accès rapide pour les commodités
  bool get hasParking => amenities.contains('parking');
  bool get hasAirConditioning => amenities.contains('air_conditioning');
  bool get hasGym => amenities.contains('gym');
  bool get hasSecuritySystem => amenities.contains('security_system');
  bool get hasTerrace => amenities.contains('terrace');
  
  // Propriétés pour compatibilité avec l'ancien code
  String get name => title;
  double get surface => squareMeters;
  String get imageUrl => images.isNotEmpty ? images.first : 'assets/images/placeholders/residence_standard.jpg';
  List<String> get imageUrls => images;
  String get status => isAvailable ? 'available' : 'unavailable';
  String get pricePerNight => '${price.toStringAsFixed(0)} FCFA/nuit';
  bool get isNewListing => createdAt != null && DateTime.now().difference(createdAt!).inDays < 30;
  List<String> get photos => images;
  
  // Propriétés ajoutées pour compatibilité
  int get roomCount => bedrooms;
  int get bathCount => bathrooms;
  String get pricePerMonth => '${price.toStringAsFixed(0)} $currency/${pricePeriod == 'month' ? 'mois' : pricePeriod}';

  Residence({
    required this.id,
    required this.title,
    required this.description,
    this.shortDescription = '',
    required this.images,
    required this.price,
    required this.location,
    required this.bedrooms,
    required this.bathrooms,
    required this.squareMeters,
    required this.amenities,
    required this.hasPool,
    required this.hasWifi,
    required this.isVacationResidence,
    required this.isSpecialResidence,
    required this.isAvailable,
    this.isFeatured = false,
    this.isPopular = false,
    this.isVerified = false,
    this.isNew = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.currency = 'XOF',
    required this.type,
    this.maxOccupancy = 2,
    this.owner = '',
    this.createdAt,
    this.updatedAt,
    this.allowsPets = false,
    this.allowsSmoking = false,
    this.allowsParties = false,
    this.priceDetails,
    this.contactInfo,
    this.videoUrl,
    this.videos = const [],
    this.virtualTourUrl,
    this.nearbyAttractions,
    this.rules,
    this.pricePeriod = 'month',
    this.hourlyRate = 0.0,
    this.halfDayRate = 0.0,
    this.fullDayRate = 0.0,
    this.weekendRate = 0.0,
    this.isVip = false,
    this.reservationMode = 'instant',
    this.paymentMethods = const [],
    this.isFavorite = false,
  });

  factory Residence.fromJson(Map<String, dynamic> json) {
    // Parsing des dates
    DateTime? createdAt;
    if (json['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(json['createdAt'] as String);
      } catch (e) {
        if (kDebugMode) debugPrint('Erreur de parsing de la date de création: $e');
      }
    }
    
    DateTime? updatedAt;
    if (json['updatedAt'] != null) {
      try {
        updatedAt = DateTime.parse(json['updatedAt'] as String);
      } catch (e) {
        if (kDebugMode) debugPrint('Erreur de parsing de la date de mise à jour: $e');
      }
    }
    
    // Parsing du type de résidence
    ResidenceType residenceType;
    try {
      if (json['type'] is String) {
        String typeStr = (json['type'] as String).toLowerCase();
        if (typeStr.contains('_')) {
          // Format snake_case, probablement du backend
          residenceType = ResidenceTypeExtension.fromSnakeCase(typeStr);
        } else {
          // Essayer de mapper directement
          residenceType = _parseResidenceTypeString(typeStr);
        }
      } else {
        residenceType = ResidenceType.other;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur lors du parsing du type de résidence: $e');
      residenceType = ResidenceType.other;
    }
    
    // Extraction préalable des amenities (nécessaire pour dériver hasPool/hasWifi)
    final List<String> amenitiesList = json['amenities'] != null
        ? List<String>.from(json['amenities'] as List)
        : [];

    // Extraction des détails de prix
    String pricePeriod = json['pricePeriod'] as String? ?? 'month';
    double hourlyRate = 0.0;
    double halfDayRate = 0.0;
    double fullDayRate = 0.0;
    double weekendRate = 0.0;
    
    // Extraction des tarifs horaires s'ils existent
    if (json['hourlyRates'] is Map) {
      hourlyRate = (json['hourlyRates']['oneHour'] as num?)?.toDouble() ?? 0.0;
    } else if (json['hourlyRate'] != null) {
      hourlyRate = double.tryParse(json['hourlyRate'].toString()) ?? 0.0;
    }
    
    // Extraction des tarifs journaliers s'ils existent
    if (json['dailyRates'] is Map) {
      halfDayRate = (json['dailyRates']['halfDay'] as num?)?.toDouble() ?? 0.0;
      fullDayRate = (json['dailyRates']['fullDay'] as num?)?.toDouble() ?? 0.0;
      weekendRate = (json['dailyRates']['weekend'] as num?)?.toDouble() ?? 0.0;
    } else {
      // Extraction directe depuis les propriétés racines si elles existent
      if (json['halfDayRate'] != null) {
        halfDayRate = double.tryParse(json['halfDayRate'].toString()) ?? 0.0;
      }
      if (json['fullDayRate'] != null) {
        fullDayRate = double.tryParse(json['fullDayRate'].toString()) ?? 0.0;
      }
      if (json['weekendRate'] != null) {
        weekendRate = double.tryParse(json['weekendRate'].toString()) ?? 0.0;
      }
      }
      
      return Residence(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? json['name'] as String? ?? 'Titre non disponible',
      description: json['description'] as String? ?? 'Description non disponible',
      shortDescription: json['shortDescription'] as String? ?? '',
      images: json['images'] != null
          ? List<String>.from(json['images'] as List)
          : ['assets/images/placeholders/residence_standard.jpg'],
      price: json['price'] != null
          ? double.parse(json['price'].toString())
          : 0.0,
      location: json['location'] as Map<String, dynamic>? ?? {},
      bedrooms: json['bedrooms'] != null
          ? int.parse(json['bedrooms'].toString())
          : 1,
      bathrooms: json['bathrooms'] != null
          ? int.parse(json['bathrooms'].toString())
          : 1,
      squareMeters: json['squareMeters'] != null
          ? double.parse(json['squareMeters'].toString())
          : json['area'] != null
              ? double.parse(json['area'].toString())
              : json['surface'] != null
                  ? double.parse(json['surface'].toString())
                  : 0.0,
      amenities: amenitiesList,
      // hasPool/hasWifi : dérivés de la liste amenities (le backend ne renvoie pas ces champs directs)
      hasPool: amenitiesList.contains('pool'),
      hasWifi: amenitiesList.contains('wifi'),
      isVacationResidence: json['isVacationResidence'] as bool? ?? false,
      isSpecialResidence: json['isSpecialResidence'] as bool? ?? false,
      // isAvailable : le backend renvoie status:'available'/'unavailable', pas un champ isAvailable
      isAvailable: json['status'] == 'available'
          ? true
          : json['status'] == 'unavailable'
              ? false
              : json['isAvailable'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isPopular: json['isPopular'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      isNew: json['isNew'] as bool? ?? false,
      rating: json['rating'] != null
          ? (json['rating'] is Map
              ? ((json['rating']['overall'] as num?)?.toDouble() ?? 0.0)
              : double.tryParse(json['rating'].toString()) ?? 0.0)
          : 0.0,
      // reviewCount : stocké dans rating.reviewCount côté backend, pas à la racine
      reviewCount: json['rating'] is Map
          ? (json['rating']['reviewCount'] as int? ?? 0)
          : json['reviewCount'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'XOF',
      type: residenceType,
      maxOccupancy: json['maxOccupancy'] as int? ?? 2,
      owner: json['owner'] as String? ?? json['ownerId'] as String? ?? '',
      createdAt: createdAt,
      updatedAt: updatedAt,
      // allowsPets/Smoking/Parties : le backend stocke dans rules:{pets,smoking,parties}
      // Le partenaire envoie {allowsPets,...}, le backend normalise en {pets,...}
      allowsPets: json['rules'] is Map
          ? (json['rules']['pets'] as bool? ?? json['allowsPets'] as bool? ?? false)
          : json['allowsPets'] as bool? ?? false,
      allowsSmoking: json['rules'] is Map
          ? (json['rules']['smoking'] as bool? ?? json['allowsSmoking'] as bool? ?? false)
          : json['allowsSmoking'] as bool? ?? false,
      allowsParties: json['rules'] is Map
          ? (json['rules']['parties'] as bool? ?? json['allowsParties'] as bool? ?? false)
          : json['allowsParties'] as bool? ?? false,
      priceDetails: json['priceDetails'] as Map<String, dynamic>?,
      contactInfo: json['contactInfo'] as Map<String, dynamic>?,
      videoUrl: json['videoUrl'] as String?,
      videos: (json['videos'] as List<dynamic>?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          const [],
      virtualTourUrl: json['virtualTourUrl'] as String?,
      nearbyAttractions: json['nearbyAttractions'] != null
          ? List<String>.from(json['nearbyAttractions'] as List)
          : null,
      // rules: le backend stocke {smoking, pets, parties} (Map), pas un tableau
      // On retourne null ici — les booléens allowsPets/Smoking/Parties gèrent l'affichage
      rules: json['rules'] is List
          ? List<String>.from(json['rules'] as List)
          : null,
        pricePeriod: pricePeriod,
        hourlyRate: hourlyRate,
        halfDayRate: halfDayRate,
        fullDayRate: fullDayRate,
        weekendRate: weekendRate,
        reservationMode: json['reservationMode'] as String? ?? 'instant',
      paymentMethods: json['paymentMethods'] != null
          ? List<String>.from(json['paymentMethods'] as List)
          : [],
      isFavorite: json['isFavorite'] as bool? ??
          (json['priceDetails'] is Map && (json['priceDetails'] as Map).containsKey('isFavorite')
              ? (json['priceDetails'] as Map)['isFavorite'] as bool? ?? false
              : false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'shortDescription': shortDescription,
      'images': images,
      'price': price,
      'location': location,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'squareMeters': squareMeters,
      'amenities': amenities,
      'hasPool': hasPool,
      'hasWifi': hasWifi,
      'isVacationResidence': isVacationResidence,
      'isSpecialResidence': isSpecialResidence,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'isPopular': isPopular,
      'isVerified': isVerified,
      'isNew': isNew,
      'rating': rating,
      'reviewCount': reviewCount,
      'currency': currency,
      'type': type.toString().split('.').last,
      'maxOccupancy': maxOccupancy,
      'owner': owner,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'allowsPets': allowsPets,
      'allowsSmoking': allowsSmoking,
      'allowsParties': allowsParties,
      'priceDetails': priceDetails,
      'contactInfo': contactInfo,
      'videoUrl': videoUrl,
      'videos': videos,
      'virtualTourUrl': virtualTourUrl,
      'nearbyAttractions': nearbyAttractions,
      'rules': rules,
      'pricePeriod': pricePeriod,
      'hourlyRates': {
        'oneHour': hourlyRate,
      },
      'dailyRates': {
        'halfDay': halfDayRate,
        'fullDay': fullDayRate,
        'weekend': weekendRate,
      },
      'reservationMode': reservationMode,
      'isFavorite': isFavorite,
    };
  }

  // Copie avec modifications
  Residence copyWith({
    String? id,
    String? title,
    String? description,
    String? shortDescription,
    List<String>? images,
    double? price,
    Map<String, dynamic>? location,
    int? bedrooms,
    int? bathrooms,
    double? squareMeters,
    List<String>? amenities,
    bool? hasPool,
    bool? hasWifi,
    bool? isVacationResidence,
    bool? isSpecialResidence,
    bool? isAvailable,
    bool? isFeatured,
    bool? isPopular,
    bool? isVerified,
    bool? isNew,
    double? rating,
    int? reviewCount,
    String? currency,
    ResidenceType? type,
    int? maxOccupancy,
    String? owner,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? allowsPets,
    bool? allowsSmoking,
    bool? allowsParties,
    Map<String, dynamic>? priceDetails,
    Map<String, dynamic>? contactInfo,
    String? videoUrl,
    List<Map<String, dynamic>>? videos,
    String? virtualTourUrl,
    List<String>? nearbyAttractions,
    List<String>? rules,
    String? pricePeriod,
    double? hourlyRate,
    double? halfDayRate,
    double? fullDayRate,
    double? weekendRate,
    String? reservationMode,
    List<String>? paymentMethods,
    bool? isFavorite,
  }) {
    return Residence(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      shortDescription: shortDescription ?? this.shortDescription,
      images: images ?? this.images,
      price: price ?? this.price,
      location: location ?? this.location,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      squareMeters: squareMeters ?? this.squareMeters,
      amenities: amenities ?? this.amenities,
      hasPool: hasPool ?? this.hasPool,
      hasWifi: hasWifi ?? this.hasWifi,
      isVacationResidence: isVacationResidence ?? this.isVacationResidence,
      isSpecialResidence: isSpecialResidence ?? this.isSpecialResidence,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      isPopular: isPopular ?? this.isPopular,
      isVerified: isVerified ?? this.isVerified,
      isNew: isNew ?? this.isNew,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      maxOccupancy: maxOccupancy ?? this.maxOccupancy,
      owner: owner ?? this.owner,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      allowsPets: allowsPets ?? this.allowsPets,
      allowsSmoking: allowsSmoking ?? this.allowsSmoking,
      allowsParties: allowsParties ?? this.allowsParties,
      priceDetails: priceDetails ?? this.priceDetails,
      contactInfo: contactInfo ?? this.contactInfo,
      videoUrl: videoUrl ?? this.videoUrl,
      videos: videos ?? this.videos,
      virtualTourUrl: virtualTourUrl ?? this.virtualTourUrl,
      nearbyAttractions: nearbyAttractions ?? this.nearbyAttractions,
      rules: rules ?? this.rules,
      pricePeriod: pricePeriod ?? this.pricePeriod,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      halfDayRate: halfDayRate ?? this.halfDayRate,
      fullDayRate: fullDayRate ?? this.fullDayRate,
      weekendRate: weekendRate ?? this.weekendRate,
      reservationMode: reservationMode ?? this.reservationMode,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  // Méthode pour convertir ResidenceType en assets.ResidenceType
  assets.ResidenceType toAssetResidenceType() {
    return assets.convertModelTypeToAssetType(type);
  }
}

extension LocationExtension on Map<String, dynamic> {
  String get displayAddress {
    if (containsKey('formattedAddress')) {
      return this['formattedAddress'] as String;
    } else if (containsKey('address')) {
      return this['address'] as String;
    } else {
      // Construction d'une adresse à partir des différentes parties
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
}

// Fonction utilitaire pour parser le type de résidence à partir d'une chaîne
ResidenceType _parseResidenceTypeString(String value) {
  switch (value.toLowerCase()) {
    case 'apartment':
      return ResidenceType.apartment;
    case 'house':
      return ResidenceType.house;
    case 'villa':
      return ResidenceType.villa;
    case 'studio':
      return ResidenceType.studio;
    case 'bungalow':
      return ResidenceType.bungalow;
    case 'hotel':
      return ResidenceType.hotel;
    case 'luxury':
      return ResidenceType.luxury;
    default:
      return ResidenceType.other;
  }
}