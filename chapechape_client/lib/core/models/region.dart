/// Modèle représentant une région administrative d'un pays
class Region {
  /// Identifiant unique de la région
  final String id;
  
  /// Nom de la région
  final String name;
  
  /// Code du pays auquel appartient cette région
  final String countryCode;
  
  /// Description optionnelle de la région
  final String? description;
  
  /// Capitale ou ville principale de la région
  final String? mainCity;
  
  /// URL d'une image représentative de la région
  final String? imageUrl;
  
  /// Nombre approximatif de villes dans la région
  final int? cityCount;
  
  /// Latitude approximative du centre de la région
  final double? latitude;
  
  /// Longitude approximative du centre de la région
  final double? longitude;
  
  /// Informations additionnelles sur la région
  final Map<String, dynamic>? additionalInfo;

  const Region({
    required this.id,
    required this.name,
    required this.countryCode,
    this.description,
    this.mainCity,
    this.imageUrl,
    this.cityCount,
    this.latitude,
    this.longitude,
    this.additionalInfo,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Region &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
  
  /// Création d'une copie de l'objet avec des valeurs modifiées
  Region copyWith({
    String? id,
    String? name,
    String? countryCode,
    String? description,
    String? mainCity,
    String? imageUrl,
    int? cityCount,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Region(
      id: id ?? this.id,
      name: name ?? this.name,
      countryCode: countryCode ?? this.countryCode,
      description: description ?? this.description,
      mainCity: mainCity ?? this.mainCity,
      imageUrl: imageUrl ?? this.imageUrl,
      cityCount: cityCount ?? this.cityCount,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
  
  /// Conversion en Map pour sérialisation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'countryCode': countryCode,
      'description': description,
      'mainCity': mainCity,
      'imageUrl': imageUrl,
      'cityCount': cityCount,
      'latitude': latitude,
      'longitude': longitude,
      'additionalInfo': additionalInfo,
    };
  }
  
  /// Création à partir d'une Map
  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'],
      name: json['name'],
      countryCode: json['countryCode'],
      description: json['description'],
      mainCity: json['mainCity'],
      imageUrl: json['imageUrl'],
      cityCount: json['cityCount'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      additionalInfo: json['additionalInfo'],
    );
  }
  
  // Alias pour compatibilité avec l'ancien code
  Map<String, dynamic> toMap() => toJson();
  factory Region.fromMap(Map<String, dynamic> map) => Region.fromJson(map);
}
