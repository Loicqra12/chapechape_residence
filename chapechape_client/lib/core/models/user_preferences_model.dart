import 'residence_type_enum.dart';

/// Modèle pour les préférences utilisateur
/// 
/// Ce modèle stocke les préférences de l'utilisateur pour la personnalisation
/// des recommandations de résidences
class UserPreferences {
  /// Localisations préférées de l'utilisateur (quartiers, villes)
  final List<String> preferredLocations;
  
  /// Types de résidences préférés
  final List<ResidenceType> preferredTypes;
  
  /// Plage de prix préférée
  final double minPrice;
  final double maxPrice;
  
  /// Plage de nombre de chambres préférée
  final int minBedrooms;
  final int maxBedrooms;
  
  /// Préférences pour les commodités
  final bool preferFurnished;
  final bool preferAirConditioned;
  final bool preferParking;
  final bool preferSwimmingPool;
  final bool preferSecurity;
  
  UserPreferences({
    this.preferredLocations = const [],
    this.preferredTypes = const [],
    this.minPrice = 0,
    this.maxPrice = 1000000,
    this.minBedrooms = 0,
    this.maxBedrooms = 10,
    this.preferFurnished = false,
    this.preferAirConditioned = false,
    this.preferParking = false,
    this.preferSwimmingPool = false,
    this.preferSecurity = true,
  });
  
  /// Crée une copie de l'objet avec les modifications spécifiées
  UserPreferences copyWith({
    List<String>? preferredLocations,
    List<ResidenceType>? preferredTypes,
    double? minPrice,
    double? maxPrice,
    int? minBedrooms,
    int? maxBedrooms,
    bool? preferFurnished,
    bool? preferAirConditioned,
    bool? preferParking,
    bool? preferSwimmingPool,
    bool? preferSecurity,
  }) {
    return UserPreferences(
      preferredLocations: preferredLocations ?? this.preferredLocations,
      preferredTypes: preferredTypes ?? this.preferredTypes,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minBedrooms: minBedrooms ?? this.minBedrooms,
      maxBedrooms: maxBedrooms ?? this.maxBedrooms,
      preferFurnished: preferFurnished ?? this.preferFurnished,
      preferAirConditioned: preferAirConditioned ?? this.preferAirConditioned,
      preferParking: preferParking ?? this.preferParking,
      preferSwimmingPool: preferSwimmingPool ?? this.preferSwimmingPool,
      preferSecurity: preferSecurity ?? this.preferSecurity,
    );
  }
  
  /// Convertit les préférences en Map pour le stockage
  Map<String, dynamic> toJson() {
    return {
      'preferredLocations': preferredLocations,
      'preferredTypes': preferredTypes.map((e) => e.toString().split('.').last).toList(),
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'minBedrooms': minBedrooms,
      'maxBedrooms': maxBedrooms,
      'preferFurnished': preferFurnished,
      'preferAirConditioned': preferAirConditioned,
      'preferParking': preferParking,
      'preferSwimmingPool': preferSwimmingPool,
      'preferSecurity': preferSecurity,
    };
  }
  
  /// Crée un objet de préférences à partir d'une Map
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      preferredLocations: (json['preferredLocations'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      preferredTypes: _parseResidenceTypes(json['preferredTypes']),
      minPrice: json['minPrice'] as double? ?? 0,
      maxPrice: json['maxPrice'] as double? ?? 1000000,
      minBedrooms: json['minBedrooms'] as int? ?? 0,
      maxBedrooms: json['maxBedrooms'] as int? ?? 10,
      preferFurnished: json['preferFurnished'] as bool? ?? false,
      preferAirConditioned: json['preferAirConditioned'] as bool? ?? false,
      preferParking: json['preferParking'] as bool? ?? false,
      preferSwimmingPool: json['preferSwimmingPool'] as bool? ?? false,
      preferSecurity: json['preferSecurity'] as bool? ?? true,
    );
  }
  
  /// Fonction utilitaire pour convertir une liste de chaînes en types de résidence
  static List<ResidenceType> _parseResidenceTypes(dynamic typesList) {
    if (typesList == null) return [];
    
    final List<dynamic> list = typesList as List<dynamic>;
    
    return list.map((item) {
      try {
        return ResidenceType.values.firstWhere(
          (e) => e.toString() == item || e.toString() == 'ResidenceType.$item',
          orElse: () => ResidenceType.apartment
        );
      } catch (e) {
        return ResidenceType.apartment;
      }
    }).toList();
  }
}
