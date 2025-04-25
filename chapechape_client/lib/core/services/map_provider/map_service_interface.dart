import 'package:flutter/material.dart';

/// Interface pour abstraire les fournisseurs de cartes (Google Maps, Mapbox, OpenStreetMap, etc.)
abstract class MapServiceInterface {
  /// Initialiser le service
  Future<void> initialize();
  
  /// Vérifier si le service est disponible
  Future<bool> isAvailable();
  
  /// Créer un widget de carte
  Widget createMapWidget({
    required double latitude,
    required double longitude,
    required double zoom,
    required Map<String, dynamic> markers,
    Function(dynamic)? onMapCreated,
    Function(dynamic)? onMapTap,
  });
  
  /// Créer un marqueur pour la carte
  dynamic createMarker({
    required String id,
    required double latitude,
    required double longitude,
    String? title,
    String? snippet,
    Function()? onTap,
  });
  
  /// Calculer la distance entre deux points
  double calculateDistance(double lat1, double lon1, double lat2, double lon2);
  
  /// Obtenir la position actuelle de l'utilisateur
  Future<Map<String, double>?> getCurrentLocation();
  
  /// Demander l'autorisation de localisation
  Future<bool> requestLocationPermission();
}
