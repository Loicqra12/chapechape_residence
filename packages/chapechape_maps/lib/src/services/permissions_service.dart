import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Service pour gérer les permissions de localisation
class PermissionsService {
  /// Vérifie si l'application a la permission d'accéder à la localisation
  Future<bool> hasLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Erreur lors de la vérification des permissions: $e');
      return false;
    }
  }
  
  /// Demande la permission d'accéder à la localisation
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      // Si l'utilisateur a déjà refusé définitivement
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        
        // Si refusé définitivement, ne peut pas demander à nouveau
        if (permission == LocationPermission.deniedForever) {
          return false;
        }
        
        // Demander la permission
        permission = await Geolocator.requestPermission();
      }
      
      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('Erreur lors de la demande de permission: $e');
      return false;
    }
  }
  
  /// Vérifie si les services de localisation sont activés sur l'appareil
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('Erreur lors de la vérification du service de localisation: $e');
      return false;
    }
  }
  
  /// Ouvre les paramètres de localisation
  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint('Erreur lors de l\'ouverture des paramètres: $e');
    }
  }
  
  /// Ouvre les paramètres de l'application
  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('Erreur lors de l\'ouverture des paramètres de l\'app: $e');
    }
  }
}
