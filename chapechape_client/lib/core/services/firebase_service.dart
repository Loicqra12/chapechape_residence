import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      debugPrint('🔥 Firebase initialisé avec succès');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation de Firebase: $e');
      // En cas d'erreur, nous pouvons quand même continuer l'exécution de l'application
    }
  }
}
