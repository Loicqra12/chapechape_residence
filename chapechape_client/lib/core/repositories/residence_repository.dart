import 'package:flutter/foundation.dart';
import '../models/residence_model.dart';
import '../services/residence_service.dart';
import '../services/favorite_service.dart';

class ResidenceRepository {
  final ResidenceService _residenceService;
  final FavoriteService _favoriteService;

  ResidenceRepository({
    required ResidenceService residenceService,
    required FavoriteService favoriteService,
  }) : 
    _residenceService = residenceService,
    _favoriteService = favoriteService;

  /// Récupère toutes les résidences
  Future<List<Residence>> getResidences({
    Map<String, dynamic>? filters,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      return await _residenceService.getAllResidences(
        filters: filters,
        page: page,
        limit: limit,
      );
    } catch (e) {
      debugPrint('Erreur lors de la récupération des résidences: $e');
      return [];
    }
  }

  /// Récupère une résidence par son ID
  Future<Residence?> getResidence(String id) async {
    try {
      final residence = await _residenceService.getResidenceById(id);
      
      // Si la résidence n'est pas trouvée, retourner null
      if (residence == null) {
        return null;
      }

      // Vérifier si la résidence est dans les favoris
      final isFavorite = await _favoriteService.checkFavorite(id);
      
      // Mettre à jour l'état des favoris dans le modèle de résidence en modifiant priceDetails
      final Map<String, dynamic> updatedPriceDetails = Map<String, dynamic>.from(residence.priceDetails ?? {});
      updatedPriceDetails['isFavorite'] = isFavorite;
      
      return residence.copyWith(priceDetails: updatedPriceDetails);
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la résidence $id: $e');
      return null;
    }
  }

  /// Récupère les résidences par type
  Future<List<Residence>> getResidencesByType(String type) async {
    try {
      return await _residenceService.getResidencesByType(type);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des résidences de type $type: $e');
      return [];
    }
  }

  /// Récupère les résidences mises en avant
  Future<List<Residence>> getFeaturedResidences() async {
    try {
      return await _residenceService.getFeaturedResidences();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des résidences en vedette: $e');
      return [];
    }
  }

  /// Récupère les résidences spéciales
  Future<List<Residence>> getSpecialResidences() async {
    try {
      return await _residenceService.getSpecialResidences();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des résidences spéciales: $e');
      return [];
    }
  }

  /// Récupère les résidences populaires
  Future<List<Residence>> getPopularResidences() async {
    try {
      return await _residenceService.getPopularResidences();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des résidences populaires: $e');
      return [];
    }
  }

  /// Recherche des résidences
  Future<List<Residence>> searchResidences({
    required String query,
    Map<String, dynamic>? filters,
  }) async {
    try {
      // Extraire les paramètres du filtre pour les passer au service
      final city = filters?['city'] as String?;
      final minPrice = filters?['minPrice'] is num ? (filters!['minPrice'] as num).toDouble() : null;
      final maxPrice = filters?['maxPrice'] is num ? (filters!['maxPrice'] as num).toDouble() : null;
      final bedrooms = filters?['bedrooms'] is int ? filters!['bedrooms'] as int : null;
      final bathrooms = filters?['bathrooms'] is int ? filters!['bathrooms'] as int : null;
      final amenities = filters?['amenities'] is List ? List<String>.from(filters!['amenities'] as List) : null;
      final checkIn = filters?['checkIn'] as DateTime?;
      final checkOut = filters?['checkOut'] as DateTime?;
      
      return await _residenceService.searchResidences(
        query: query,
        city: city,
        minPrice: minPrice,
        maxPrice: maxPrice,
        bedrooms: bedrooms,
        bathrooms: bathrooms,
        amenities: amenities,
        checkIn: checkIn,
        checkOut: checkOut,
        forceRefresh: filters?['forceRefresh'] as bool? ?? false,
      );
    } catch (e) {
      debugPrint('Erreur lors de la recherche de résidences: $e');
      return [];
    }
  }

  /// Filtre des résidences
  Future<List<Residence>> filterResidences({
    required Map<String, dynamic> filters,
  }) async {
    try {
      return await _residenceService.getAllResidences(
        filters: filters,
      );
    } catch (e) {
      debugPrint('Erreur lors du filtrage des résidences: $e');
      return [];
    }
  }

  /// Vérifie la disponibilité d'une résidence
  Future<bool> checkAvailability({
    required String residenceId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      return await _residenceService.checkAvailability(
        residenceId: residenceId,
        checkIn: checkIn,
        checkOut: checkOut,
      );
    } catch (e) {
      debugPrint('Erreur lors de la vérification de disponibilité: $e');
      return false;
    }
  }
}

