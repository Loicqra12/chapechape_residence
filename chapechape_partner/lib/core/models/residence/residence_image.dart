import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

/// Modèle pour les images des résidences qui fonctionne à la fois sur mobile et web
class ResidenceImage {
  final File? file;
  final String? url;
  final Uint8List? _webImage;
  final bool isWeb;
  String? localPath; // Chemin local pour référence
  String? originalUrl; // URL d'origine pour les images existantes

  ResidenceImage({
    this.file,
    this.url,
    Uint8List? webImage,
    this.isWeb = false,
    this.localPath,
    this.originalUrl,
  }) : _webImage = webImage;

  Uint8List? get webImage => _webImage;

  // Constructeur pour les fichiers standards (mobile)
  ResidenceImage.fromFile(File file)
      : file = file,
        url = null,
        _webImage = null,
        isWeb = false,
        localPath = file.path,
        originalUrl = null;

  // Constructeur pour XFile (compatible web)
  ResidenceImage.fromXFile(XFile xFile, {Uint8List? webBytes}) 
      : file = null,
        url = null,
        _webImage = webBytes,
        isWeb = true,
        localPath = xFile.path,
        originalUrl = null;

  // Constructeur pour les données binaires (web)
  ResidenceImage.fromWebBytes(Uint8List bytes, {String? path})
      : file = null,
        url = null,
        _webImage = bytes,
        isWeb = true,
        localPath = path,
        originalUrl = null;

  // Constructeur pour URL (images existantes)
  ResidenceImage.fromUrl(String url)
      : file = null,
        url = url,
        _webImage = null,
        isWeb = false,
        localPath = null,
        originalUrl = url;

  // Utilitaires pour vérifier le type
  bool get hasMobileFile => file != null;
  bool get hasExistingUrl => originalUrl != null && originalUrl!.isNotEmpty;
  
  // Nouvelles propriétés pour la compatibilité avec le code existant
  bool get isLocal => file != null;
  String? get path => file?.path ?? localPath;

  // Méthode pour créer une liste de ResidenceImage à partir de données mixtes
  static List<ResidenceImage> fromMixed(List<dynamic> images) {
    List<ResidenceImage> result = [];
    
    for (var image in images) {
      if (image is File) {
        result.add(ResidenceImage(file: image));
      } else if (image is XFile) {
        result.add(ResidenceImage.fromXFile(image));
      } else if (image is String) {
        result.add(ResidenceImage.fromUrl(image));
      } else if (image is Map) {
        if (image['file'] != null) {
          result.add(ResidenceImage(file: image['file']));
        } else if (image['url'] != null) {
          result.add(ResidenceImage.fromUrl(image['url']));
        }
      }
    }
    
    return result;
  }
  
  // Méthode de débogage pour afficher les informations de l'image
  String getDebugInfo() {
    final StringBuffer info = StringBuffer();
    
    if (url != null) {
      info.write('URL: $url');
    }
    
    if (file != null) {
      info.write('File: ${file!.path}');
    }
    
    if (_webImage != null) {
      info.write('WebImage: ${_webImage!.length} octets');
    }
    
    if (localPath != null) {
      info.write(', Path: $localPath');
    }
    
    if (originalUrl != null) {
      info.write(', Original URL: $originalUrl');
    }
    
    info.write(', isWeb: $isWeb');
    info.write(', isLocal: $isLocal');
    
    return info.toString();
  }
}
