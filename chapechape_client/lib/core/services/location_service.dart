import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/location_suggestion_model.dart';
import '../models/city.dart';
import '../models/country.dart';

class LocationService {
  static LocationService? _instance;
  List<City> _cities = [];
  List<Country> _countries = [];
  
  // Singleton pattern
  factory LocationService() {
    _instance ??= LocationService._internal();
    return _instance!;
  }
  
  LocationService._internal() {
    // Initialiser avec des données par défaut immédiatement
    _initializeDefaultData();
  }
  
  // Initialiser avec des données par défaut
  void _initializeDefaultData() {
    // Pays par défaut
    _countries = [
      Country(code: 'ci', name: 'Côte d\'Ivoire', phoneCode: '+225'),
      Country(code: 'sn', name: 'Sénégal', phoneCode: '+221'),
      Country(code: 'gh', name: 'Ghana', phoneCode: '+233'),
      Country(code: 'ng', name: 'Nigeria', phoneCode: '+234'),
    ];
    
    // Quelques villes de Côte d'Ivoire par défaut
    _cities = [
      City(
        id: 'abidjan',
        name: 'Abidjan',
        region: 'Lagunes',
        countryCode: 'ci',
        latitude: 5.3599517,
        longitude: -4.0082563,
        isPopular: true,
      ),
      City(
        id: 'yamoussoukro',
        name: 'Yamoussoukro',
        region: 'Lacs',
        countryCode: 'ci',
        latitude: 6.8276228,
        longitude: -5.2893433,
        isPopular: true,
      ),
      City(
        id: 'bouake',
        name: 'Bouaké',
        region: 'Vallée du Bandama',
        countryCode: 'ci',
        latitude: 7.6898329,
        longitude: -5.0309311,
        isPopular: true,
      ),
      City(
        id: 'cocody',
        name: 'Cocody',
        region: 'District Autonome d\'Abidjan',
        countryCode: 'ci',
        latitude: 5.3601774,
        longitude: -3.9812076,
        isPopular: true,
      ),
      City(
        id: 'plateau',
        name: 'Plateau',
        region: 'District Autonome d\'Abidjan',
        countryCode: 'ci',
        latitude: 5.3241081,
        longitude: -4.0211811,
        isPopular: true,
      ),
    ];
    
    // Essayer de charger les données complètes
    initialize();
  }
  
  // Initialisation du service
  Future<void> initialize() async {
    await _loadCountries();
    await _loadCities();
  }
  
  // Chargement des pays depuis le fichier JSON
  Future<void> _loadCountries() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/countries.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _countries = jsonList.map((json) => Country.fromMap(json)).toList();
    } catch (e) {
      print('Erreur lors du chargement des pays: $e');
    }
  }
  
  // Chargement des villes depuis le fichier JSON
  Future<void> _loadCities() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/cities.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _cities = jsonList.map((json) => City.fromMap(json)).toList();
    } catch (e) {
      print('Erreur lors du chargement des villes: $e');
    }
  }
  
  // Obtenir tous les pays
  List<Country> getCountries() {
    return _countries;
  }
  
  // Obtenir un pays par son code
  Country? getCountryByCode(String code) {
    try {
      return _countries.firstWhere((country) => country.code.toLowerCase() == code.toLowerCase());
    } catch (e) {
      return null;
    }
  }
  
  // Obtenir toutes les villes d'un pays
  List<City> getCitiesByCountry(String countryCode) {
    return _cities.where((city) => city.countryCode.toLowerCase() == countryCode.toLowerCase()).toList();
  }
  
  // Obtenir les villes populaires d'un pays
  List<City> getPopularCitiesByCountry(String countryCode) {
    return _cities.where(
      (city) => city.countryCode.toLowerCase() == countryCode.toLowerCase() && city.isPopular
    ).toList();
  }
  
  // Obtenir toutes les villes d'une région
  List<City> getCitiesByRegion(String countryCode, String region) {
    return _cities.where(
      (city) => city.countryCode.toLowerCase() == countryCode.toLowerCase() && 
                city.region.toLowerCase() == region.toLowerCase()
    ).toList();
  }
  
  // Recherche de villes par nom
  List<City> searchCities(String query, {String? countryCode}) {
    if (query.isEmpty) return [];
    
    final lowercaseQuery = query.toLowerCase();
    var filteredCities = _cities.where(
      (city) => city.name.toLowerCase().contains(lowercaseQuery)
    ).toList();
    
    if (countryCode != null) {
      filteredCities = filteredCities.where(
        (city) => city.countryCode.toLowerCase() == countryCode.toLowerCase()
      ).toList();
    }
    
    return filteredCities;
  }
  
  // Obtenir toutes les régions d'un pays
  List<String> getRegionsByCountry(String countryCode) {
    final cities = getCitiesByCountry(countryCode);
    final regions = cities.map((city) => city.region).toSet().toList();
    regions.sort();
    return regions;
  }
  
  // Obtenir une ville par son ID
  City? getCityById(String id) {
    try {
      return _cities.firstWhere((city) => city.id == id);
    } catch (e) {
      return null;
    }
  }
  
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
