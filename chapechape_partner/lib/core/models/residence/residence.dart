import 'package:intl/intl.dart';

class Residence {
  final String id;
  final String name;
  final String description;
  final List<dynamic> images;
  final String? mainImage;
  final String address;
  final String city;
  final double price;
  final int bedrooms;
  final int bathrooms;
  final double surface;
  final bool hasPool;
  final bool hasWifi;
  final bool hasRestaurant;
  final bool isVacationResidence;
  final bool isSpecialResidence;
  final bool isAvailable;
  final double rating;
  final int reviewCount;
  final String type;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Nouvelles propriétés
  final bool isFurnished;
  final Map<String, dynamic>? partnerInfo;
  final int maxGuests;
  final bool allowsSmoking;
  final bool allowsPets;
  final bool allowsParties;
  final List<String> amenities;
  
  // Propriétés de tarification
  final String pricePeriod;
  final double hourlyRate;
  final double halfDayRate;
  final double fullDayRate;
  final double weekendRate;
  
  // Options spécifiques ajoutées
  final Map<String, dynamic>? options;
  
  // Propriétés de localisation
  final String? country;
  final String? countryName;
  final String? region;
  final String? regionName;
  final String? cityCode;
  final String? cityName;
  
  // Coordonnées GPS
  final double? latitude;
  final double? longitude;
  final String? formattedAddress;
  
  // Statut de suppression
  final bool? deleted;
  
  // Devise du prix
  final String currency;

  // Nouveaux champs pour l'interface améliorée
  final int stars;
  final List<Map<String, dynamic>> nearbyPlaces;
  final List<Map<String, dynamic>> faqs;
  final Map<String, dynamic> enhancedAmenities;
  final List<String> paymentMethods;
  final String reservationMode; // 'instant' ou 'approval_required'

  Residence({
    required this.id,
    required this.name,
    required this.description,
    required this.images,
    this.mainImage,
    required this.address,
    required this.city,
    required this.price,
    required this.bedrooms,
    required this.bathrooms,
    required this.surface,
    required this.hasPool,
    required this.hasWifi,
    required this.hasRestaurant,
    required this.isVacationResidence,
    required this.isSpecialResidence,
    required this.isAvailable,
    required this.rating,
    required this.reviewCount,
    required this.type,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.isFurnished = false,
    this.partnerInfo,
    this.maxGuests = 2,
    this.allowsSmoking = false,
    this.allowsPets = false,
    this.allowsParties = false,
    this.amenities = const [],
    this.pricePeriod = '',
    this.hourlyRate = 0.0,
    this.halfDayRate = 0.0,
    this.fullDayRate = 0.0,
    this.weekendRate = 0.0,
    this.options,
    this.country,
    this.countryName,
    this.region,
    this.regionName,
    this.cityCode,
    this.cityName,
    this.latitude,
    this.longitude,
    this.formattedAddress,
    this.deleted,
    this.currency = 'FCFA',
    this.stars = 0,
    this.nearbyPlaces = const [],
    this.faqs = const [],
    this.enhancedAmenities = const {},
    this.paymentMethods = const [],
    this.reservationMode = 'instant', // Valeur par défaut
  });

  factory Residence.fromJson(Map<String, dynamic> json) {
    // Convertir les amenities en propriétés booléennes
    final amenities = (json['amenities'] as List<dynamic>?)?.cast<String>() ?? [];
    
    // Ajouter les propriétés du partenaire si présentes
    Map<String, dynamic>? partnerInfo;
    if (json['partner'] != null) {
      partnerInfo = {
        'id': json['partner']['_id'] ?? '',
        'name': '${json['partner']['firstName'] ?? ''} ${json['partner']['lastName'] ?? ''}'.trim(),
        'email': json['partner']['email'] ?? '',
        'phoneNumber': json['partner']['phoneNumber'] ?? '',
      };
    } else if (json['partnerInfo'] != null) {
      partnerInfo = json['partnerInfo'] as Map<String, dynamic>;
    }
    
    // Ajouter les règles
    final maxGuests = json['rules']?['maxGuests'] ?? json['maxGuests'] ?? 2;
    final allowsSmoking = json['rules']?['smoking'] ?? json['allowsSmoking'] ?? false;
    final allowsPets = json['rules']?['pets'] ?? json['allowsPets'] ?? false;
    final allowsParties = json['rules']?['parties'] ?? json['allowsParties'] ?? false;
    
    // Ajouter les propriétés de tarification
    final pricePeriod = json['pricePeriod']?.toString() ?? '';
    
    // Gérer les différents formats de tarification
    double hourlyRate = 0.0;
    double halfDayRate = 0.0;
    double fullDayRate = 0.0;
    double weekendRate = 0.0;
    
    // Extraction des tarifs horaires (peut être un nombre simple ou un objet)
    if (json['hourlyRate'] != null && json['hourlyRate'] is num) {
      hourlyRate = (json['hourlyRate'] as num).toDouble();
    } else if (json['hourlyRates'] != null && json['hourlyRates'] is Map) {
      final hourlyRates = json['hourlyRates'] as Map<String, dynamic>;
      hourlyRate = (hourlyRates['oneHour'] as num?)?.toDouble() ?? 0.0;
    }
    
    // Extraction des tarifs journaliers (peut être un nombre simple ou un objet)
    if (json['halfDayRate'] != null && json['halfDayRate'] is num) {
      halfDayRate = (json['halfDayRate'] as num).toDouble();
    } else if (json['dailyRates'] != null && json['dailyRates'] is Map) {
      final dailyRates = json['dailyRates'] as Map<String, dynamic>;
      halfDayRate = (dailyRates['halfDay'] as num?)?.toDouble() ?? 0.0;
    }
    
    if (json['fullDayRate'] != null && json['fullDayRate'] is num) {
      fullDayRate = (json['fullDayRate'] as num).toDouble();
    } else if (json['dailyRates'] != null && json['dailyRates'] is Map) {
      final dailyRates = json['dailyRates'] as Map<String, dynamic>;
      fullDayRate = (dailyRates['fullDay'] as num?)?.toDouble() ?? 0.0;
    }
    
    if (json['weekendRate'] != null && json['weekendRate'] is num) {
      weekendRate = (json['weekendRate'] as num).toDouble();
    } else if (json['dailyRates'] != null && json['dailyRates'] is Map) {
      final dailyRates = json['dailyRates'] as Map<String, dynamic>;
      weekendRate = (dailyRates['weekend'] as num?)?.toDouble() ?? 0.0;
    }
    
    // Extraire les options
    Map<String, dynamic>? options = json['options'] as Map<String, dynamic>?;
    
    // Si les options ne sont pas présentes directement, essayer de les construire
    if (options == null) {
      options = {
        'hasPool': json['hasPool'] ?? false,
        'isVacationResidence': json['isVacationResidence'] ?? false,
        'isSpecialResidence': json['isSpecialResidence'] ?? false,
      };
      
      // Ajouter d'autres options si présentes dans le JSON
      for (final option in [
        'hasAirConditioning', 'hasWifi', 'hasParking', 'hasSecurity',
        'hasCleaning', 'hasHotWater', 'hasBalcony', 'hasGarden',
        'hasTerrace', 'hasKitchen', 'hasSharedKitchen', 'hasTv',
        'hasGenerator', 'hasSolarEnergy', 'hasGym', 'hasSpa',
        'hasRestaurant', 'hasBar', 'hasRoomService', 'hasLaundry',
        'hasMeetingRoom'
      ]) {
        if (json[option] != null) {
          options[option] = json[option];
        }
      }
    }
    
    // Extraire les informations de localisation
    String? country = json['country']?.toString();
    String? countryName = json['countryName']?.toString();
    String? region = json['region']?.toString();
    String? regionName = json['regionName']?.toString();
    String? cityCode = json['cityCode']?.toString();
    String? cityName = json['cityName']?.toString();
    
    // Extraire les coordonnées GPS
    double? latitude;
    double? longitude;
    String? formattedAddress;
    
    if (json['latitude'] != null) {
      latitude = (json['latitude'] is String) 
          ? double.tryParse(json['latitude']) 
          : (json['latitude'] as num?)?.toDouble();
    }
    
    if (json['longitude'] != null) {
      longitude = (json['longitude'] is String) 
          ? double.tryParse(json['longitude']) 
          : (json['longitude'] as num?)?.toDouble();
    }
    
    formattedAddress = json['formattedAddress']?.toString();
    
    // Extraire la devise du prix (avec FCFA comme valeur par défaut)
    final currency = json['currency']?.toString() ?? 'FCFA';
    
    // Extraire le statut de suppression
    final deleted = json['deleted'] as bool?;
    
    // Extraire les nouveaux champs
    final stars = json['stars'] as int? ?? 0;
    final nearbyPlaces = (json['nearbyPlaces'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
    final faqs = (json['faqs'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>).toList() ?? [];
    final enhancedAmenities = json['enhancedAmenities'] as Map<String, dynamic>? ?? {};
    final paymentMethods = (json['paymentMethods'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];

    return Residence(
      id: json['_id']?.toString() ?? '',
      name: json['title']?.toString() ?? json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      images: json['images'] ?? [],
      mainImage: json['mainImage']?.toString(),
      address: json['address']?.toString() ?? json['location']?['address']?.toString() ?? '',
      city: json['city']?.toString() ?? json['location']?['city']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      bedrooms: json['bedrooms'] as int? ?? 0,
      bathrooms: json['bathrooms'] as int? ?? 0,
      surface: (json['area'] as num?)?.toDouble() ?? (json['surface'] as num?)?.toDouble() ?? 0.0,
      hasPool: amenities.contains('pool'),
      hasWifi: amenities.contains('wifi'),
      hasRestaurant: amenities.contains('kitchen'),
      isVacationResidence: json['type'] == 'villa',
      isSpecialResidence: false,
      isAvailable: json['status']?.toString().toLowerCase() == 'available',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
      isFurnished: json['isFurnished'] as bool? ?? false,
      partnerInfo: partnerInfo,
      maxGuests: maxGuests,
      allowsSmoking: allowsSmoking,
      allowsPets: allowsPets,
      allowsParties: allowsParties,
      amenities: amenities,
      pricePeriod: pricePeriod,
      hourlyRate: hourlyRate,
      halfDayRate: halfDayRate,
      fullDayRate: fullDayRate,
      weekendRate: weekendRate,
      options: options,
      country: country,
      countryName: countryName,
      region: region,
      regionName: regionName,
      cityCode: cityCode,
      cityName: cityName,
      latitude: latitude,
      longitude: longitude,
      formattedAddress: formattedAddress,
      deleted: deleted,
      currency: currency,
      stars: stars,
      nearbyPlaces: nearbyPlaces,
      faqs: faqs,
      enhancedAmenities: enhancedAmenities,
      paymentMethods: paymentMethods,
      reservationMode: json['reservationMode'] as String? ?? 'instant',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': name,
      'description': description,
      'images': images,
      'mainImage': mainImage,
      'address': address,
      'city': city,
      'price': price,
      'currency': currency,
      'area': surface,
      'features': {
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'hasPool': hasPool,
        'hasWifi': hasWifi,
        'hasRestaurant': hasRestaurant,
        'isVacationResidence': isVacationResidence,
        'isSpecialResidence': isSpecialResidence,
      },
      'status': isAvailable ? 'available' : 'unavailable',
      'type': type,
      'category': category,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isFurnished': isFurnished,
      'partnerInfo': partnerInfo,
      'maxGuests': maxGuests,
      'allowsSmoking': allowsSmoking,
      'allowsPets': allowsPets,
      'allowsParties': allowsParties,
      'amenities': amenities,
      'pricePeriod': pricePeriod,
      'hourlyRate': hourlyRate,
      'halfDayRate': halfDayRate,
      'fullDayRate': fullDayRate,
      'weekendRate': weekendRate,
      'options': options,
      'country': country,
      'countryName': countryName,
      'region': region,
      'regionName': regionName,
      'cityCode': cityCode,
      'cityName': cityName,
      'latitude': latitude,
      'longitude': longitude,
      'formattedAddress': formattedAddress,
      'deleted': deleted,
      'stars': stars,
      'nearbyPlaces': nearbyPlaces,
      'faqs': faqs,
      'enhancedAmenities': enhancedAmenities,
      'paymentMethods': paymentMethods,
      'reservationMode': reservationMode,
    };
  }

  String get formattedPrice {
    final numberFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );
    return numberFormat.format(price);
  }
}