import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'permissions_service.dart';

/// Service de localisation pour obtenir et suivre la position de l'utilisateur
class LocationService {
  static LocationService? _instance;
  
  // Stream de localisation
  StreamSubscription<Position>? _positionStream;
  final _locationController = StreamController<LatLng>.broadcast();
  
  // Dernière position connue
  LatLng? _lastKnownPosition;
  
  // Position par défaut si la géolocalisation n'est pas disponible
  // Centre de la carte de France (peut être modifié selon la zone d'activité principale)
  static const LatLng _defaultPosition = LatLng(46.603354, 1.888334); // France
  
  // Options de géolocalisation
  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // En mètres
  );
  
  /// Singleton pattern
  factory LocationService() {
    _instance ??= LocationService._internal();
    return _instance!;
  }
  
  LocationService._internal() {
    // Charger la dernière position connue depuis les préférences locales
    _loadLastKnownPosition();
  }
  
  /// Stream de la position actuelle
  Stream<LatLng> get positionStream => _locationController.stream;
  
  /// Dernière position connue ou position par défaut
  LatLng get currentPosition => _lastKnownPosition ?? _defaultPosition;
  
  /// Vérifie si le service de localisation est disponible et demande les permissions
  Future<bool> isLocationAvailable() async {
    final permissionsService = PermissionsService();
    final hasPermission = await permissionsService.requestLocationPermission();
    
    if (!hasPermission) {
      return false;
    }
    
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    return isServiceEnabled;
  }
  
  /// Obtient la position actuelle de l'utilisateur
  Future<LatLng> getCurrentPosition() async {
    try {
      final permissionsService = PermissionsService();
      final hasPermission = await permissionsService.requestLocationPermission();
      
      if (!hasPermission) {
        return _lastKnownPosition ?? _defaultPosition;
      }
      
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      final latLng = LatLng(position.latitude, position.longitude);
      _lastKnownPosition = latLng;
      
      // Sauvegarder la position dans les préférences
      _saveLastKnownPosition(latLng);
      
      return latLng;
    } catch (e) {
      debugPrint('Erreur de géolocalisation: $e');
      return _lastKnownPosition ?? _defaultPosition;
    }
  }
  
  /// Commence à suivre les changements de position
  Future<bool> startPositionStream() async {
    try {
      final permissionsService = PermissionsService();
      final hasPermission = await permissionsService.requestLocationPermission();
      
      if (!hasPermission) {
        return false;
      }
      
      // Arrêter le stream précédent s'il existe
      await stopPositionStream();
      
      // Démarrer un nouveau stream
      _positionStream = Geolocator.getPositionStream(
        locationSettings: _locationSettings
      ).listen((Position position) {
        final latLng = LatLng(position.latitude, position.longitude);
        _lastKnownPosition = latLng;
        _locationController.add(latLng);
        
        // Sauvegarder périodiquement la position
        _saveLastKnownPosition(latLng);
      });
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors du démarrage du stream de position: $e');
      return false;
    }
  }
  
  /// Arrête le suivi de la position
  Future<void> stopPositionStream() async {
    await _positionStream?.cancel();
    _positionStream = null;
  }
  
  /// Calcule la distance entre deux points en mètres
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude
    );
  }
  
  /// Sauvegarde la dernière position connue
  Future<void> _saveLastKnownPosition(LatLng position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_known_lat', position.latitude);
      await prefs.setDouble('last_known_lng', position.longitude);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde de la position: $e');
    }
  }
  
  /// Charge la dernière position connue depuis le stockage local
  Future<void> _loadLastKnownPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('last_known_lat');
      final lng = prefs.getDouble('last_known_lng');
      
      if (lat != null && lng != null) {
        _lastKnownPosition = LatLng(lat, lng);
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de la dernière position: $e');
    }
  }
  
  /// Nettoyage des ressources
  void dispose() {
    stopPositionStream();
    _locationController.close();
  }
}
