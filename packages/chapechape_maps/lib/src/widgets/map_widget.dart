import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Widget de carte réutilisable avec des fonctionnalités avancées
class MapWidget extends StatelessWidget {
  /// Position initiale de la caméra
  final LatLng initialPosition;
  
  /// Niveau de zoom initial
  final double initialZoom;
  
  /// Marqueurs à afficher sur la carte
  final Set<Marker>? markers;
  
  /// Polylignes à afficher (pour les itinéraires)
  final Set<Polyline>? polylines;
  
  /// Polygones à afficher (pour les zones)
  final Set<Polygon>? polygons;
  
  /// Cercles à afficher (pour les rayons)
  final Set<Circle>? circles;
  
  /// Callback appelé quand la carte est prête
  final void Function(GoogleMapController)? onMapCreated;
  
  /// Callback appelé quand l'utilisateur tape sur la carte
  final void Function(LatLng)? onTap;
  
  /// Callback appelé quand l'utilisateur déplace la caméra
  final void Function(CameraPosition)? onCameraMove;
  
  /// Callback appelé quand l'utilisateur arrête de déplacer la caméra
  final VoidCallback? onCameraIdle;
  
  /// Afficher le bouton de localisation
  final bool myLocationButtonEnabled;
  
  /// Afficher la position actuelle de l'utilisateur
  final bool myLocationEnabled;
  
  /// Style de la carte (normal, satellite, terrain, etc.)
  final MapType mapType;
  
  /// Bordure arrondie de la carte
  final BorderRadius? borderRadius;
  
  /// Contrôleur de la carte
  final GoogleMapController? controller;
  
  /// Style JSON de la carte (thème personnalisé)
  final String? mapStyle;
  
  /// Constructeur
  const MapWidget({
    super.key,
    required this.initialPosition,
    this.initialZoom = 14.0,
    this.markers,
    this.polylines,
    this.polygons,
    this.circles,
    this.onMapCreated,
    this.onTap,
    this.onCameraMove,
    this.onCameraIdle,
    this.myLocationButtonEnabled = true,
    this.myLocationEnabled = true,
    this.mapType = MapType.normal,
    this.borderRadius,
    this.controller,
    this.mapStyle,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialPosition,
          zoom: initialZoom,
        ),
        markers: markers ?? {},
        polylines: polylines ?? {},
        polygons: polygons ?? {},
        circles: circles ?? {},
        onMapCreated: _onMapCreatedInternal,
        onTap: onTap,
        onCameraMove: onCameraMove,
        onCameraIdle: onCameraIdle,
        myLocationEnabled: myLocationEnabled,
        myLocationButtonEnabled: myLocationButtonEnabled,
        zoomControlsEnabled: true,
        mapToolbarEnabled: false,
        mapType: mapType,
        compassEnabled: true,
        trafficEnabled: false, // Peut être ajouté comme paramètre si nécessaire
      ),
    );
  }
  
  /// Callback interne appelé quand la carte est prête
  void _onMapCreatedInternal(GoogleMapController controller) {
    // Appliquer le style de la carte si fourni
    if (mapStyle != null) {
      controller.setMapStyle(mapStyle);
    }
    
    // Appeler le callback externe s'il est fourni
    if (onMapCreated != null) {
      onMapCreated!(controller);
    }
  }
}

/// Extension pour faciliter l'animation de la caméra
extension GoogleMapControllerExtension on GoogleMapController {
  /// Anime la caméra vers une position avec un niveau de zoom
  Future<void> animateToPosition(LatLng position, {double zoom = 14.0}) {
    return animateCamera(
      CameraUpdate.newLatLngZoom(position, zoom),
    );
  }
  
  /// Définit les limites de la carte en fonction d'une liste de positions
  Future<void> fitBounds(List<LatLng> positions, {double padding = 50.0}) {
    if (positions.isEmpty) return Future.value();
    
    // Trouver les limites
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;
    
    for (final position in positions) {
      if (position.latitude < minLat) minLat = position.latitude;
      if (position.latitude > maxLat) maxLat = position.latitude;
      if (position.longitude < minLng) minLng = position.longitude;
      if (position.longitude > maxLng) maxLng = position.longitude;
    }
    
    // Créer la limite
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    
    // Animer la caméra
    return animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
    );
  }
}
