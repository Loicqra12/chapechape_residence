import 'package:flutter/material.dart';
import 'core/config/app_config_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser le gestionnaire de configuration
  await AppConfigManager.initialize(autoDetectIp: false);
  
  // Définir l'adresse IP du serveur
  await AppConfigManager.setServerIp('192.168.1.70');
  
  // Activer l'utilisation d'une URL personnalisée
  await AppConfigManager.setUseCustomServerUrl(true);
  
  print('✅ Configuration du serveur mise à jour avec succès !');
  print('🌐 Nouvelle URL API: ${AppConfigManager.apiUrl}');
}
