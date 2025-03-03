import 'dart:async';
import '../models/location_suggestion_model.dart';

class LocationService {
  // Simuler une API de suggestions de localisation
  Future<List<LocationSuggestionModel>> getSuggestions(String query) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (query.isEmpty) {
      return [];
    }
    
    // Suggestions fictives pour la démonstration
    final suggestions = [
      LocationSuggestionModel(
        id: '1',
        name: 'Cocody',
        fullAddress: 'Cocody, Abidjan, Côte d\'Ivoire',
        city: 'Abidjan',
        district: 'Cocody',
        country: 'Côte d\'Ivoire',
        latitude: 5.3601,
        longitude: -4.0083,
        isPopular: true,
        searchCount: 1250,
      ),
      LocationSuggestionModel(
        id: '2',
        name: 'Plateau',
        fullAddress: 'Plateau, Abidjan, Côte d\'Ivoire',
        city: 'Abidjan',
        district: 'Plateau',
        country: 'Côte d\'Ivoire',
        latitude: 5.3234,
        longitude: -4.0168,
        isPopular: true,
        searchCount: 980,
      ),
      LocationSuggestionModel(
        id: '3',
        name: 'Marcory',
        fullAddress: 'Marcory, Abidjan, Côte d\'Ivoire',
        city: 'Abidjan',
        district: 'Marcory',
        country: 'Côte d\'Ivoire',
        latitude: 5.3019,
        longitude: -3.9826,
        isPopular: true,
        searchCount: 850,
      ),
      LocationSuggestionModel(
        id: '4',
        name: 'Bietry',
        fullAddress: 'Bietry, Zone 4, Abidjan, Côte d\'Ivoire',
        city: 'Abidjan',
        district: 'Zone 4',
        country: 'Côte d\'Ivoire',
        latitude: 5.2910,
        longitude: -3.9734,
        isPopular: false,
        searchCount: 420,
      ),
      LocationSuggestionModel(
        id: '5',
        name: 'Riviera',
        fullAddress: 'Riviera, Cocody, Abidjan, Côte d\'Ivoire',
        city: 'Abidjan',
        district: 'Cocody',
        country: 'Côte d\'Ivoire',
        latitude: 5.3782,
        longitude: -3.9534,
        isPopular: true,
        searchCount: 1100,
      ),
    ];
    
    // Filtrer les suggestions en fonction de la requête
    return suggestions
        .where((suggestion) => 
            suggestion.name.toLowerCase().contains(query.toLowerCase()) ||
            suggestion.fullAddress.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
  
  // Obtenir les localisations populaires
  Future<List<LocationSuggestionModel>> getPopularLocations() async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Suggestions fictives pour la démonstration
    final suggestions = [
      LocationSuggestionModel(
        id: '1',
        name: 'Cocody',
        fullAddress: 'Cocody, Abidjan, Côte d\'Ivoire',
        city: 'Abidjan',
        district: 'Cocody',
        country: 'Côte d\'Ivoire',
        latitude: 5.3601,
        longitude: -4.0083,
        isPopular: true,
        searchCount: 1250,
      ),
      LocationSuggestionModel(
        id: '2',
        name: 'Plateau',
        fullAddress: 'Plateau, Abidjan, Côte d\'Ivoire',
        city: 'Abidjan',
        district: 'Plateau',
        country: 'Côte d\'Ivoire',
        latitude: 5.3234,
        longitude: -4.0168,
        isPopular: true,
        searchCount: 980,
      ),
      LocationSuggestionModel(
        id: '5',
        name: 'Riviera',
        fullAddress: 'Riviera, Cocody, Abidjan, Côte d\'Ivoire',
        city: 'Abidjan',
        district: 'Cocody',
        country: 'Côte d\'Ivoire',
        latitude: 5.3782,
        longitude: -3.9534,
        isPopular: true,
        searchCount: 1100,
      ),
    ];
    
    return suggestions;
  }
}
