import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;
import 'package:logging/logging.dart';
import 'package:image_picker/image_picker.dart';

/// Service d'optimisation d'images pour améliorer les performances et réduire la consommation réseau
class ImageOptimizationService {
  static final ImageOptimizationService _instance = ImageOptimizationService._internal();
  factory ImageOptimizationService() => _instance;
  ImageOptimizationService._internal();

  final Logger _logger = Logger('ImageOptimization');
  final Uuid _uuid = Uuid();
  
  /// Définit la qualité de compression des images (0-100)
  final int uploadQuality = 85;
  
  /// Définit la taille maximale des images téléchargées (en pixels)
  final int maxUploadWidth = 1920;
  final int maxUploadHeight = 1920;
  
  /// Compresse une image pour réduire sa taille avant envoi au serveur
  Future<Uint8List?> compressForUpload(Uint8List imageBytes) async {
    try {
      _logger.info('Compression d\'une image de ${imageBytes.length} octets');
      
      // Decoder l'image
      img.Image? decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        _logger.warning('Impossible de décoder l\'image');
        return null;
      }
      
      // Redimensionner si nécessaire
      img.Image resizedImage = _resizeIfNeeded(decodedImage);
      
      // Encoder l'image avec la qualité définie
      List<int> compressedBytes = img.encodeJpg(resizedImage, quality: uploadQuality);
      
      _logger.info('Image compressée à ${compressedBytes.length} octets (réduction de ${(100 - (compressedBytes.length / imageBytes.length * 100)).toStringAsFixed(1)}%)');
      
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      _logger.severe('Erreur lors de la compression de l\'image: $e');
      return null;
    }
  }
  
  /// Compresse une image depuis un fichier
  Future<File?> compressImageFile(File imageFile) async {
    try {
      if (kIsWeb) {
        _logger.warning('La compression de fichier n\'est pas supportée sur le web');
        return imageFile; // Pas de compression possible sur le web
      }
      
      _logger.info('Compression du fichier: ${imageFile.path}');
      
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      var result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path, 
        targetPath,
        quality: uploadQuality,
        minWidth: 1080,
        minHeight: 1080,
      );
      
      if (result == null) {
        _logger.warning('La compression a échoué');
        return imageFile;
      }
      
      // Convertir XFile en File
      File compressedFile = File(result.path);
      
      final originalSize = await imageFile.length();
      final compressedSize = await compressedFile.length();
      
      _logger.info('Fichier compressé de $originalSize à $compressedSize octets (réduction de ${(100 - (compressedSize / originalSize * 100)).toStringAsFixed(1)}%)');
      
      return compressedFile;
    } catch (e) {
      _logger.severe('Erreur lors de la compression du fichier: $e');
      return imageFile; // Retourner l'original en cas d'erreur
    }
  }

  /// Compresse une image à partir d'un XFile
  Future<File?> compressXFile(XFile xFile) async {
    try {
      if (kIsWeb) {
        // Sur le web, on ne peut pas manipuler les fichiers comme sur mobile
        _logger.warning('La compression XFile n\'est pas supportée sur le web');
        return File(xFile.path); // Simulation, ne fonctionnera pas réellement sur le web
      }
      
      // Convertir XFile en File puis compresser
      File file = File(xFile.path);
      return await compressImageFile(file);
    } catch (e) {
      _logger.severe('Erreur lors de la compression de XFile: $e');
      return File(xFile.path); // Retourner un File basé sur le chemin en cas d'erreur
    }
  }

  /// Redimensionne une image si elle dépasse les dimensions maximales
  img.Image _resizeIfNeeded(img.Image image) {
    // Vérifier si l'image dépasse les dimensions maximales
    if (image.width <= maxUploadWidth && image.height <= maxUploadHeight) {
      return image; // Pas besoin de redimensionner
    }
    
    // Calculer le ratio pour conserver les proportions
    double widthRatio = maxUploadWidth / image.width;
    double heightRatio = maxUploadHeight / image.height;
    double ratio = widthRatio < heightRatio ? widthRatio : heightRatio;
    
    // Calculer les nouvelles dimensions
    int newWidth = (image.width * ratio).round();
    int newHeight = (image.height * ratio).round();
    
    _logger.info('Redimensionnement de l\'image de ${image.width}x${image.height} à ${newWidth}x${newHeight}');
    
    // Redimensionner l'image
    return img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );
  }

  /// Génère une URL de cache unique pour une image
  String generateCacheKey(String url, {int? width, int? height}) {
    return 'img_${url.hashCode}_${width ?? 0}_${height ?? 0}';
  }
} 