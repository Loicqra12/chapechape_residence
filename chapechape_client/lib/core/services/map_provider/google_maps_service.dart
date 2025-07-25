import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'map_service_interface.dart';

/// Implémentation de MapServiceInterface utilisant Google Maps
class GoogleMapsService implements MapServiceInterface {
  // Contrôleur pour interagir avec la carte
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  
  // Cache pour les marqueurs créés
  final Map<String, Marker> _markers = {};
  
  GoogleMapsService();
  
  @override
  Future<void> initialize() async {
    // GoogleMaps s'initialise lorsque le widget est créé
    return;
  }
  
  @override
  Future<bool> isAvailable() async {
    // On suppose que Google Maps est disponible si la bibliothèque est importée
    // Dans une implémentation plus robuste, on pourrait vérifier la disponibilité du service
    return true;
  }
  
  @override
  Widget createMapWidget({
    required double latitude,
    required double longitude,
    required double zoom,
    required Map<String, dynamic> markers,
    Function(dynamic)? onMapCreated,
    Function(dynamic)? onMapTap,
  }) {
    // Récupérer les marqueurs depuis l'objet passé en paramètre
    Set<Marker> googleMarkers = _getMarkersFromDynamic(markers);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(latitude, longitude),
          zoom: zoom,
        ),
        markers: googleMarkers,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
          if (onMapCreated != null) {
            onMapCreated(controller);
          }
        },
        onTap: onMapTap != null 
            ? (LatLng position) => onMapTap(position) 
            : null,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        compassEnabled: true,
        zoomControlsEnabled: false,
        mapType: MapType.normal,
      ),
    );
  }
  
  // Convertir les marqueurs dynamiques en un ensemble de marqueurs Google Maps
  Set<Marker> _getMarkersFromDynamic(Map<String, dynamic> markersMap) {
    if (markersMap.containsKey('markers') && markersMap['markers'] is List<dynamic>) {
      final List<dynamic> dynamicMarkers = markersMap['markers'] as List<dynamic>;
      final Set<Marker> result = {};
      
      for (final marker in dynamicMarkers) {
        if (marker is Marker) {
          result.add(marker);
        }
      }
      
      return result;
    }
    return {};
  }
  
  @override
  dynamic createMarker({
    required String id,
    required double latitude,
    required double longitude,
    String? title,
    String? snippet,
    Function()? onTap,
  }) {
    final marker = Marker(
      markerId: MarkerId(id),
      position: LatLng(latitude, longitude),
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet,
      ),
      onTap: onTap,
    );
    
    // Mettre en cache le marqueur pour une utilisation ultérieure
    _markers[id] = marker;
    
    return marker;
  }
  
  @override
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Formule de Haversine pour calculer la distance entre deux points
    const double earthRadius = 6371; // Rayon de la Terre en kilomètres
    
    // Convertir les latitudes et longitudes de degrés en radians
    final double latRad1 = lat1 * (pi / 180);
    final double lonRad1 = lon1 * (pi / 180);
    final double latRad2 = lat2 * (pi / 180);
    final double lonRad2 = lon2 * (pi / 180);
    
    // Différence de latitude et longitude
    final double dLat = latRad2 - latRad1;
    final double dLon = lonRad2 - lonRad1;
    
    // Formule de Haversine
    final double a = sin(dLat / 2) * sin(dLat / 2) +
                    cos(latRad1) * cos(latRad2) * 
                    sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = earthRadius * c;
    
    return distance;
  }
  
  @override
  Future<Map<String, double>?> getCurrentLocation() async {
    try {
      // Vérifier si la géolocalisation est activée
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Demander à l'utilisateur d'activer la géolocalisation
        return null;
      }
      
      // Vérifier les permissions de localisation
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // Demander la permission
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        // Les permissions sont définitivement refusées
        return null;
      }
      
      // Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      print('Erreur de géolocalisation: $e');
      
      // En cas d'erreur, retourner une position par défaut (Abidjan)
      return {
        'latitude': 5.3599517,
        'longitude': -4.0082563,
      };
    }
  }
  
  @override
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      return permission != LocationPermission.denied && 
             permission != LocationPermission.deniedForever;
    } catch (e) {
      print('Erreur lors de la demande de permission: $e');
      return false;
    }
  }
  
  // Méthodes supplémentaires spécifiques à Google Maps
  
  /// Déplace la caméra vers une position spécifique
  Future<void> animateToPosition(double latitude, double longitude, {double zoom = 14.0}) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(latitude, longitude),
        zoom: zoom,
      ),
    ));
  }
  
  /// Change le type de carte (normal, satellite, terrain, hybride)
  Future<void> changeMapType(MapType mapType) async {
    // Cette méthode devra être utilisée par le widget qui crée la carte
    // car le type de carte est une propriété du widget GoogleMap
  }
}
