import 'package:freezed_annotation/freezed_annotation.dart';
import '../constants/app_assets.dart' as assets;

// Classe simplifiée sans freezed pour éviter les erreurs de génération
class Residence {
  final String id;
  final String name;
  final String description;
  final double price;
  final String address;
  final String city;
  final String country;
  final List<String> images;
  final int bedrooms;
  final int bathrooms;
  final double surface;
  final bool isAvailable;
  final Map<String, dynamic> location;
  final List<String> amenities;
  final List<String> rules;
  final bool isFavorite;
  final ResidenceType type;
  final String pricePeriod;
  final double hourlyRate;
  final double halfDayRate;
  final double fullDayRate;
  final double weekendRate;
  final double? rating;
  final int? reviewCount;
  final String? ownerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Ajout de la propriété imageUrls pour compatibilité avec le code existant
  List<String> get imageUrls => images;

  // Récupérer le premier URL d'image ou une image par défaut
  String get imageUrl => images.isNotEmpty ? images.first : getDefaultImageByType();

  // Vérifier si la résidence a une piscine
  bool get hasPool => amenities.contains('pool');

  // Vérifier si la résidence a un parking
  bool get hasParking => amenities.contains('parking');

  // Vérifier si c'est une résidence de vacances
  bool get isVacationResidence => 
      type == ResidenceType.villa || 
      type == ResidenceType.bungalow || 
      type == ResidenceType.hotel;

  // Méthode pour créer une copie de Residence avec des modifications
  Residence copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? address,
    String? city,
    String? country,
    List<String>? images,
    int? bedrooms,
    int? bathrooms,
    double? surface,
    bool? isAvailable,
    Map<String, dynamic>? location,
    List<String>? amenities,
    List<String>? rules,
    bool? isFavorite,
    ResidenceType? type,
    String? pricePeriod,
    double? hourlyRate,
    double? halfDayRate,
    double? fullDayRate,
    double? weekendRate,
    double? rating,
    int? reviewCount,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Residence(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      images: images ?? this.images,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      surface: surface ?? this.surface,
      isAvailable: isAvailable ?? this.isAvailable,
      location: location ?? this.location,
      amenities: amenities ?? this.amenities,
      rules: rules ?? this.rules,
      isFavorite: isFavorite ?? this.isFavorite,
      type: type ?? this.type,
      pricePeriod: pricePeriod ?? this.pricePeriod,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      halfDayRate: halfDayRate ?? this.halfDayRate,
      fullDayRate: fullDayRate ?? this.fullDayRate,
      weekendRate: weekendRate ?? this.weekendRate,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  const Residence({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.address,
    required this.city,
    required this.country,
    required this.images,
    required this.bedrooms,
    required this.bathrooms,
    required this.surface,
    required this.isAvailable,
    required this.location,
    this.amenities = const [],
    this.rules = const [],
    this.isFavorite = false,
    this.type = ResidenceType.apartment,
    this.pricePeriod = 'month',
    this.hourlyRate = 0,
    this.halfDayRate = 0,
    this.fullDayRate = 0,
    this.weekendRate = 0,
    this.rating,
    this.reviewCount,
    this.ownerId,
    this.createdAt,
    this.updatedAt,
  });

  factory Residence.fromJson(Map<String, dynamic> json) {
    try {
      // Traiter les champs qui pourraient être null avec des valeurs par défaut
      final String id = json['id']?.toString() ?? 'unknown_id';
      final String name = json['title']?.toString() ?? json['name']?.toString() ?? 'Résidence sans nom';
      final String description = json['description']?.toString() ?? 'Aucune description disponible';
      final double price = json['price'] != null ? (json['price'] as num).toDouble() : 0.0;
      final String address = json['address']?.toString() ?? 'Adresse non spécifiée';
      final String city = json['city']?.toString() ?? 'Ville non spécifiée';
      final String country = json['country']?.toString() ?? 'Pays non spécifié';
      
      List<String> images = [];
      if (json['images'] != null && json['images'] is List) {
        images = (json['images'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
      }
      
      final int bedrooms = json['bedrooms'] is int ? json['bedrooms'] as int : 0;
      final int bathrooms = json['bathrooms'] is int ? json['bathrooms'] as int : 0;
      final double surface = json['area'] != null ? (json['area'] as num).toDouble() : 
                           json['surface'] != null ? (json['surface'] as num).toDouble() : 0.0;
      final bool isAvailable = json['isAvailable'] is bool ? json['isAvailable'] as bool : true;
      
      Map<String, dynamic> location = {};
      if (json['location'] is Map) {
        location = json['location'] as Map<String, dynamic>;
      }
      
      List<String> amenities = [];
      if (json.containsKey('amenities') && json['amenities'] is List) {
        amenities = (json['amenities'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
      }
      
      List<String> rules = [];
      if (json.containsKey('rules') && json['rules'] is List) {
        rules = (json['rules'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
      }
      
      final bool isFavorite = json['isFavorite'] is bool ? json['isFavorite'] as bool : false;
      final ResidenceType type = _parseResidenceType(json['type']?.toString() ?? 'apartment');
      final String pricePeriod = json['pricePeriod']?.toString() ?? 'month';
      
      final double hourlyRate = json['hourlyRate'] != null ? (json['hourlyRate'] as num).toDouble() : 0.0;
      final double halfDayRate = json['halfDayRate'] != null ? (json['halfDayRate'] as num).toDouble() : 0.0;
      final double fullDayRate = json['fullDayRate'] != null ? (json['fullDayRate'] as num).toDouble() : 0.0;
      final double weekendRate = json['weekendRate'] != null ? (json['weekendRate'] as num).toDouble() : 0.0;
      
      double? rating;
      if (json['rating'] != null) {
        rating = (json['rating'] as num).toDouble();
      }
      
      int? reviewCount;
      if (json['reviewCount'] is int) {
        reviewCount = json['reviewCount'] as int;
      }
      
      String? ownerId;
      if (json['ownerId'] is String) {
        ownerId = json['ownerId'] as String;
      }
      
      DateTime? createdAt;
      if (json['createdAt'] is String && json['createdAt'].toString().isNotEmpty) {
        try {
          createdAt = DateTime.parse(json['createdAt'] as String);
        } catch (_) {}
      }
      
      DateTime? updatedAt;
      if (json['updatedAt'] is String && json['updatedAt'].toString().isNotEmpty) {
        try {
          updatedAt = DateTime.parse(json['updatedAt'] as String);
        } catch (_) {}
      }
      
      return Residence(
        id: id,
        name: name,
        description: description,
        price: price,
        address: address,
        city: city,
        country: country,
        images: images,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        surface: surface,
        isAvailable: isAvailable,
        location: location,
        amenities: amenities,
        rules: rules,
        isFavorite: isFavorite,
        type: type,
        pricePeriod: pricePeriod,
        hourlyRate: hourlyRate,
        halfDayRate: halfDayRate,
        fullDayRate: fullDayRate,
        weekendRate: weekendRate,
        rating: rating,
        reviewCount: reviewCount,
        ownerId: ownerId,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e, stackTrace) {
      // En cas d'erreur, logger l'erreur et créer une résidence par défaut pour éviter les crashs
      print('Erreur lors de la conversion de residence: $e');
      print('JSON: $json');
      print('Stack trace: $stackTrace');
      
      return Residence.defaultResidence();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': name,
      'description': description,
      'price': price,
      'address': address,
      'city': city,
      'country': country,
      'images': images,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': surface,
      'isAvailable': isAvailable,
      'location': location,
      'amenities': amenities,
      'rules': rules,
      'isFavorite': isFavorite,
      'type': type.toString().split('.').last,
      'pricePeriod': pricePeriod,
      'hourlyRate': hourlyRate,
      'halfDayRate': halfDayRate,
      'fullDayRate': fullDayRate,
      'weekendRate': weekendRate,
      if (rating != null) 'rating': rating,
      if (reviewCount != null) 'reviewCount': reviewCount,
      if (ownerId != null) 'ownerId': ownerId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
  
  // Fonction pour obtenir une image par défaut basée sur le type
  String getDefaultImageByType() {
    switch (type) {
      case ResidenceType.apartment:
        return 'assets/images/residences/apartments/seen-hotel-abidjan-plateau.jpg';
      case ResidenceType.villa:
        return 'assets/images/residences/villas/Villa-Santorini-Abidjan-1.jpg';
      case ResidenceType.studio:
        return 'assets/images/residences/studios/304661255.jpg';
      case ResidenceType.bungalow:
        return 'assets/images/residences/apartments/IMG_0668.jpg';
      case ResidenceType.hotel:
        return 'assets/images/residences/apartments/450667738.jpg';
      case ResidenceType.luxury:
        return 'assets/images/residences/luxury/Waterfront_view-5B-e1670065708270.webp';
      default:
        return 'assets/images/residences/apartments/seen-hotel-abidjan-plateau.jpg';
    }
  }
  
  // Méthode pour convertir le type en assets.ResidenceType pour la compatibilité avec les extensions
  assets.ResidenceType toAssetResidenceType() {
    switch (type) {
      case ResidenceType.apartment:
        return assets.ResidenceType.apartment;
      case ResidenceType.villa:
        return assets.ResidenceType.villa;
      case ResidenceType.studio:
        return assets.ResidenceType.studio;
      case ResidenceType.bungalow:
        return assets.ResidenceType.bungalow;
      case ResidenceType.hotel:
        return assets.ResidenceType.hotel;
      case ResidenceType.luxury:
        return assets.ResidenceType.luxury;
      default:
        return assets.ResidenceType.apartment;
    }
  }
  
  // Fonction pour obtenir l'icône du type de résidence
  String get typeIconPath {
    return toAssetResidenceType().iconPath;
  }

  // Méthode pour créer une résidence par défaut en cas d'erreur
  factory Residence.defaultResidence() {
    return const Residence(
      id: 'error_id',
      name: 'Résidence (Erreur de chargement)',
      description: 'Les détails de cette résidence n\'ont pas pu être chargés correctement.',
      price: 0,
      address: 'Adresse inconnue',
      city: 'Ville inconnue',
      country: 'Pays inconnu',
      images: [],
      bedrooms: 0,
      bathrooms: 0,
      surface: 0,
      isAvailable: false,
      location: {},
    );
  }
}

// Extensions pour ajouter des propriétés calculées
extension ResidenceProperties on Residence {
  bool get isSpecialResidence => 
      type == ResidenceType.hotel || 
      type == ResidenceType.luxury;
      
  bool get isStudentResidence => 
      type == ResidenceType.studio;

  // Propriétés supplémentaires pour les cartes de résidence
  bool get isBeachfront => 
      amenities.contains('beachfront') || 
      description.toLowerCase().contains('plage') ||
      description.toLowerCase().contains('océan');
      
  bool get isMountainView => 
      amenities.contains('mountain_view') || 
      description.toLowerCase().contains('montagne') ||
      description.toLowerCase().contains('vue panoramique');
      
  bool get isNewListing => 
      createdAt != null && 
      DateTime.now().difference(createdAt!).inDays < 30;  // Listings de moins de 30 jours

  // Getters pour la compatibilité avec le code existant
  String get title => name.isNotEmpty ? name : "Résidence";
  String get status => isAvailable ? 'available' : 'unavailable';
  String get pricePerNight => '${price.toStringAsFixed(0)} FCFA/nuit';
}

extension LocationExtension on Map<String, dynamic> {
  String get displayAddress {
    if (containsKey('formattedAddress')) {
      return this['formattedAddress'] as String;
    } else if (containsKey('address')) {
      return this['address'] as String;
    } else if (this.isEmpty) {
      return 'Adresse non disponible';
    }
    return 'Adresse non disponible';
  }
}

// Types de résidences dans notre modèle
enum ResidenceType {
  // 🏠 Résidences meublées
  studioMeuble,
  appartementMeuble,
  villaMeublee,
  penthouse,
  grenier,
  
  // 🏨 Hôtels & Hébergements classiques
  hotelDePassage,
  motel,
  boutiqueHotel,
  hotelDeLuxe,
  aubergeEtMaisonDHotes,
  residenceHoteliere,
  
  // 🌍 Hébergements insolites & nature
  bungalow,
  lodgeEtEcolodge,
  caseTraditionnelle,
  maisonFlottante,
  campementTouristique,
  
  // 🏘️ Colocation & résidences partagées
  chambreEnColocation,
  cohabitation,
  residenceUniversitaire,
  citeDortoir,
  
  // 🏡 Résidences longue durée
  appartementNonMeuble,
  villaNonMeublee,
  immeuble,
  courCommune,
  
  // ⛺ Hébergements économiques et populaires
  maisonDHotesEconomique,
  residenceFamilialeEnLocation,
  chambresDePassage,
  
  // Types génériques de base (pour compatibilité)
  apartment,
  studio,
  villa,
  house,
  hotel,
  luxury,
  
  // Valeur par défaut
  other
}

// Fonction utilitaire pour parser le type de résidence
ResidenceType _parseResidenceType(String value) {
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

// Extension pour obtenir le nom d'affichage en français de chaque type de résidence
extension ResidenceTypeExtension on ResidenceType {
  String get displayName {
    switch (this) {
      // 🏠 Résidences meublées
      case ResidenceType.studioMeuble:
        return 'Studio meublé';
      case ResidenceType.appartementMeuble:
        return 'Appartement meublé';
      case ResidenceType.villaMeublee:
        return 'Villa meublée';
      case ResidenceType.penthouse:
        return 'Penthouse';
      case ResidenceType.grenier:
        return 'Grenier';

      // 🏨 Hôtels & Hébergements classiques
      case ResidenceType.hotelDePassage:
        return 'Hôtel de passage';
      case ResidenceType.motel:
        return 'Motel';
      case ResidenceType.boutiqueHotel:
        return 'Boutique-Hôtel';
      case ResidenceType.hotelDeLuxe:
        return 'Hôtel de luxe';
      case ResidenceType.aubergeEtMaisonDHotes:
        return 'Auberge et maison d\'hôtes';
      case ResidenceType.residenceHoteliere:
        return 'Résidence hôtelière';

      // 🌍 Hébergements insolites & nature
      case ResidenceType.bungalow:
        return 'Bungalow';
      case ResidenceType.lodgeEtEcolodge:
        return 'Lodge & Écolodge';
      case ResidenceType.caseTraditionnelle:
        return 'Case traditionnelle';
      case ResidenceType.maisonFlottante:
        return 'Maison flottante';
      case ResidenceType.campementTouristique:
        return 'Campement touristique';

      // 🏘️ Colocation & résidences partagées
      case ResidenceType.chambreEnColocation:
        return 'Chambre en colocation';
      case ResidenceType.cohabitation:
        return 'Cohabitation';
      case ResidenceType.residenceUniversitaire:
        return 'Résidence universitaire';
      case ResidenceType.citeDortoir:
        return 'Cité dortoir';

      // 🏡 Résidences longue durée
      case ResidenceType.appartementNonMeuble:
        return 'Appartement non meublé';
      case ResidenceType.villaNonMeublee:
        return 'Villa non meublée';
      case ResidenceType.immeuble:
        return 'Immeuble';
      case ResidenceType.courCommune:
        return 'Cour commune';

      // ⛺ Hébergements économiques et populaires
      case ResidenceType.maisonDHotesEconomique:
        return 'Maison d\'hôtes économique';
      case ResidenceType.residenceFamilialeEnLocation:
        return 'Résidence familiale en location';
      case ResidenceType.chambresDePassage:
        return 'Chambres de passage';

      // Types génériques de base
      case ResidenceType.apartment:
        return 'Appartement';
      case ResidenceType.studio:
        return 'Studio';
      case ResidenceType.villa:
        return 'Villa';
      case ResidenceType.house:
        return 'Maison';
      case ResidenceType.hotel:
        return 'Hôtel';
      case ResidenceType.luxury:
        return 'Résidence de luxe';
      case ResidenceType.other:
        return 'Autre';
    }
  }

  // Récupérer l'icône appropriée pour chaque type de résidence
  String get icon {
    switch (this) {
      // 🏠 Résidences meublées
      case ResidenceType.studioMeuble:
      case ResidenceType.appartementMeuble:
        return '🏠';
      case ResidenceType.villaMeublee:
      case ResidenceType.penthouse:
        return '🏘️';
      case ResidenceType.grenier:
        return '🏠';

      // 🏨 Hôtels & Hébergements classiques
      case ResidenceType.hotelDePassage:
      case ResidenceType.motel:
      case ResidenceType.boutiqueHotel:
      case ResidenceType.hotelDeLuxe:
      case ResidenceType.residenceHoteliere:
        return '🏨';
      case ResidenceType.aubergeEtMaisonDHotes:
        return '🏡';

      // 🌍 Hébergements insolites & nature
      case ResidenceType.bungalow:
      case ResidenceType.lodgeEtEcolodge:
      case ResidenceType.caseTraditionnelle:
        return '🌴';
      case ResidenceType.maisonFlottante:
        return '🚣';
      case ResidenceType.campementTouristique:
        return '⛺';

      // 🏘️ Colocation & résidences partagées
      case ResidenceType.chambreEnColocation:
      case ResidenceType.cohabitation:
      case ResidenceType.residenceUniversitaire:
      case ResidenceType.citeDortoir:
        return '🏘️';

      // 🏡 Résidences longue durée
      case ResidenceType.appartementNonMeuble:
        return '🏢';
      case ResidenceType.villaNonMeublee:
        return '🏡';
      case ResidenceType.immeuble:
        return '🏢';
      case ResidenceType.courCommune:
        return '🏘️';

      // ⛺ Hébergements économiques et populaires
      case ResidenceType.maisonDHotesEconomique:
      case ResidenceType.residenceFamilialeEnLocation:
      case ResidenceType.chambresDePassage:
        return '⛺';

      // Types génériques de base
      case ResidenceType.apartment:
        return '🏢';
      case ResidenceType.studio:
        return '🏠';
      case ResidenceType.villa:
        return '🏡';
      case ResidenceType.house:
        return '🏠';
      case ResidenceType.hotel:
        return '🏨';
      case ResidenceType.luxury:
        return '🏰';
      case ResidenceType.other:
        return '🏠';
    }
  }
}