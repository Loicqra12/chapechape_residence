import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'map_service_interface.dart';

/// Implémentation de MapServiceInterface utilisant OpenStreetMap (flutter_map)
class OSMMapService implements MapServiceInterface {
  late MapController _mapController;
  
  OSMMapService() {
    _mapController = MapController();
  }
  
  @override
  Future<void> initialize() async {
    // Rien de spécial à initialiser pour OSM
    return;
  }
  
  @override
  Future<bool> isAvailable() async {
    // flutter_map est disponible par défaut car il utilise OSM qui est open source
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(latitude, longitude),
          initialZoom: zoom,
          onTap: onMapTap != null 
              ? (tapPosition, tapPoint) => onMapTap(tapPoint) 
              : null,
          onMapReady: onMapCreated != null 
              ? () => onMapCreated(_mapController) 
              : null,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.chapechape.chapechape_client',
            tileProvider: NetworkTileProvider(),
          ),
          MarkerLayer(
            markers: _getMarkersFromDynamic(markers),
          ),
        ],
      ),
    );
  }
  
  // Méthode d'aide pour convertir les marqueurs dynamiques en liste de marqueurs Flutter Map
  List<Marker> _getMarkersFromDynamic(Map<String, dynamic> markersMap) {
    final List<dynamic> dynamicMarkers = markersMap['markers'] as List<dynamic>? ?? [];
    final List<Marker> result = [];
    
    for (final marker in dynamicMarkers) {
      if (marker is Marker) {
        result.add(marker);
      }
    }
    
    return result;
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
    return Marker(
      width: 40.0,
      height: 40.0,
      point: LatLng(latitude, longitude),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 46,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              if (title != null && title.isNotEmpty)
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
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
    // Simuler une position par défaut puisqu'on ne peut pas accéder directement 
    // à la géolocalisation depuis flutter_map
    // Dans une implémentation réelle, vous utiliseriez un package comme geolocator
    
    // Coordonnées d'Abidjan comme position par défaut
    return {
      'latitude': 5.3599517,
      'longitude': -4.0082563,
    };
  }
  
  @override
  Future<bool> requestLocationPermission() async {
    // Simuler une autorisation pour le moment
    // Dans une implémentation réelle, vous utiliseriez un package comme permission_handler
    return true;
  }
}
