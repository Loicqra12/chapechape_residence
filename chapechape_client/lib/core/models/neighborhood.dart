/// Modèle représentant un quartier dans une ville
class Neighborhood {
  /// Identifiant unique du quartier
  final String id;
  
  /// Nom du quartier
  final String name;
  
  /// ID de la ville à laquelle appartient ce quartier
  final String cityId;
  
  /// Code du pays où se trouve le quartier
  final String countryCode;
  
  /// Description optionnelle du quartier
  final String? description;
  
  /// Indique si c'est un quartier populaire/important
  final bool isPopular;
  
  /// Latitude de la position centrale du quartier (optionnel)
  final double? latitude;
  
  /// Longitude de la position centrale du quartier (optionnel)
  final double? longitude;
  
  /// Code postal ou identifiant de zone (optionnel)
  final String? postalCode;
  
  /// Caractéristiques du quartier (résidentiel, commercial, etc.)
  final List<String>? features;

  const Neighborhood({
    required this.id,
    required this.name,
    required this.cityId,
    required this.countryCode,
    this.description,
    this.isPopular = false,
    this.latitude,
    this.longitude,
    this.postalCode,
    this.features,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Neighborhood &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
  
  /// Création d'une copie de l'objet avec des valeurs modifiées
  Neighborhood copyWith({
    String? id,
    String? name,
    String? cityId,
    String? countryCode,
    String? description,
    bool? isPopular,
    double? latitude,
    double? longitude,
    String? postalCode,
    List<String>? features,
  }) {
    return Neighborhood(
      id: id ?? this.id,
      name: name ?? this.name,
      cityId: cityId ?? this.cityId,
      countryCode: countryCode ?? this.countryCode,
      description: description ?? this.description,
      isPopular: isPopular ?? this.isPopular,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      postalCode: postalCode ?? this.postalCode,
      features: features ?? this.features,
    );
  }
  
  /// Conversion en Map pour sérialisation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cityId': cityId,
      'countryCode': countryCode,
      'description': description,
      'isPopular': isPopular,
      'latitude': latitude,
      'longitude': longitude,
      'postalCode': postalCode,
      'features': features,
    };
  }
  
  /// Création à partir d'une Map
  factory Neighborhood.fromJson(Map<String, dynamic> json) {
    return Neighborhood(
      id: json['id'],
      name: json['name'],
      cityId: json['cityId'],
      countryCode: json['countryCode'],
      description: json['description'],
      isPopular: json['isPopular'] ?? false,
      latitude: json['latitude'],
      longitude: json['longitude'],
      postalCode: json['postalCode'],
      features: json['features'] != null 
        ? List<String>.from(json['features']) 
        : null,
    );
  }
}
