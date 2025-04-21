// Alias pour la classe Residence et adaptateurs pour la compatibilité
import 'residence_model.dart';
import 'residence_type_enum.dart';
export 'residence_model.dart' show Residence;

// Alias pour permettre l'utilisation de ResidenceModel
typedef ResidenceModel = Residence;

/// Extension pour assurer la compatibilité avec l'ancien usage de Residence
extension ResidenceBackwardCompatibility on Residence {
  // Getters pour les anciens noms de propriétés
  String get name => title;
  double get surface => squareMeters;
  String get address => location.containsKey('address') ? location['address'] as String : '';
  String get city => location.containsKey('city') ? location['city'] as String : '';
  String get country => location.containsKey('country') ? location['country'] as String : '';
  String get ownerId => owner;
  List<String> get photos => images;
  
  /// Crée une instance de Residence à partir d'un modèle legacy
  /// Cette méthode est utilisée pour migrer d'anciens codes vers le nouveau modèle
  static Residence fromLegacyModel({
    required String id,
    String? name,
    String? description,
    double? price = 0.0,
    String? address,
    String? city,
    String? country,
    List<String>? images,
    int? bedrooms = 0,
    int? bathrooms = 0,
    double? surface = 0.0,
    bool? isAvailable = true,
    Map<String, dynamic>? location,
    List<String>? amenities,
    ResidenceType? type,
    String? pricePeriod = 'month',
    double? hourlyRate = 0.0,
    double? halfDayRate = 0.0,
    double? fullDayRate = 0.0,
    double? weekendRate = 0.0,
    double? rating = 0.0,
    int? reviewCount = 0,
    bool? isFavorite = false,
  }) {
    // Construire l'objet location combiné
    Map<String, dynamic> combinedLocation = location ?? {};
    if (address != null) combinedLocation['address'] = address;
    if (city != null) combinedLocation['city'] = city;
    if (country != null) combinedLocation['country'] = country;
    
    // Éventuellement ajouter isFavorite aux priceDetails
    Map<String, dynamic>? priceDetails;
    if (isFavorite == true) {
      priceDetails = {'isFavorite': true};
    }
    
    // Renvoyer une nouvelle instance avec les propriétés requises du nouveau modèle
    return Residence(
      id: id,
      title: name ?? 'Sans titre',
      description: description ?? '',
      shortDescription: '',
      images: images ?? [],
      price: price ?? 0.0,
      location: combinedLocation,
      bedrooms: bedrooms ?? 0,
      bathrooms: bathrooms ?? 0,
      squareMeters: surface ?? 0.0,
      amenities: amenities ?? [],
      hasPool: amenities?.contains('pool') ?? false,
      hasWifi: amenities?.contains('wifi') ?? false,
      isVacationResidence: false,
      isSpecialResidence: false,
      isAvailable: isAvailable ?? true,
      isFeatured: false,
      isPopular: false,
      isVerified: false,
      isNew: false,
      rating: rating ?? 0.0,
      reviewCount: reviewCount ?? 0,
      currency: 'XOF',
      type: type ?? ResidenceType.other,
      maxOccupancy: (bedrooms ?? 0) * 2,
      owner: '',
      pricePeriod: pricePeriod ?? 'month', 
      hourlyRate: hourlyRate ?? 0.0,
      halfDayRate: halfDayRate ?? 0.0,
      fullDayRate: fullDayRate ?? 0.0,
      weekendRate: weekendRate ?? 0.0,
      priceDetails: priceDetails,
      allowsPets: false,
      allowsSmoking: false,
      allowsParties: false,
    );
  }
}
