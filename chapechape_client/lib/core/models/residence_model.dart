import 'package:freezed_annotation/freezed_annotation.dart';
import '../constants/app_assets.dart';

part 'residence_model.freezed.dart';
part 'residence_model.g.dart';

@freezed
class Residence with _$Residence {
  const factory Residence({
    required String id,
    required String name,
    required String description,
    required double price,
    required String address,
    required String city,
    required String country,
    required List<String> images,
    required int bedrooms,
    required int bathrooms,
    required double surface,
    required bool isAvailable,
    required Map<String, dynamic> location,
    @Default([]) List<String> amenities,
    @Default([]) List<String> rules,
    @Default(false) bool isFavorite,
    @Default(ResidenceType.apartment) ResidenceType type,
    double? rating,
    int? reviewCount,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Residence;

  factory Residence.fromJson(Map<String, dynamic> json) => _$ResidenceFromJson(json);
}

// Extensions pour ajouter des propriétés calculées
extension ResidenceProperties on Residence {
  bool get hasPool => amenities.contains('pool');
  
  bool get isVacationResidence => 
      type == ResidenceType.villa || 
      type == ResidenceType.bungalow || 
      type == ResidenceType.luxury;
      
  bool get isSpecialResidence => 
      type == ResidenceType.hotel || 
      type == ResidenceType.luxury;
      
  bool get isStudentResidence => 
      type == ResidenceType.studio;

  // Getters pour la compatibilité avec le code existant
  String get imageUrl => images.isNotEmpty ? images.first : getDefaultImageByType();
  String get title => name;
  String get status => isAvailable ? 'available' : 'unavailable';
  String get pricePerNight => '${price.toStringAsFixed(0)} FCFA/nuit';
  
  // Retourne une image par défaut en fonction du type de résidence
  String getDefaultImageByType() {
    if (type == null) {
      return 'assets/images/residences/apartments/304661255.jpg';
    }
    
    switch (type) {
      case ResidenceType.apartment:
        return ResidenceImages.apartments.isNotEmpty ? ResidenceImages.apartments.first : 'assets/images/residences/apartments/304661255.jpg';
      case ResidenceType.luxury:
        return ResidenceImages.luxury.isNotEmpty ? ResidenceImages.luxury.first : 'assets/images/residences/luxury/Quai-dOrsay-large-studio-9920039024960.jpg';
      case ResidenceType.studio:
        return ResidenceImages.studios.isNotEmpty ? ResidenceImages.studios.first : 'assets/images/residences/apartments/IMG_0668.jpg';
      case ResidenceType.villa:
        return ResidenceImages.villas.isNotEmpty ? ResidenceImages.villas.first : 'assets/images/residences/apartments/304661255.jpg';
      case ResidenceType.bungalow:
        return 'assets/images/residences/apartments/450667738.jpg';
      case ResidenceType.hotel:
        return 'assets/images/residences/apartments/seen-hotel-abidjan-plateau.jpg';
      case ResidenceType.penthouse:
        return 'assets/images/residences/luxury/Waterfront_view-5B-e1670065708270.webp';
      case ResidenceType.room:
        return 'assets/images/residences/apartments/IMG_0668.jpg';
      case ResidenceType.coworking:
        return 'assets/images/residences/apartments/seen-hotel-abidjan-plateau.jpg';
      case ResidenceType.student:
        return 'assets/images/residences/apartments/450667738.jpg';
      default:
        return 'assets/images/residences/apartments/304661255.jpg';
    }
  }
}

extension LocationExtension on Map<String, dynamic> {
  String get displayAddress {
    if (containsKey('formattedAddress')) {
      return this['formattedAddress'] as String;
    } else if (containsKey('address')) {
      return this['address'] as String;
    }
    return '';
  }
}