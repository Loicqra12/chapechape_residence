import 'app_config_manager.dart';

/// Classe de compatibilité pour assurer la transition vers AppConfigManager
/// Maintient les mêmes propriétés statiques pour ne pas casser le code existant
class AppConfig {
  // Redirige vers le nouveau gestionnaire de configuration
  static String get apiUrl => AppConfigManager.apiUrl;
  
  // Configuration de l'application
  static String get appName => AppConfigManager.appName;
  static String get appVersion => AppConfigManager.appVersion;
  
  // Méthodes de formatage des URLs
  static String getApiEndpoint(String path) => AppConfigManager.getApiEndpoint(path);
  static String getMediaUrl(String path) => AppConfigManager.getMediaUrl(path);
}
