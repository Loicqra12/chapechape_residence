import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de géocodage qui permet de convertir entre adresses et coordonnées
class GeocodingService {
  static GeocodingService? _instance;
  final Dio _dio = Dio();
  
  // Cache pour éviter des requêtes répétitives
  final Map<String, LatLng> _addressCache = {};
  final Map<String, String> _coordinatesCache = {};
  
  // Clé pour la Google Maps API
  String? _apiKey;
  
  /// Singleton pattern
  factory GeocodingService() {
    _instance ??= GeocodingService._internal();
    return _instance!;
  }
  
  GeocodingService._internal();
  
  /// Initialise le service avec la clé API Google Maps
  Future<void> initialize(String apiKey) async {
    _apiKey = apiKey;
  }
  
  /// Convertit une adresse en coordonnées (latitude, longitude)
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    // Vérifier le cache d'abord
    if (_addressCache.containsKey(address)) {
      return _addressCache[address];
    }
    
    try {
      // Essayer d'abord avec la bibliothèque geocoding locale
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final latLng = LatLng(locations.first.latitude, locations.first.longitude);
        // Mettre en cache le résultat
        _addressCache[address] = latLng;
        return latLng;
      }
    } catch (e) {
      // En cas d'erreur, essayer avec l'API Google Maps si la clé est disponible
      if (_apiKey != null) {
        try {
          final response = await _dio.get(
            'https://maps.googleapis.com/maps/api/geocode/json',
            queryParameters: {
              'address': address,
              'key': _apiKey,
            },
          );
          
          if (response.statusCode == 200 && 
              response.data['status'] == 'OK' && 
              response.data['results'].isNotEmpty) {
            
            final location = response.data['results'][0]['geometry']['location'];
            final latLng = LatLng(location['lat'], location['lng']);
            
            // Mettre en cache le résultat
            _addressCache[address] = latLng;
            return latLng;
          }
        } catch (dioError) {
          debugPrint('Erreur API Google Maps: $dioError');
        }
      }
    }
    
    return null;
  }
  
  /// Convertit des coordonnées (latitude, longitude) en adresse
  Future<String?> getAddressFromCoordinates(LatLng coordinates) async {
    final coordKey = '${coordinates.latitude},${coordinates.longitude}';
    
    // Vérifier le cache d'abord
    if (_coordinatesCache.containsKey(coordKey)) {
      return _coordinatesCache[coordKey];
    }
    
    try {
      // Essayer d'abord avec la bibliothèque geocoding locale
      List<Placemark> placemarks = await placemarkFromCoordinates(
        coordinates.latitude, 
        coordinates.longitude
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final address = _formatAddress(placemark);
        
        // Mettre en cache le résultat
        _coordinatesCache[coordKey] = address;
        return address;
      }
    } catch (e) {
      // En cas d'erreur, essayer avec l'API Google Maps si la clé est disponible
      if (_apiKey != null) {
        try {
          final response = await _dio.get(
            'https://maps.googleapis.com/maps/api/geocode/json',
            queryParameters: {
              'latlng': coordKey,
              'key': _apiKey,
            },
          );
          
          if (response.statusCode == 200 && 
              response.data['status'] == 'OK' && 
              response.data['results'].isNotEmpty) {
            
            final address = response.data['results'][0]['formatted_address'];
            
            // Mettre en cache le résultat
            _coordinatesCache[coordKey] = address;
            return address;
          }
        } catch (dioError) {
          debugPrint('Erreur API Google Maps: $dioError');
        }
      }
    }
    
    return null;
  }
  
  /// Formate l'adresse à partir d'un Placemark
  String _formatAddress(Placemark placemark) {
    final List<String> addressParts = [];
    
    if (placemark.street != null && placemark.street!.isNotEmpty) {
      addressParts.add(placemark.street!);
    }
    
    if (placemark.locality != null && placemark.locality!.isNotEmpty) {
      addressParts.add(placemark.locality!);
    }
    
    if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
      addressParts.add(placemark.postalCode!);
    }
    
    if (placemark.country != null && placemark.country!.isNotEmpty) {
      addressParts.add(placemark.country!);
    }
    
    return addressParts.join(', ');
  }
  
  /// Sauvegarde les données du cache pour une utilisation future
  Future<void> saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('geocoding_address_cache', _addressCache.toString());
      await prefs.setString('geocoding_coordinates_cache', _coordinatesCache.toString());
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du cache: $e');
    }
  }
  
  /// Charge les données du cache depuis le stockage local
  Future<void> loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Implémenter le chargement du cache si nécessaire
      // Cette partie est plus complexe car nous devons désérialiser les maps
    } catch (e) {
      debugPrint('Erreur lors du chargement du cache: $e');
    }
  }
  
  /// Vide le cache
  void clearCache() {
    _addressCache.clear();
    _coordinatesCache.clear();
  }
}
