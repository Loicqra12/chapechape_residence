import 'package:flutter/material.dart';
import 'test_residence_creation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Exécuter le test de création de résidence
  await testResidenceCreation();
  
  // Afficher une interface utilisateur minimaliste
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(
        title: const Text('Test Résidence'),
      ),
      body: const Center(
        child: Text('Consultez la console pour voir les résultats du test'),
      ),
    ),
  ));
} 