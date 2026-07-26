import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chapechape_partner/core/utils/secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'core/services/api/residence_service.dart';
import 'core/models/residence/residence_image.dart';
import 'package:chapechape_partner/core/utils/app_logger.dart';

/// Petit script à exécuter pour tester la création d'une résidence
Future<void> testResidenceCreation() async {
  AppLogger.d('=== Début du test de création de résidence ===');
  
  // Créer une instance du service
  final service = ResidenceService(
    baseUrl: 'http://localhost:4000/api',
    storage: AppSecureStorage.instance,
  );
  
  // Préparer les données de test
  final testData = {
    'name': 'Test Residence',
    'description': 'Description de test',
    'price': 100.0,
    'type': 'studio_meuble',
    'address': '123 Test Street',
    'city': 'Test City',
    'bedrooms': 1,
    'bathrooms': 1,
    'surface': 50.0,
    'amenities': ['wifi', 'parking'],
    'isAvailable': true,
  };
  
  // Créer une image de test si on est sur web
  List<ResidenceImage> testImages = [];
  if (kIsWeb) {
    final dummyImage = Uint8List.fromList([0, 1, 2, 3]); // Image factice
    testImages.add(ResidenceImage(webImage: dummyImage, isWeb: true));
  }
  
  try {
    AppLogger.d('Envoi de la requête de création...');
    final result = await service.createResidence(testData, testImages);
    AppLogger.d('Résidence créée avec succès: ${result.name}');
  } catch (e) {
    AppLogger.d('Erreur lors de la création: $e');
  }
  
  AppLogger.d('=== Fin du test de création de résidence ===');
} 