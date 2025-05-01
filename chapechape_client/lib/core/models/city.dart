class City {
  final String id;
  final String name;
  final String region;
  final String? regionId;  // ID de la région (peut être null pour la compatibilité)
  final String countryCode;
  final double? latitude;
  final double? longitude;
  final bool isPopular;
  
  /// Nombre approximatif d'habitants
  final int? population;
  
  /// URL d'une image représentative de la ville
  final String? imageUrl;
  
  /// Nombre estimé de quartiers dans la ville
  final int? neighborhoodCount;
  
  /// Code postal principal de la ville
  final String? postalCode;
  
  /// Informations additionnelles sur la ville
  final Map<String, dynamic>? additionalInfo;
  
  const City({
    required this.id,
    required this.name,
    required this.region,
    this.regionId,
    required this.countryCode,
    this.latitude,
    this.longitude,
    this.isPopular = false,
    this.population,
    this.imageUrl,
    this.neighborhoodCount,
    this.postalCode,
    this.additionalInfo,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
  
  // Création d'une copie de l'objet avec des valeurs modifiées
  City copyWith({
    String? id,
    String? name,
    String? region,
    String? regionId,
    String? countryCode,
    double? latitude,
    double? longitude,
    bool? isPopular,
    int? population,
    String? imageUrl,
    int? neighborhoodCount,
    String? postalCode,
    Map<String, dynamic>? additionalInfo,
  }) {
    return City(
      id: id ?? this.id,
      name: name ?? this.name,
      region: region ?? this.region,
      regionId: regionId ?? this.regionId,
      countryCode: countryCode ?? this.countryCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPopular: isPopular ?? this.isPopular,
      population: population ?? this.population,
      imageUrl: imageUrl ?? this.imageUrl,
      neighborhoodCount: neighborhoodCount ?? this.neighborhoodCount,
      postalCode: postalCode ?? this.postalCode,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
  
  // Conversion de l'objet en Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'region': region,
      'regionId': regionId,
      'countryCode': countryCode,
      'latitude': latitude,
      'longitude': longitude,
      'isPopular': isPopular,
      'population': population,
      'imageUrl': imageUrl,
      'neighborhoodCount': neighborhoodCount,
      'postalCode': postalCode,
      'additionalInfo': additionalInfo,
    };
  }
  
  // Création d'un objet à partir d'une Map
  factory City.fromJson(Map<String, dynamic> map) {
    return City(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      region: map['region']?.toString() ?? '',
      regionId: map['regionId']?.toString(),
      countryCode: map['countryCode']?.toString() ?? '',
      latitude: map['latitude'] != null ? (map['latitude'] is double ? map['latitude'] : double.tryParse(map['latitude'].toString())) : null,
      longitude: map['longitude'] != null ? (map['longitude'] is double ? map['longitude'] : double.tryParse(map['longitude'].toString())) : null,
      isPopular: map['isPopular'] as bool? ?? false,
      population: map['population'] as int?,
      imageUrl: map['imageUrl'] as String?,
      neighborhoodCount: map['neighborhoodCount'] as int?,
      postalCode: map['postalCode'] as String?,
      additionalInfo: map['additionalInfo'] as Map<String, dynamic>?,
    );
  }
  
  // Alias pour compatibilité avec l'ancien code
  Map<String, dynamic> toMap() => toJson();
  factory City.fromMap(Map<String, dynamic> map) => City.fromJson(map);
}