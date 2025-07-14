import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';
import 'package:intl/intl.dart';

/// Classe principale pour gérer le watermark ChapeChape
class ChapeWatermark {
  /// Singleton
  static final ChapeWatermark _instance = ChapeWatermark._internal();
  factory ChapeWatermark() => _instance;
  ChapeWatermark._internal();

  /// Chemin du fichier de signature
  static const String _signaturePath = '.chape_meta/signature.yaml';

  /// Cache du watermark pour éviter de relire le fichier à chaque fois
  String? _cachedWatermark;
  Map<String, dynamic>? _signatureData;

  /// Retourne le watermark sous forme de chaîne formatée
  /// Format: "© [auteur] - [projet] ([date])"
  Future<String> getWatermark() async {
    if (_cachedWatermark != null) {
      return _cachedWatermark!;
    }

    try {
      await _loadSignatureData();
      if (_signatureData == null) {
        return "© ChapeChape Residence";
      }

      // Format de la date
      String dateStr = _signatureData!['date_creation'] ?? '';
      if (dateStr.isNotEmpty) {
        try {
          final date = DateTime.parse(dateStr);
          dateStr = DateFormat('yyyy-MM-dd').format(date);
        } catch (e) {
          // Garde la date telle quelle si le format n'est pas valide
        }
      }

      // Construction du watermark
      _cachedWatermark = "© ${_signatureData!['auteur']} - ${_signatureData!['projet']} ($dateStr)";
      return _cachedWatermark!;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du watermark: $e');
      return " ChapeChape Residence";
    }
  }

  /// Charge les données de signature depuis le fichier YAML
  Future<void> _loadSignatureData() async {
    if (_signatureData != null) return;

    try {
      // Initialisation de yamlContent pour éviter l'erreur de non-nullabilité
      String yamlContent = '';
      
      // En mode web ou plateforme non supportée
      if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        try {
          // Essaie de charger depuis les assets
          yamlContent = await rootBundle.loadString(_signaturePath);
        } catch (e) {
          debugPrint('Impossible de charger le fichier signature depuis les assets: $e');
          return;
        }
      } else {
        // Pour les plateformes natives, on cherche à partir du répertoire de travail
        Directory appDir;
        if (Platform.isAndroid || Platform.isIOS) {
          appDir = await getApplicationDocumentsDirectory();
        } else {
          appDir = Directory.current;
        }
        
        // Remonter jusqu'à trouver le fichier signature.yaml
        Directory currentDir = appDir;
        bool found = false;
        int maxDepth = 5;  // Évite les boucles infinies
        
        while (!found && maxDepth > 0) {
          final signatureFile = File(path.join(currentDir.path, _signaturePath));
          if (await signatureFile.exists()) {
            yamlContent = await signatureFile.readAsString();
            found = true;
            break;
          }
          
          // Remonte d'un niveau
          final parentDir = currentDir.parent;
          if (parentDir.path == currentDir.path) {
            // Nous sommes à la racine, impossible de remonter plus haut
            break;
          }
          
          currentDir = parentDir;
          maxDepth--;
        }
        
        if (!found) {
          // Si on n'a pas trouvé le fichier, on essaie de le charger depuis les assets
          try {
            yamlContent = await rootBundle.loadString(_signaturePath);
          } catch (e) {
            debugPrint('Fichier signature non trouvé: $e');
            return;
          }
        }
      }
      
      // Parse le contenu YAML
      final yamlMap = loadYaml(yamlContent) as YamlMap;
      _signatureData = Map<String, dynamic>.from(yamlMap.cast<String, dynamic>());
      
    } catch (e) {
      debugPrint('Erreur lors du chargement des données de signature: $e');
    }
  }
  
  /// Génère un hash SHA256 de l'arborescence du code
  /// Ce hash peut être utilisé pour vérifier l'intégrité du code
  static Future<String> generateCodeHash(String directory) async {
    if (kIsWeb) return 'non-supporté-sur-web';
    
    try {
      final files = await _listFilesRecursively(directory);
      files.sort(); // Pour avoir un résultat cohérent
      
      final fileContents = <String>[];
      for (final file in files) {
        if (file.endsWith('.dart') || file.endsWith('.yaml') || file.endsWith('.json')) {
          final content = await File(file).readAsString();
          fileContents.add(content);
        }
      }
      
      final allContent = fileContents.join('\n');
      final bytes = utf8.encode(allContent);
      final digest = sha256.convert(bytes);
      
      return digest.toString();
    } catch (e) {
      debugPrint('Erreur lors de la génération du hash: $e');
      return 'error-generating-hash';
    }
  }
  
  /// Liste récursivement les fichiers d'un répertoire
  static Future<List<String>> _listFilesRecursively(String directory) async {
    final files = <String>[];
    
    try {
      final dir = Directory(directory);
      if (!await dir.exists()) return files;
      
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          // Exclut certains répertoires et fichiers
          final relativePath = path.relative(entity.path, from: directory);
          if (!_shouldIgnore(relativePath)) {
            files.add(entity.path);
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du listing des fichiers: $e');
    }
    
    return files;
  }
  
  /// Détermine si un fichier doit être ignoré pour le hash
  static bool _shouldIgnore(String relativePath) {
    final ignoredDirs = [
      '.dart_tool', 'build', '.idea', '.vscode', '.git', 'node_modules', 
      'coverage', '.pub', '.flutter-plugins', '.metadata', 'generated_plugin_registrant'
    ];
    
    for (final dir in ignoredDirs) {
      if (relativePath.startsWith('$dir/') || relativePath == dir) {
        return true;
      }
    }
    
    final ignoredExtensions = [
      '.lock', '.log', '.jks', '.keystore', '.gradle', '.iml'
    ];
    
    for (final ext in ignoredExtensions) {
      if (relativePath.endsWith(ext)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Met à jour le hash dans le fichier signature.yaml
  static Future<bool> updateSignatureHash(String projectDirectory) async {
    if (kIsWeb) return false;
    
    try {
      final signatureFile = File(path.join(projectDirectory, _signaturePath));
      if (!await signatureFile.exists()) {
        debugPrint('Fichier signature non trouvé');
        return false;
      }
      
      // Génère le hash
      final hash = await generateCodeHash(projectDirectory);
      
      // Lit le contenu actuel
      String yamlContent = await signatureFile.readAsString();
      
      // Parse le YAML
      final yamlDoc = loadYaml(yamlContent);
      final yamlMap = Map<String, dynamic>.from((yamlDoc as YamlMap).cast<String, dynamic>());
      
      // Met à jour le hash
      yamlMap['hash'] = hash;
      
      // Convertit en YAML et écrit dans le fichier
      final newYaml = _mapToYaml(yamlMap);
      await signatureFile.writeAsString(newYaml);
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du hash de signature: $e');
      return false;
    }
  }
  
  /// Convertit une Map en chaîne YAML
  static String _mapToYaml(Map<String, dynamic> map) {
    final buffer = StringBuffer();
    
    map.forEach((key, value) {
      if (value is String) {
        // Entoure les chaînes contenant des caractères spéciaux avec des guillemets
        if (value.contains('\n') || value.contains(':') || value.contains('#')) {
          buffer.write('$key: "${value.replaceAll('"', '\\"')}"\n');
        } else {
          buffer.write('$key: $value\n');
        }
      } else {
        buffer.write('$key: $value\n');
      }
    });
    
    return buffer.toString();
  }
}
