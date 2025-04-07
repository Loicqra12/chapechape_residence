import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path/path.dart' as path;
import 'image_optimization_service.dart';
import '../../models/residence/residence_image.dart';
import 'package:flutter/material.dart';

/// Service de gestion des médias qui intègre l'optimisation d'image
/// et la gestion du cache pour l'application
class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  final Logger _logger = Logger('MediaService');
  final Uuid _uuid = Uuid();
  final ImageOptimizationService _imageOptimizationService = ImageOptimizationService();
  
  /// Taille maximale des images en Ko (par défaut 5 Mo)
  static const int maxImageSizeKB = 5 * 1024;
  
  /// Liste des formats d'image autorisés
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];

  /// Optimise une liste d'images pour l'upload
  Future<List<ResidenceImage>> optimizeImagesForUpload(List<ResidenceImage> images) async {
    final List<ResidenceImage> optimizedImages = [];
    _logger.info('Optimisation de ${images.length} images pour upload');

    for (var i = 0; i < images.length; i++) {
      try {
        final image = images[i];
        
        // Si c'est une URL externe, l'ajouter directement
        if (image.url != null && image.url!.startsWith('http')) {
          _logger.fine('Image ${i+1}/${images.length}: URL externe (non optimisée)');
          optimizedImages.add(image);
          continue;
        }
        
        // Si c'est une image web (Uint8List)
        if (image.isWeb && image.webImage != null) {
          _logger.fine('Image ${i+1}/${images.length}: Optimisation d\'image web');
          
          // Compresser l'image
          final compressedBytes = await _imageOptimizationService.compressForUpload(image.webImage!);
          
          if (compressedBytes != null) {
            optimizedImages.add(ResidenceImage.fromWebBytes(compressedBytes));
            _logger.fine('Image ${i+1} optimisée avec succès');
          } else {
            // En cas d'échec, ajouter l'original
            optimizedImages.add(image);
            _logger.warning('Impossible d\'optimiser l\'image ${i+1}, utilisation de l\'original');
          }
        } 
        // Si c'est un fichier (mobile)
        else if (!kIsWeb && image.file != null) {
          _logger.fine('Image ${i+1}/${images.length}: Optimisation de fichier mobile');
          
          // Compresser le fichier
          final compressedFile = await _imageOptimizationService.compressImageFile(image.file!);
          
          if (compressedFile != null) {
            optimizedImages.add(ResidenceImage.fromFile(compressedFile));
            _logger.fine('Image ${i+1} optimisée avec succès');
          } else {
            // En cas d'échec, ajouter l'original
            optimizedImages.add(image);
            _logger.warning('Impossible d\'optimiser l\'image ${i+1}, utilisation de l\'original');
          }
        } else {
          _logger.warning('Image ${i+1}/${images.length}: Format non supporté');
        }
      } catch (e) {
        _logger.severe('Erreur lors de l\'optimisation de l\'image ${i+1}: $e');
        // En cas d'erreur, ajouter l'image originale
        optimizedImages.add(images[i]);
      }
    }
    
    _logger.info('Optimisation terminée: ${optimizedImages.length}/${images.length} images traitées');
    return optimizedImages;
  }

  /// Valide si l'image respecte les critères (taille, format, etc.)
  bool validateImage(ResidenceImage image) {
    // Vérification de base pour la taille et le format
    try {
      // URL externe - considérée comme valide sans vérification
      if (image.url != null && image.url!.startsWith('http')) {
        return true;
      }
      
      // Image web (Uint8List)
      if (image.isWeb && image.webImage != null) {
        // Vérifier la taille maximale (ex: 10MB)
        if (image.webImage!.length > 10 * 1024 * 1024) {
          _logger.warning('Image trop volumineuse: ${image.webImage!.length} octets');
          return false;
        }
        return true;
      }
      
      // Fichier (mobile)
      if (!kIsWeb && image.file != null) {
        final extension = path.extension(image.file!.path).toLowerCase();
        
        // Vérifier l'extension
        if (!['.jpg', '.jpeg', '.png', '.webp', '.gif'].contains(extension)) {
          _logger.warning('Format d\'image non supporté: $extension');
          return false;
        }
        return true;
      }
      
      return false;
    } catch (e) {
      _logger.severe('Erreur lors de la validation de l\'image: $e');
      return false;
    }
  }

  /// Vide le cache d'images
  Future<void> clearImageCache() async {
    try {
      // Vider le cache Flutter
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      
      // Vider le cache de CachedNetworkImage
      CachedNetworkImage.logLevel = CacheManagerLogLevel.none;
      
      _logger.info('Cache d\'images vidé avec succès');
    } catch (e) {
      _logger.warning('Erreur lors de la suppression du cache d\'images: $e');
    }
  }

  /// Précharge une liste d'images pour affichage instantané ultérieur
  Future<void> precacheImages(List<String> imageUrls, BuildContext context) async {
    try {
      for (final url in imageUrls) {
        precacheImage(
          CachedNetworkImageProvider(url),
          context,
        );
      }
      _logger.fine('Préchargement de ${imageUrls.length} images');
    } catch (e) {
      _logger.warning('Erreur lors du préchargement des images: $e');
    }
  }

  /// Obtient un chemin temporaire pour stocker une image
  Future<String> getTemporaryImagePath([String? extension]) async {
    final directory = await getTemporaryDirectory();
    return path.join(directory.path, '${_uuid.v4()}.${extension ?? 'jpg'}');
  }
} 