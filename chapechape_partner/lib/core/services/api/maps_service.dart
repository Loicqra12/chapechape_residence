import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chapechape_partner/core/utils/secure_storage.dart';
import '../../../core/exceptions/api_exception.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'package:chapechape_partner/core/utils/app_logger.dart';

/// Convertit une DioException en ApiException
ApiException _handleDioError(DioException e) {
  int statusCode = e.response?.statusCode ?? 0;
  String message = e.message ?? 'Erreur réseau';
  Map<String, dynamic> data = {};

  if (e.response != null) {
    // Essayer d'extraire le message d'erreur de la réponse si disponible
    if (e.response!.data is Map<String, dynamic>) {
      data = e.response!.data;
      if (data.containsKey('message')) {
        message = data['message'];
      }
    }
  }

  return ApiException(message, statusCode, data);
}

/// Service pour interagir avec les endpoints Maps de notre API backend
class MapsService {
  final String baseUrl;
  final Dio _dio;
  final FlutterSecureStorage _storage = AppSecureStorage.instance;

  MapsService({required this.baseUrl}) : _dio = Dio() {
    // Ajout des intercepteurs
    _dio.interceptors.add(AuthInterceptor(dio: _dio, storage: _storage));
    _dio.interceptors.add(RetryInterceptor(
      dio: _dio,
      maxRetries: 3,
      initialDelay: const Duration(milliseconds: 500),
      backoffFactor: 2.0,  // Augmente plus rapidement le délai
      maxDelay: const Duration(seconds: 15),
    ));
  }

  /// Géocodage d'une adresse (adresse → latitude/longitude)
  Future<Map<String, dynamic>> geocodeAddress(String address) async {
    try {
      final response = await _dio.post(
        '$baseUrl/maps/geocode',
        data: {'address': address},
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw ApiException(
          'Échec du géocodage: ${response.data['message'] ?? "Erreur inconnue"}',
          response.statusCode ?? 400,
          response.data ?? {},
        );
      }
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e);
      }
      throw ApiException(
        'Erreur lors du géocodage: $e', 
        500, 
        {'error': e.toString()},
      );
    }
  }

  /// Géocodage inverse (latitude/longitude → adresse)
  Future<Map<String, dynamic>> reverseGeocode(double latitude, double longitude) async {
    try {
      // Log pour le débogage
      AppLogger.d('📍 Tentative de géocodage inverse: lat=$latitude, lng=$longitude');
      
      // Vérification que les coordonnées sont des nombres valides
      if (latitude == 0 && longitude == 0) {
        AppLogger.d('⚠️ Coordonnées invalides (0,0) détectées lors du géocodage inverse');
      }
      
      // Vérification du token d'authentification avant l'envoi
      final token = await _storage.read(key: 'token');
      if (token == null || token.isEmpty) {
        AppLogger.d('❌ Erreur: Token d\'authentification manquant pour le géocodage inverse');
        return {'error': 'Token d\'authentification manquant'};
      }
      
      final response = await _dio.post(
        '$baseUrl/maps/reverse-geocode',
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token'
          }
        ),
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw ApiException(
          'Échec du géocodage inverse: ${response.data['message'] ?? "Erreur inconnue"}',
          response.statusCode ?? 400,
          response.data ?? {},
        );
      }
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e);
      }
      throw ApiException(
        'Erreur lors du géocodage inverse: $e', 
        500, 
        {'error': e.toString()},
      );
    }
  }

  /// Autocomplétion d'adresses
  Future<List<Map<String, dynamic>>> autocompleteAddress(String query) async {
    try {
      final response = await _dio.get(
        '$baseUrl/maps/autocomplete',
        queryParameters: {'query': query},
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw ApiException(
          'Échec de l\'autocomplétion: ${response.data['message'] ?? "Erreur inconnue"}',
          response.statusCode ?? 400,
          response.data ?? {},
        );
      }
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e);
      }
      throw ApiException(
        'Erreur lors de l\'autocomplétion: $e', 
        500, 
        {'error': e.toString()},
      );
    }
  }

  /// Recherche de résidences à proximité
  Future<List<dynamic>> findNearbyResidences(double latitude, double longitude, {double radius = 10.0}) async {
    try {
      final response = await _dio.get(
        '$baseUrl/maps/nearby',
        queryParameters: {
          'lat': latitude,
          'lng': longitude,
          'radius': radius,
        },
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw ApiException(
          'Échec de la recherche à proximité: ${response.data['message'] ?? "Erreur inconnue"}',
          response.statusCode ?? 400,
          response.data ?? {},
        );
      }
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e);
      }
      throw ApiException(
        'Erreur lors de la recherche à proximité: $e', 
        500, 
        {'error': e.toString()},
      );
    }
  }
  
  /// Convertit les données de géocodage en objet LatLng
  static LatLng? extractLatLng(Map<String, dynamic>? geocodeResult) {
    if (geocodeResult != null && 
        geocodeResult['latitude'] != null && 
        geocodeResult['longitude'] != null) {
      return LatLng(
        geocodeResult['latitude'], 
        geocodeResult['longitude']
      );
    }
    return null;
  }
}
