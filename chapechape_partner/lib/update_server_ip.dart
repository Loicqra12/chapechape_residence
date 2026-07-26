import 'package:flutter/material.dart';
import 'core/config/app_config_manager.dart';
import 'package:chapechape_partner/core/utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser le gestionnaire de configuration
  await AppConfigManager.initialize(autoDetectIp: false);
  
  // Définir l'adresse IP du serveur
  await AppConfigManager.setServerIp('192.168.1.66');
  
  // Activer l'utilisation d'une URL personnalisée
  await AppConfigManager.setUseCustomServerUrl(true);
  
  AppLogger.d('✅ Configuration du serveur mise à jour avec succès !');
  AppLogger.d('🌐 Nouvelle URL API: ${AppConfigManager.apiUrl}');
}
