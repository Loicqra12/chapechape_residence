import '../models/residence_type_enum.dart';
import 'package:flutter/material.dart';

// Constantes pour les chemins d'assets
class AppAssets {
  // Images
  static const String appLogo = 'assets/logos/logo.png';
  static const String appLogoDark = 'assets/logos/logo_dark.png';
  static const String appIcon = 'assets/logos/app_icon.png';
  static const String splashLogo = 'assets/logos/splash_logo.png';
  static const String googleLogo = 'assets/icons/google_logo.png';
  
  // Retourne une URL pour un avatar dynamique basé sur le nom de l'utilisateur
  static String getDefaultAvatar({String name = 'User', int size = 100}) {
    // Encodage URL pour éviter les problèmes avec les caractères spéciaux
    final encodedName = Uri.encodeComponent(name);
    return 'https://ui-avatars.com/api/?name=$encodedName&size=$size&background=random&color=fff&bold=true';
  }
  
  static const String onboardingBackground1 = 'assets/images/onboarding/onboarding_bg_1.jpg';
  static const String onboardingBackground2 = 'assets/images/onboarding/onboarding_bg_2.jpg';
  static const String onboardingBackground3 = 'assets/images/onboarding/onboarding_bg_3.jpg';
  static const String emptyResult = 'assets/images/placeholders/empty_result.png';
  static const String noResultFound = 'assets/images/placeholders/no_results.png';
  static const String errorOccurred = 'assets/images/placeholders/error.png';
  static const String noConnection = 'assets/images/placeholders/no_connection.png';
  static const String mapMarker = 'assets/images/map/map_marker.png';
  static const String mapMarkerSelected = 'assets/images/map/map_marker_selected.png';
  static const String comingSoon = 'assets/images/placeholders/coming_soon.png';
  static const String heroBg = 'assets/images/hero/hero_background.jpg';
  static const String placeholderImage = 'assets/images/placeholders/residence_standard.jpg';
  static const String emptyWishlist = 'assets/images/placeholders/empty_wishlist.png';
  static const String welcomeImage = 'assets/images/backgrounds/welcome_bg.jpg';
  static const String loginBackground = 'assets/images/backgrounds/login_bg.jpg';
  static const String registerBackground = 'assets/images/backgrounds/register_bg.jpg';
  static const String homescreenPlan = 'assets/images/backgrounds/homescreen_plan.png';
  /// Bannière campagne app Partenaire (aperçu accueil).
  static const String partnerPromoBanner = 'assets/images/bannieres/banner_partner.png';
  /// Visuel plein écran après tap sur la bannière partenaire.
  static const String partnerPromoFullscreen = 'assets/images/bannieres/image_partner.png';
  static const String paymentSuccess = 'assets/images/payment/payment_success.png';
  static const String paymentError = 'assets/images/payment/payment_error.png';
  static const String searchBackground = 'assets/images/backgrounds/search_bg.jpg';
  static const String profileBackground = 'assets/images/backgrounds/profile_bg.jpg';
  
  // Icônes
  static const String iconHome = 'assets/icons/home.svg';
  static const String iconSearch = 'assets/icons/search.svg';
  static const String iconBooking = 'assets/icons/booking.svg';
  static const String iconProfile = 'assets/icons/profile.svg';
  static const String iconWishlist = 'assets/icons/wishlist.svg';
  static const String iconNotification = 'assets/icons/notification.svg';
  static const String iconFilter = 'assets/icons/filter.svg';
  static const String iconSort = 'assets/icons/sort.svg';
  static const String iconMap = 'assets/icons/map.svg';
  static const String iconList = 'assets/icons/list.svg';
  static const String iconCalendar = 'assets/icons/calendar.svg';
  static const String iconClock = 'assets/icons/clock.svg';
  static const String iconLocation = 'assets/icons/location.svg';
  static const String iconPhone = 'assets/icons/phone.svg';
  static const String iconEmail = 'assets/icons/email.svg';
  static const String iconEdit = 'assets/icons/edit.svg';
  static const String iconDelete = 'assets/icons/delete.svg';
  static const String iconSettings = 'assets/icons/settings.svg';
  static const String iconLogout = 'assets/icons/logout.svg';
  static const String iconHelp = 'assets/icons/help.svg';
  static const String iconInfo = 'assets/icons/info.svg';
  static const String iconStar = 'assets/icons/star.svg';
  
  // Icônes pour types de résidences
  static const String iconApartment = 'assets/icons/categories/apartment.svg';
  static const String iconVilla = 'assets/icons/categories/villa.svg';
  static const String iconHouse = 'assets/icons/categories/house.svg';
  static const String iconBungalow = 'assets/icons/categories/bungalow.svg';
  static const String iconBed = 'assets/icons/categories/bedroom.svg';
  static const String iconHotel = 'assets/icons/categories/hotel.svg';
  static const String iconPenthouse = 'assets/icons/categories/penthouse.svg';
  static const String iconFiveStars = 'assets/icons/categories/five-stars.svg';
  static const String iconOther = 'assets/icons/categories/other.svg';
  static const String iconStudent = 'assets/icons/categories/student.svg';
  
  // Icônes pour équipements
  static const String iconWifi = 'assets/icons/amenities/wifi.svg';
  static const String iconPool = 'assets/icons/amenities/pool.svg';
  static const String iconParking = 'assets/icons/amenities/parking.svg';
  static const String iconAc = 'assets/icons/amenities/air-conditioner.svg';
  static const String iconGym = 'assets/icons/amenities/gym.svg';
  static const String iconTv = 'assets/icons/amenities/tv.svg';
  static const String iconKitchen = 'assets/icons/amenities/kitchen.svg';
  static const String iconWasher = 'assets/icons/amenities/washer.svg';
  static const String iconBalcony = 'assets/icons/amenities/balcony.svg';
  static const String iconGarden = 'assets/icons/amenities/garden.svg';
  static const String iconSecurity = 'assets/icons/amenities/security.svg';
  static const String iconElevator = 'assets/icons/amenities/elevator.svg';
  
  // Logos de paiement
  static const String logoVisa = 'assets/logos/payment/visa.png';
  static const String logoMastercard = 'assets/logos/payment/mastercard.png';
  static const String logoPaypal = 'assets/logos/payment/paypal.png';
  static const String logoApplePay = 'assets/logos/payment/apple_pay.png';
  static const String logoGooglePay = 'assets/logos/payment/google_pay.png';
  static const String logoMtnMoney = 'assets/logos/payment/mtn_money.png';
  static const String logoOrangeMoney = 'assets/logos/payment/orange_money.png';
  static const String logoMoovMoney = 'assets/logos/payment/moov_money.png';
  static const String logoWave = 'assets/logos/payment/wave.png';
  
  // Animations
  static const String animationLoading = 'assets/animations/loading.json';
  static const String animationSuccess = 'assets/animations/success.json';
  static const String animationError = 'assets/animations/error.json';
  static const String animationEmpty = 'assets/animations/empty.json';
  static const String animationNoConnection = 'assets/animations/no_connection.json';
  static const String animationSearch = 'assets/animations/search.json';
  static const String animationWelcome = 'assets/animations/welcome.json';
  static const String animationBooking = 'assets/animations/booking.json';
  static const String animationConfetti = 'assets/animations/confetti.json';
}

// Classe pour les assets de blog
class ResidenceAssets {
  static const String villa1 = 'assets/images/residences/apartments/304661255.jpg';
  static const String apartment4 = 'assets/images/residences/apartments/seen-hotel-abidjan-plateau.jpg';
  static const String studio2 = 'assets/images/residences/luxury/images (3).jpg';
  static const String luxury1 = 'assets/images/residences/luxury/Quai-dOrsay-large-studio-9920039024960.jpg';
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
      default:
        return AppAssets.iconKitchen;
    }
  }
}

// Énumération pour les types de résidence (version simplifiée)
enum ResidenceType {
  apartment,
  studio,
  villa,
  house,
  bungalow,
  hotel,
  luxury,
  other
}

// Extension pour accéder à l'icône du type de résidence
extension ResidenceTypeExtension on ResidenceType {
  String get iconPath {
    switch (this) {
      case ResidenceType.apartment:
        return AppAssets.iconApartment;
      case ResidenceType.studio:
        return AppAssets.iconBed;
      case ResidenceType.villa:
        return AppAssets.iconVilla;
      case ResidenceType.house:
        return AppAssets.iconHouse;
      case ResidenceType.bungalow:
        return AppAssets.iconBungalow;
      case ResidenceType.hotel:
        return AppAssets.iconHotel;
      case ResidenceType.luxury:
        return AppAssets.iconFiveStars;
      case ResidenceType.other:
      default:
        return AppAssets.iconHouse;
    }
  }
  
  String get displayName {
    switch (this) {
      case ResidenceType.apartment:
        return 'Appartement';
      case ResidenceType.studio:
        return 'Studio';
      case ResidenceType.villa:
        return 'Villa';
      case ResidenceType.house:
        return 'Maison';
      case ResidenceType.bungalow:
        return 'Bungalow';
      case ResidenceType.hotel:
        return 'Hôtel';
      case ResidenceType.luxury:
        return 'Résidence Luxe';
      case ResidenceType.other:
      default:
        return 'Autre';
    }
  }
}

/// Convertit le ResidenceType du modèle vers le ResidenceType d'assets
/// Cette fonction sert de pont entre les deux
ResidenceType convertModelTypeToAssetType(dynamic modelType) {
  if (modelType == null) return ResidenceType.other;
  
  // Si c'est déjà un ResidenceType d'assets, le retourner
  if (modelType is ResidenceType) {
    return modelType;
  }
  
  // Si c'est une chaîne, essayer de convertir
  if (modelType is String) {
    switch (modelType.toLowerCase()) {
      case 'apartment':
      case 'appartement_meuble':
      case 'appartementmeuble':
        return ResidenceType.apartment;
      case 'studio':
      case 'studio_meuble':
      case 'studiomeuble':
        return ResidenceType.studio;
      case 'villa':
      case 'villa_meublee':
      case 'villameublee':
        return ResidenceType.villa;
      case 'house':
      case 'maison':
        return ResidenceType.house;
      case 'bungalow':
      case 'lodge':
        return ResidenceType.bungalow;
      case 'hotel':
      case 'auberge':
        return ResidenceType.hotel;
      case 'luxury':
      case 'penthouse':
        return ResidenceType.luxury;
      default:
        return ResidenceType.other;
    }
  }
  
  // Si c'est un modèle ResidenceType importé, convertir en fonction du nom
  try {
    String typeName = modelType.toString().split('.').last.toLowerCase();
    switch (typeName) {
      case 'studiomeuble':
      case 'studio':
        return ResidenceType.studio;
      case 'appartementmeuble':
      case 'appartementnonmeuble':
      case 'apartment':
        return ResidenceType.apartment;
      case 'villameublee':
      case 'villanonmeublee':
      case 'villa':
        return ResidenceType.villa;
      case 'house':
      case 'immeuble':
      case 'courcommune':
        return ResidenceType.house;
      case 'bungalow':
      case 'lodgetecolodge':
      case 'casetraditionnelle':
      case 'maisonflottante':
        return ResidenceType.bungalow;
      case 'hoteldepassage':
      case 'motel':
      case 'boutiquehotel':
      case 'hotel':
        return ResidenceType.hotel;
      case 'penthouse':
      case 'hoteldeluxe':
      case 'luxury':
        return ResidenceType.luxury;
      default:
        return ResidenceType.other;
    }
  } catch (e) {
    return ResidenceType.other;
  }
}
