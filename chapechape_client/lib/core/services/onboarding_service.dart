import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer l'état de l'onboarding
/// Permet de savoir si l'utilisateur a déjà vu l'onboarding
class OnboardingService {
  static const String _key = 'has_seen_onboarding';
  static const String _versionKey = 'onboarding_version';
  static const int _currentVersion = 1; // Incrémenter si vous changez l'onboarding

  /// Vérifie si l'utilisateur a déjà vu l'onboarding
  static Future<bool> hasSeenOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool(_key) ?? false;
      final version = prefs.getInt(_versionKey) ?? 0;
      
      // Si la version a changé, considérer comme non vu
      if (version < _currentVersion) {
        return false;
      }
      
      return hasSeen;
    } catch (e) {
      // En cas d'erreur, considérer comme non vu pour être sûr
      return false;
    }
  }

  /// Marque l'onboarding comme vu
  static Future<void> markOnboardingAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
      await prefs.setInt(_versionKey, _currentVersion);
    } catch (e) {
      // Ignorer les erreurs silencieusement
      // L'onboarding sera simplement re-affiché au prochain lancement
    }
  }

  /// Réinitialise l'état de l'onboarding (utile pour les tests ou le debug)
  static Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      await prefs.remove(_versionKey);
    } catch (e) {
      // Ignorer les erreurs
    }
  }

  /// Vérifie si l'onboarding doit être affiché (version mise à jour)
  static Future<bool> shouldShowOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final version = prefs.getInt(_versionKey) ?? 0;
      return version < _currentVersion;
    } catch (e) {
      return true; // En cas d'erreur, afficher l'onboarding
    }
  }
}








