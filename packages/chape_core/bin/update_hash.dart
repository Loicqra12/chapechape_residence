import 'dart:io';
import 'package:path/path.dart' as path;
import '../lib/src/watermark/watermark.dart';

/// Script pour générer et mettre à jour le hash dans le fichier signature.yaml
void main(List<String> arguments) async {
  final projectDir = arguments.isNotEmpty 
      ? arguments.first 
      : path.dirname(path.dirname(path.dirname(Platform.script.toFilePath())));
  
  print('📁 Projet: $projectDir');
  print('🔄 Génération du hash en cours...');
  
  final hash = await ChapeWatermark.generateCodeHash(projectDir);
  print('🔐 Hash généré: $hash');
  
  final success = await ChapeWatermark.updateSignatureHash(projectDir);
  if (success) {
    print('✅ Hash mis à jour dans .chape_meta/signature.yaml');
  } else {
    print('❌ Échec de la mise à jour du hash');
    exit(1);
  }
}
