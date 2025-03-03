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
  });

  factory Residence.fromJson(Map<String, dynamic> json) {
    return Residence(
      id: json['_id']?.toString() ?? '',
      name: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      images: json['images'] ?? [],
      mainImage: json['mainImage']?.toString(),
      address: json['location']?['address']?.toString() ?? '',
      city: json['location']?['city']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      bedrooms: json['features']?['bedrooms'] as int? ?? json['bedrooms'] as int? ?? 0,
      bathrooms: json['features']?['bathrooms'] as int? ?? json['bathrooms'] as int? ?? 0,
      surface: json['features']?['area'] as double? ?? json['area'] as double? ?? 0.0,
      hasPool: json['features']?['hasPool'] as bool? ?? json['hasPool'] as bool? ?? false,
      hasWifi: json['features']?['hasWifi'] as bool? ?? json['hasWifi'] as bool? ?? false,
      hasRestaurant: json['features']?['hasRestaurant'] as bool? ?? json['hasRestaurant'] as bool? ?? false,
      isVacationResidence: json['features']?['isVacationResidence'] as bool? ?? json['isVacationResidence'] as bool? ?? false,
      isSpecialResidence: json['features']?['isSpecialResidence'] as bool? ?? json['isSpecialResidence'] as bool? ?? false,
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
      partnerInfo: json['partnerInfo'] as Map<String, dynamic>?,
      maxGuests: json['maxGuests'] as int? ?? 2,
      allowsSmoking: json['allowsSmoking'] as bool? ?? false,
      allowsPets: json['allowsPets'] as bool? ?? false,
      allowsParties: json['allowsParties'] as bool? ?? false,
      amenities: (json['amenities'] as List<dynamic>?)?.cast<String>() ?? [],
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