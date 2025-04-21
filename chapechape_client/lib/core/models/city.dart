class City {
  final String id;
  final String name;
  final String region;
  final String countryCode;
  final double? latitude;
  final double? longitude;
  final bool isPopular;
  
  const City({
    required this.id,
    required this.name,
    required this.region,
    required this.countryCode,
    this.latitude,
    this.longitude,
    this.isPopular = false,
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
    String? countryCode,
    double? latitude,
    double? longitude,
    bool? isPopular,
  }) {
    return City(
      id: id ?? this.id,
      name: name ?? this.name,
      region: region ?? this.region,
      countryCode: countryCode ?? this.countryCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPopular: isPopular ?? this.isPopular,
    );
  }
  
  // Conversion de l'objet en Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'region': region,
      'countryCode': countryCode,
      'latitude': latitude,
      'longitude': longitude,
      'isPopular': isPopular,
    };
  }
  
  // Création d'un objet à partir d'une Map
  factory City.fromMap(Map<String, dynamic> map) {
    return City(
      id: map['id'] as String,
      name: map['name'] as String,
      region: map['region'] as String,
      countryCode: map['countryCode'] as String,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      isPopular: map['isPopular'] as bool? ?? false,
    );
  }
} 