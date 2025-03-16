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
    final hourlyRate = (json['hourlyRate'] as num?)?.toDouble() ?? 0.0;
    final halfDayRate = (json['halfDayRate'] as num?)?.toDouble() ?? 0.0;
    final fullDayRate = (json['fullDayRate'] as num?)?.toDouble() ?? 0.0;
    final weekendRate = (json['weekendRate'] as num?)?.toDouble() ?? 0.0;
    
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
      surface: json['area'] as double? ?? json['surface'] as double? ?? 0.0,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': name,
      'description': description,
      'images': images,
      'mainImage': mainImage,
      'location': {
        'address': address,
        'city': city,
      },
      'price': price,
      'features': {
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'area': surface,
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