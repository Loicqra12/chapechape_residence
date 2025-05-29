

/// Modèle représentant un point d'intérêt à proximité d'une résidence
class NearbyPlace {
  final String name;
  final String type;
  final int distance; // distance en mètres
  final String description;

  NearbyPlace({
    required this.name,
    required this.type,
    required this.distance,
    required this.description,
  });

  /// Créer une copie avec certaines valeurs modifiées
  NearbyPlace copyWith({
    String? name,
    String? type,
    int? distance,
    String? description,
  }) {
    return NearbyPlace(
      name: name ?? this.name,
      type: type ?? this.type,
      distance: distance ?? this.distance,
      description: description ?? this.description,
    );
  }

  /// Convertir un objet JSON en NearbyPlace
  factory NearbyPlace.fromJson(Map<String, dynamic> json) {
    return NearbyPlace(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'other',
      distance: json['distance'] as int? ?? 0,
      description: json['description'] as String? ?? '',
    );
  }

  /// Convertir un NearbyPlace en objet JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'distance': distance,
      'description': description,
    };
  }

  /// Obtenir une icône pour ce type de lieu
  String get iconName {
    switch (type) {
      case 'restaurant':
        return 'restaurant';
      case 'shop':
        return 'store';
      case 'hospital':
        return 'local_hospital';
      case 'school':
        return 'school';
      case 'park':
        return 'park';
      case 'transport':
        return 'directions_bus';
      case 'beach':
        return 'beach_access';
      default:
        return 'place';
    }
  }

  /// Formater la distance pour l'affichage
  String get formattedDistance {
    if (distance < 1000) {
      return '$distance m';
    } else {
      final km = distance / 1000.0;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  @override
  String toString() => 'NearbyPlace(name: $name, type: $type, distance: $distance)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is NearbyPlace &&
           other.name == name &&
           other.type == type &&
           other.distance == distance &&
           other.description == description;
  }

  @override
  int get hashCode => name.hashCode ^ type.hashCode ^ distance.hashCode ^ description.hashCode;
}
