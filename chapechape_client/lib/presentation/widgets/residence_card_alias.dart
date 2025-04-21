// Ce fichier existe pour maintenir la compatibilité avec le code existant
// qui pourrait utiliser l'un ou l'autre widget avec le même nom.
export 'residence_card.dart' show ResidenceCard;

import '../../core/models/residence_model.dart';
import '../../core/models/residence_model_alias.dart';
import '../../core/models/residence_type_enum.dart';
import '../../core/utils/residence_adapters.dart';

/// Cette fonction aide à convertir un ancien format de création de Residence vers le nouveau format
/// Elle est conçue pour faciliter la transition entre les modèles
Residence createResidence({
  required String id,
  String? name,
  String? title,
  String? description,
  double? price = 0.0,
  String? address,
  String? city,
  String? country,
  List<String>? images,
  int bedrooms = 0,
  int bathrooms = 0,
  double? surface,
  double? squareMeters,
  bool isAvailable = true,
  Map<String, dynamic>? location,
  List<String>? amenities,
  // Convertit plusieurs façons de spécifier le type en une seule
  dynamic type,
  String? pricePeriod = 'month',
  double hourlyRate = 0.0,
  double halfDayRate = 0.0,
  double fullDayRate = 0.0,
  double weekendRate = 0.0,
  double rating = 0.0,
  int reviewCount = 0,
  bool isFavorite = false,
  String? owner,
  String? ownerId,
  DateTime? createdAt,
  DateTime? updatedAt,
  List<String>? rules,
  Map<String, dynamic>? priceDetails,
}) {
  // Si title est null mais name ne l'est pas, utiliser name comme title
  title = title ?? name ?? '';
  
  // Si squareMeters est null mais surface ne l'est pas, utiliser surface comme squareMeters
  squareMeters = squareMeters ?? surface ?? 0.0;
  
  // Construire l'objet location en combinant les champs individuels et l'objet location
  Map<String, dynamic> combinedLocation = location ?? {};
  if (address != null) combinedLocation['address'] = address;
  if (city != null) combinedLocation['city'] = city;
  if (country != null) combinedLocation['country'] = country;
  
  // Ajouter isFavorite aux priceDetails
  Map<String, dynamic> updatedPriceDetails = priceDetails ?? {};
  if (isFavorite) {
    updatedPriceDetails['isFavorite'] = true;
  }
  
  // Résoudre le type
  ResidenceType resolvedType;
  
  // Utiliser l'utilitaire de parsing pour obtenir une instance correcte de ResidenceType
  if (type is String) {
    resolvedType = ResidenceAdapters.parseResidenceTypeString(type);
  } else if (type is ResidenceType) {
    resolvedType = type;
  } else {
    resolvedType = ResidenceType.other;
  }
  
  // Construire une instance avec tous les paramètres requis
  return Residence(
    id: id,
    title: title,
    description: description ?? '',
    shortDescription: '',
    images: images ?? [],
    price: price ?? 0.0,
    location: combinedLocation,
    bedrooms: bedrooms,
    bathrooms: bathrooms,
    squareMeters: squareMeters,
    amenities: amenities ?? [],
    hasPool: amenities?.contains('pool') ?? false,
    hasWifi: amenities?.contains('wifi') ?? false,
    isVacationResidence: false,
    isSpecialResidence: false,
    isAvailable: isAvailable,
    isFeatured: false,
    isPopular: false,
    isVerified: false,
    isNew: false,
    rating: rating,
    reviewCount: reviewCount,
    currency: 'XOF',
    type: resolvedType,
    maxOccupancy: bedrooms * 2,
    owner: owner ?? ownerId ?? '',
    createdAt: createdAt,
    updatedAt: updatedAt,
    allowsPets: false,
    allowsSmoking: false,
    allowsParties: false,
    pricePeriod: pricePeriod ?? 'month', 
    hourlyRate: hourlyRate,
    halfDayRate: halfDayRate,
    fullDayRate: fullDayRate,
    weekendRate: weekendRate,
    priceDetails: updatedPriceDetails,
  );
} 