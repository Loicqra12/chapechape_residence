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
  apartment,
  studio,
  villa,
  room,
  bungalow,
  penthouse,
  hotel,
  luxury,
  coworking,
  student
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
      default:
        return AppAssets.iconApartment;
    }
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
