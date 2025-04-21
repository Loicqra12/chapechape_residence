import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../documentation/api_documentation.dart';

/// Service pour gérer la génération et l'exportation de la documentation API
class ApiDocumentationService {
  /// Instance singleton du service
  static final ApiDocumentationService _instance = ApiDocumentationService._internal();
  
  /// Constructeur d'usine pour retourner l'instance singleton
  factory ApiDocumentationService() {
    return _instance;
  }
  
  /// Constructeur privé
  ApiDocumentationService._internal();
  
  /// Génère la documentation API au format JSON
  String generateJsonDocumentation() {
    return ApiDocumentation.getOpenApiJson();
  }
  
  /// Génère la documentation API au format YAML
  /// Note: Cette méthode nécessiterait une bibliothèque de conversion JSON vers YAML
  /// Pour l'instant, elle retourne un message d'erreur
  String generateYamlDocumentation() {
    // TODO: Implémenter avec une bibliothèque YAML
    return "# La conversion en YAML n'est pas encore implémentée\n";
  }
  
  /// Exporte la documentation API dans un fichier sur le disque
  Future<String> exportDocumentation({
    required String format,
    String? customPath,
  }) async {
    String content;
    String extension;
    
    // Déterminer le format et générer le contenu approprié
    switch (format.toLowerCase()) {
      case 'json':
        content = generateJsonDocumentation();
        extension = 'json';
        break;
      case 'yaml':
      case 'yml':
        content = generateYamlDocumentation();
        extension = 'yaml';
        break;
      default:
        throw ArgumentError('Format non supporté: $format. Utilisez "json" ou "yaml".');
    }
    
    try {
      // Obtenir le répertoire de stockage
      final directory = await _getExportDirectory(customPath);
      
      // Créer le fichier avec un nom basé sur la date actuelle
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$directory/api_documentation_$timestamp.$extension';
      
      // Écrire le contenu dans le fichier
      final file = File(filePath);
      await file.writeAsString(content);
      
      if (kDebugMode) {
        print('Documentation API exportée avec succès à: $filePath');
      }
      
      return filePath;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'exportation de la documentation: $e');
      }
      throw Exception('Échec de l\'exportation de la documentation: $e');
    }
  }
  
  /// Méthode privée pour obtenir le répertoire d'exportation
  Future<String> _getExportDirectory(String? customPath) async {
    if (customPath != null && customPath.isNotEmpty) {
      final directory = Directory(customPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return customPath;
    }
    
    // Utiliser le répertoire de documents de l'application
    final appDocDir = await getApplicationDocumentsDirectory();
    final exportDir = '${appDocDir.path}/api_docs';
    
    final directory = Directory(exportDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
    return exportDir;
  }
  
  /// Génère un fichier HTML interactif pour visualiser la documentation API
  /// Cette méthode pourrait être utilisée pour créer une interface utilisateur
  /// intégrée permettant aux développeurs de consulter la documentation
  Future<String> generateHtmlDocumentation() async {
    final jsonSpec = generateJsonDocumentation();
    
    // Modèle HTML de base intégrant Swagger UI
    final htmlContent = '''
    <!DOCTYPE html>
    <html lang="fr">
    <head>
      <meta charset="UTF-8">
      <title>ChapeChape API Documentation</title>
      <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@4/swagger-ui.css">
      <style>
        body {
          margin: 0;
          padding: 0;
        }
        #swagger-ui {
          max-width: 1200px;
          margin: 0 auto;
        }
      </style>
    </head>
    <body>
      <div id="swagger-ui"></div>
      <script src="https://unpkg.com/swagger-ui-dist@4/swagger-ui-bundle.js"></script>
      <script>
        window.onload = function() {
          const ui = SwaggerUIBundle({
            spec: ${jsonSpec},
            dom_id: '#swagger-ui',
            deepLinking: true,
            presets: [
              SwaggerUIBundle.presets.apis,
              SwaggerUIBundle.SwaggerUIStandalonePreset
            ],
            layout: "BaseLayout",
            docExpansion: "list",
            defaultModelsExpandDepth: 1,
            defaultModelExpandDepth: 1
          });
          window.ui = ui;
        };
      </script>
    </body>
    </html>
    ''';
    
    // Exporter le fichier HTML
    final directory = await _getExportDirectory(null);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '$directory/api_documentation_$timestamp.html';
    
    final file = File(filePath);
    await file.writeAsString(htmlContent);
    
    return filePath;
  }
}
