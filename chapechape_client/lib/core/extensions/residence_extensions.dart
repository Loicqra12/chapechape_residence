import 'package:chapechape_client/core/models/residence_model.dart';

/// Extensions pour simplifier l'accès aux coordonnées géographiques des résidences
extension ResidenceLocationExtension on Residence {
  /// Retourne la latitude de la résidence, ou null si les coordonnées ne sont pas disponibles
  double? get latitude {
    try {
      // Support du nouveau format (objet avec propriétés latitude/longitude)
      if (location != null) {
        // Si les coordonnées sont directement disponibles
        if (location['latitude'] != null) {
          var value = location['latitude'];
          return value is int ? value.toDouble() : value as double?;
        }
        
        // Si on a un champ locationData avec coordinates
        if (location['locationData'] != null) {
          var locationData = location['locationData'];
          if (locationData is Map) {
            // Format avec locationData.coordinates comme Map
            if (locationData['coordinates'] != null) {
              var coordinates = locationData['coordinates'];
              if (coordinates is Map && coordinates['latitude'] != null) {
                var value = coordinates['latitude'];
                return value is int ? value.toDouble() : value as double?;
              }
            }
          }
        }
        
        // Support des coordonnées directes dans location
        if (location['coordinates'] != null) {
          var coordinates = location['coordinates'];
          if (coordinates is Map && coordinates['latitude'] != null) {
            // Format {coordinates: {latitude: X, longitude: Y}}
            var value = coordinates['latitude'];
            return value is int ? value.toDouble() : value as double?;
          } else if (coordinates is List && coordinates.length >= 2) {
            // Format ancien {coordinates: [lng, lat]}
            var value = coordinates[1];
            return value is int ? value.toDouble() : value as double?;
          }
        }
      }
    } catch (e) {
      print('Erreur lors de l\'accès à la latitude: $e');
    }
    return null;
  }

  /// Retourne la longitude de la résidence, ou null si les coordonnées ne sont pas disponibles
  double? get longitude {
    try {
      // Support du nouveau format (objet avec propriétés latitude/longitude)
      if (location != null) {
        // Si les coordonnées sont directement disponibles
        if (location['longitude'] != null) {
          var value = location['longitude'];
          return value is int ? value.toDouble() : value as double?;
        }
        
        // Si on a un champ locationData avec coordinates
        if (location['locationData'] != null) {
          var locationData = location['locationData'];
          if (locationData is Map) {
            // Format avec locationData.coordinates comme Map
            if (locationData['coordinates'] != null) {
              var coordinates = locationData['coordinates'];
              if (coordinates is Map && coordinates['longitude'] != null) {
                var value = coordinates['longitude'];
                return value is int ? value.toDouble() : value as double?;
              }
            }
          }
        }
        
        // Support des coordonnées directes dans location
        if (location['coordinates'] != null) {
          var coordinates = location['coordinates'];
          if (coordinates is Map && coordinates['longitude'] != null) {
            // Format {coordinates: {latitude: X, longitude: Y}}
            var value = coordinates['longitude'];
            return value is int ? value.toDouble() : value as double?;
          } else if (coordinates is List && coordinates.length >= 2) {
            // Format ancien {coordinates: [lng, lat]}
            var value = coordinates[0];
            return value is int ? value.toDouble() : value as double?;
          }
        }
      }
    } catch (e) {
      print('Erreur lors de l\'accès à la longitude: $e');
    }
    return null;
  }
}
