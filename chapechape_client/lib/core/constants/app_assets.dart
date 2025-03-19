import 'package:flutter/material.dart';

class AppAssets {
  // Logos
  static const String appLogo = 'assets/logos/app_logo.png';
  static const String appIcon = 'assets/logos/app_icon.png';
  static const String splashLogo = 'assets/logos/splash_logo.png';

  // Backgrounds
  static const String heroBg = 'assets/images/backgrounds/hero_bg.png';
  static const String citySkyline = 'assets/images/backgrounds/city_skyline.png';
  static const String mapBg = 'assets/images/backgrounds/map_bg.png';
  static const String patternGold = 'assets/images/backgrounds/pattern_gold.png';

  // Payment Methods
  static const String orangeMoney = 'assets/images/payment/orange_money.png';
  static const String mtnMoney = 'assets/images/payment/mtn_money.png';
  static const String moovMoney = 'assets/images/payment/moov_money.png';
  static const String waveMoney = 'assets/images/payment/wave_money.png';
  static const String visa = 'assets/images/payment/visa.png';
  static const String mastercard = 'assets/images/payment/mastercard.png';
  static const String paypal = 'assets/images/payment/paypal.png';

  // Category Icons
  static const String iconApartment = 'assets/icons/categories/apartment.png';
  static const String iconBed = 'assets/icons/categories/bed.png';
  static const String iconBungalow = 'assets/icons/categories/bungalow.png';
  static const String iconFiveStars = 'assets/icons/categories/five-stars.png';
  static const String iconPenthouse = 'assets/icons/categories/penthouse.png';
  static const String iconVilla = 'assets/icons/categories/villa.png';
  static const String iconCoworking = 'assets/icons/categories/coworking.png';
  static const String iconStudent = 'assets/icons/categories/student.png';
  static const String iconShortTerm = 'assets/icons/categories/short_term.png';
  static const String iconLongTerm = 'assets/icons/categories/long_term.png';

  // Amenity Icons
  static const String iconWifi = 'assets/icons/amenities/wifi.png';
  static const String iconAc = 'assets/icons/amenities/climatisation.png';
  static const String iconParking = 'assets/icons/amenities/parking.png';
  static const String iconPool = 'assets/icons/amenities/pool.png';
  static const String iconGym = 'assets/icons/amenities/gym.png';
  static const String iconSecurity = 'assets/icons/amenities/security.png';
  static const String iconElevator = 'assets/icons/amenities/elevator.png';
  static const String iconGarden = 'assets/icons/amenities/garden.png';
  static const String iconBalcony = 'assets/icons/amenities/balcony.png';
  static const String iconFurnished = 'assets/icons/amenities/furnished.png';

  // Country Flags
  static const String flagCI = 'assets/images/flags/cote-divoire.png';
  static const String flagSN = 'assets/images/flags/senegal.png';
  static const String flagML = 'assets/images/flags/mali.png';
  static const String flagBF = 'assets/images/flags/burkina-faso.png';
  static const String flagGH = 'assets/images/flags/ghana.png';
  static const String flagTG = 'assets/images/flags/togo.png';
  static const String flagBJ = 'assets/images/flags/benin.png';
  static const String flagGN = 'assets/images/flags/guinea.png';
  static const String flagNE = 'assets/images/flags/niger.png';
  static const String flagNG = 'assets/images/flags/nigeria.png';
  static const String flagLR = 'assets/images/flags/liberia.png';
  static const String flagSL = 'assets/images/flags/sierra-leone.png';
  static const String flagGM = 'assets/images/flags/gambia.png';
  static const String flagCV = 'assets/images/flags/cape-verde.png';

  // Residence Images
  static const String premium1 = 'assets/images/residences/premium1.png';
  static const String premium2 = 'assets/images/residences/premium2.png';
  static const String promo1 = 'assets/images/residences/promo1.png';
  static const String promo2 = 'assets/images/residences/promo2.png';
}

// Classe séparée pour les images des résidences
class ResidenceImages {
  // Apartments
  static const List<String> apartments = [
    'assets/images/residences/apartments/304661255.jpg',
    'assets/images/residences/apartments/450667738.jpg',
    'assets/images/residences/apartments/IMG_0668.jpg',
    'assets/images/residences/apartments/seen-hotel-abidjan-plateau.jpg',
  ];

  // Luxury
  static const List<String> luxury = [
    'assets/images/residences/luxury/Quai-dOrsay-large-studio-9920039024960.jpg',
    'assets/images/residences/luxury/Quai-dOrsay-large-studio-9920039024960.jpg',
  ];

  // Villas
  static const List<String> villas = [
    'assets/images/residences/apartments/304661255.jpg',
    'assets/images/residences/apartments/450667738.jpg',
  ];

  // Studios
  static const List<String> studios = [
    'assets/images/residences/apartments/IMG_0668.jpg',
    'assets/images/residences/luxury/images (3).jpg',
  ];
}

// Classe pour les assets de blog
class ResidenceAssets {
  static const String villa1 = 'assets/images/residences/apartments/304661255.jpg';
  static const String apartment4 = 'assets/images/residences/apartments/seen-hotel-abidjan-plateau.jpg';
  static const String studio2 = 'assets/images/residences/luxury/images (3).jpg';
  static const String luxury1 = 'assets/images/residences/luxury/Quai-dOrsay-large-studio-9920039024960.jpg';
}

// Énumération pour les types de résidences
enum ResidenceType {
  // Types existants (conservés pour compatibilité)
  apartment,
  studio,
  villa,
  room,
  bungalow,
  penthouse,
  hotel,
  luxury,
  coworking,
  student,
  
  // 🏠 Résidences meublées
  studioMeuble,
  appartementMeuble,
  villaMeublee,
  grenier,
  
  // 🏨 Hôtels & Hébergements classiques
  hotelDePassage,
  motel,
  boutiqueHotel,
  hotelDeLuxe,
  aubergeEtMaisonDHotes,
  residenceHoteliere,
  
  // 🌍 Hébergements insolites & nature
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
  
  // Valeur par défaut
  other
}

// Énumération pour les équipements
enum Amenity {
  wifi,
  ac,
  parking,
  pool,
  gym,
  security,
  elevator,
  garden,
  balcony,
  furnished
}

// Extension pour obtenir le chemin de l'icône
extension ResidenceTypeExtension on ResidenceType {
  String get iconPath {
    switch (this) {
      // Types existants
      case ResidenceType.apartment:
        return AppAssets.iconApartment;
      case ResidenceType.studio:
        return AppAssets.iconBed;
      case ResidenceType.villa:
        return AppAssets.iconVilla;
      case ResidenceType.bungalow:
        return AppAssets.iconBungalow;
      case ResidenceType.penthouse:
        return AppAssets.iconPenthouse;
      case ResidenceType.luxury:
        return AppAssets.iconFiveStars;
      case ResidenceType.coworking:
        return AppAssets.iconCoworking;
      case ResidenceType.student:
        return AppAssets.iconStudent;
      case ResidenceType.room:
        return AppAssets.iconBed;
        
      // 🏠 Résidences meublées
      case ResidenceType.studioMeuble:
        return AppAssets.iconBed;
      case ResidenceType.appartementMeuble:
        return AppAssets.iconApartment;
      case ResidenceType.villaMeublee:
        return AppAssets.iconVilla;
      case ResidenceType.grenier:
        return AppAssets.iconApartment; // À remplacer par une icône spécifique
        
      // 🏨 Hôtels & Hébergements classiques
      case ResidenceType.hotelDePassage:
        return AppAssets.iconFiveStars;
      case ResidenceType.motel:
        return AppAssets.iconBed;
      case ResidenceType.boutiqueHotel:
        return AppAssets.iconFiveStars;
      case ResidenceType.hotelDeLuxe:
        return AppAssets.iconFiveStars;
      case ResidenceType.aubergeEtMaisonDHotes:
        return AppAssets.iconVilla;
      case ResidenceType.residenceHoteliere:
        return AppAssets.iconApartment;
        
      // 🌍 Hébergements insolites & nature
      case ResidenceType.lodgeEtEcolodge:
        return AppAssets.iconBungalow;
      case ResidenceType.caseTraditionnelle:
        return AppAssets.iconBungalow;
      case ResidenceType.maisonFlottante:
        return AppAssets.iconBungalow; // À remplacer par une icône spécifique
      case ResidenceType.campementTouristique:
        return AppAssets.iconBungalow;
        
      // 🏘️ Colocation & résidences partagées
      case ResidenceType.chambreEnColocation:
        return AppAssets.iconBed;
      case ResidenceType.cohabitation:
        return AppAssets.iconApartment;
      case ResidenceType.residenceUniversitaire:
        return AppAssets.iconStudent;
      case ResidenceType.citeDortoir:
        return AppAssets.iconBed;
        
      // 🏡 Résidences longue durée
      case ResidenceType.appartementNonMeuble:
        return AppAssets.iconApartment;
      case ResidenceType.villaNonMeublee:
        return AppAssets.iconVilla;
      case ResidenceType.immeuble:
        return AppAssets.iconApartment;
      case ResidenceType.courCommune:
        return AppAssets.iconVilla;
        
      // ⛺ Hébergements économiques et populaires
      case ResidenceType.maisonDHotesEconomique:
        return AppAssets.iconBed;
      case ResidenceType.residenceFamilialeEnLocation:
        return AppAssets.iconVilla;
      case ResidenceType.chambresDePassage:
        return AppAssets.iconBed;
        
      // Valeur par défaut
      case ResidenceType.other:
      default:
        return AppAssets.iconApartment;
    }
  }
  
  // Nouvelle méthode pour obtenir des IconData à utiliser pour les icônes manquantes
  bool get hasCustomIcon {
    return [
      ResidenceType.grenier,
      ResidenceType.maisonFlottante,
      ResidenceType.caseTraditionnelle,
      ResidenceType.courCommune,
      ResidenceType.immeuble,
      ResidenceType.campementTouristique
    ].contains(this);
  }
  
  // Méthode qui retourne un IconData pour les types sans icône dédiée
  IconData get materialIcon {
    switch (this) {
      // Icônes pour les types qui n'ont pas encore d'image dédiée
      case ResidenceType.grenier:
        return Icons.roofing;
      case ResidenceType.maisonFlottante:
        return Icons.sailing;
      case ResidenceType.caseTraditionnelle:
        return Icons.home_work;
      case ResidenceType.courCommune:
        return Icons.holiday_village;
      case ResidenceType.immeuble:
        return Icons.domain;
      case ResidenceType.campementTouristique:
        return Icons.nature_people;
        
      // Types de base
      case ResidenceType.apartment:
        return Icons.apartment;
      case ResidenceType.studio:
        return Icons.single_bed;
      case ResidenceType.villa:
        return Icons.house;
      case ResidenceType.bungalow:
        return Icons.holiday_village;
      case ResidenceType.penthouse:
        return Icons.location_city;
      case ResidenceType.hotel:
        return Icons.hotel;
      case ResidenceType.luxury:
        return Icons.star;
      
      // Autres types
      default:
        return Icons.home;
    }
  }
  
  // Méthode pour obtenir une catégorie pour ce type
  String get category {
    // Types existants
    if ([
      ResidenceType.apartment,
      ResidenceType.studio,
      ResidenceType.villa,
      ResidenceType.room,
      ResidenceType.bungalow,
      ResidenceType.penthouse,
    ].contains(this)) {
      return 'Résidences';
    }
    
    if ([
      ResidenceType.hotel,
      ResidenceType.luxury,
    ].contains(this)) {
      return 'Hôtels & Luxe';
    }
    
    if ([
      ResidenceType.coworking,
      ResidenceType.student,
    ].contains(this)) {
      return 'Espaces spécialisés';
    }
    
    // Nouveaux types
    if ([
      ResidenceType.studioMeuble,
      ResidenceType.appartementMeuble,
      ResidenceType.villaMeublee,
      ResidenceType.grenier,
    ].contains(this)) {
      return '🏠 Résidences meublées';
    }
    
    if ([
      ResidenceType.hotelDePassage,
      ResidenceType.motel,
      ResidenceType.boutiqueHotel,
      ResidenceType.hotelDeLuxe,
      ResidenceType.aubergeEtMaisonDHotes,
      ResidenceType.residenceHoteliere,
    ].contains(this)) {
      return '🏨 Hôtels & Hébergements classiques';
    }
    
    if ([
      ResidenceType.bungalow,
      ResidenceType.lodgeEtEcolodge,
      ResidenceType.caseTraditionnelle,
      ResidenceType.maisonFlottante,
      ResidenceType.campementTouristique,
    ].contains(this)) {
      return '🌍 Hébergements insolites & nature';
    }
    
    if ([
      ResidenceType.chambreEnColocation,
      ResidenceType.cohabitation,
      ResidenceType.residenceUniversitaire,
      ResidenceType.citeDortoir,
    ].contains(this)) {
      return '🏘️ Colocation & résidences partagées';
    }
    
    if ([
      ResidenceType.appartementNonMeuble,
      ResidenceType.villaNonMeublee,
      ResidenceType.immeuble,
      ResidenceType.courCommune,
    ].contains(this)) {
      return '🏡 Résidences longue durée';
    }
    
    if ([
      ResidenceType.maisonDHotesEconomique,
      ResidenceType.residenceFamilialeEnLocation,
      ResidenceType.chambresDePassage,
    ].contains(this)) {
      return '⛺ Hébergements économiques et populaires';
    }
    
    return 'Autre';
  }
  
  // Vérifier si c'est une résidence spéciale (pour compatibilité)
  bool get isSpecialResidence {
    return this == ResidenceType.luxury ||
        this == ResidenceType.hotel ||
        this == ResidenceType.hotelDeLuxe ||
        this == ResidenceType.boutiqueHotel ||
        this == ResidenceType.residenceHoteliere;
  }
  
  // Vérifier si c'est une résidence de vacances (pour compatibilité)
  bool get isVacationResidence {
    return this == ResidenceType.villa ||
        this == ResidenceType.bungalow ||
        this == ResidenceType.hotel ||
        this == ResidenceType.villaMeublee ||
        this == ResidenceType.lodgeEtEcolodge ||
        this == ResidenceType.caseTraditionnelle ||
        this == ResidenceType.maisonFlottante ||
        this == ResidenceType.campementTouristique;
  }
}

// Extension pour obtenir le chemin de l'icône d'équipement
extension AmenityExtension on Amenity {
  String get iconPath {
    switch (this) {
      case Amenity.wifi:
        return AppAssets.iconWifi;
      case Amenity.ac:
        return AppAssets.iconAc;
      case Amenity.parking:
        return AppAssets.iconParking;
      case Amenity.pool:
        return AppAssets.iconPool;
      case Amenity.gym:
        return AppAssets.iconGym;
      case Amenity.security:
        return AppAssets.iconSecurity;
      case Amenity.elevator:
        return AppAssets.iconElevator;
      case Amenity.garden:
        return AppAssets.iconGarden;
      case Amenity.balcony:
        return AppAssets.iconBalcony;
      case Amenity.furnished:
        return AppAssets.iconFurnished;
    }
  }
}

// Classe pour les logos des partenaires
class PartnerAssets {
  static const List<String> logos = [
    'assets/logos/partners/partner1_logo.png',
    'assets/logos/partners/partner2_logo.png',
    'assets/logos/partners/partner3_logo.png',
    'assets/logos/partners/partner4_logo.png',
    'assets/logos/partners/partner5_logo.png',
  ];
}

// Classe pour les vidéos des résidences
class ResidenceVideos {
  // Chemins des vidéos
  static const List<String> videoTours = [
    'assets/videos/residence_tour1.mp4',
    'assets/videos/residence_tour2.mp4',
    'assets/videos/residence_tour3.mp4',
  ];
  
  // Chemins des thumbnails
  static const List<String> videoThumbnails = [
    'assets/images/video_thumbnails/thumbnail1.jpg',
    'assets/images/video_thumbnails/thumbnail2.jpg',
    'assets/images/video_thumbnails/thumbnail3.jpg',
  ];
  
  // Thumbnails individuels pour accès direct
  static const String villa1 = 'assets/images/video_thumbnails/thumbnail1.jpg';
  static const String apartment4 = 'assets/images/video_thumbnails/thumbnail2.jpg';
  static const String luxury1 = 'assets/images/video_thumbnails/thumbnail3.jpg';
}
