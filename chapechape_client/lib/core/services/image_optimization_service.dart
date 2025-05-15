import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

/// Service pour optimiser et gérer les images des résidences
class ImageOptimizationService {
  static const String _cacheKey = 'residence_images_cache';
  static final ImageOptimizationService _instance = ImageOptimizationService._internal();
  
  late final BaseCacheManager _cacheManager;
  
  // État de la connexion (mis à jour par ConnectionQualityService)
  bool _isSlowConnection = false;
  bool _isOffline = false;
  
  /// Singleton instance
  factory ImageOptimizationService() => _instance;
  
  /// Constructeur privé
  ImageOptimizationService._internal() {
    _cacheManager = CacheManager(
      Config(
        _cacheKey,
        stalePeriod: const Duration(days: 14), // Augmenté à 14 jours pour un meilleur support hors ligne
        maxNrOfCacheObjects: 200, // Augmenté pour stocker plus d'images en cache
        repo: JsonCacheInfoRepository(databaseName: _cacheKey),
        fileService: HttpFileService(),
      ),
    );
  }
  
  /// Met à jour l'état de la connexion
  void updateConnectionStatus({bool isSlowConnection = false, bool isOffline = false}) {
    _isSlowConnection = isSlowConnection;
    _isOffline = isOffline;
    debugPrint('🌐 État de connexion mis à jour: lent=$_isSlowConnection, hors ligne=$_isOffline');
  }
  
  /// Précharge une liste d'images pour une résidence avec différentes résolutions
  Future<void> preloadResidenceImages(List<String> imageUrls) async {
    if (imageUrls.isEmpty) return;
    
    // Limite le nombre d'images préchargées pour économiser de la bande passante
    final imagesToPreload = imageUrls.length > 3 ? imageUrls.sublist(0, 3) : imageUrls;
    
    // Si connexion lente, ne précharger que des versions basse résolution
    if (_isSlowConnection) {
      await Future.wait(
        imagesToPreload.map((url) async {
          final optimizedUrl = await getOptimizedImageUrl(url, width: 300, quality: 60);
          return _cacheManager.getSingleFile(optimizedUrl);
        }).toList(),
      );
      debugPrint('🖼️ ${imagesToPreload.length} images préchargées en basse résolution (connexion lente)');
    } else {
      // Sinon, précharger des versions standard
      await Future.wait(
        imagesToPreload.map((url) async {
          final optimizedUrl = await getOptimizedImageUrl(url);
          return _cacheManager.getSingleFile(optimizedUrl);
        }).toList(),
      );
      debugPrint('🖼️ ${imagesToPreload.length} images préchargées en résolution standard');
    }
  }
  
  /// Récupère une image optimisée avec des paramètres de redimensionnement adaptés à la qualité de connexion
  Future<String> getOptimizedImageUrl(String originalUrl, {int? width, int? quality}) async {
    // Si l'URL est déjà une URL d'image optimisée, la retourner telle quelle
    if (originalUrl.contains('?width=') || originalUrl.contains('&quality=')) {
      return originalUrl;
    }
    
    // Adapter la qualité et la largeur en fonction de l'état de la connexion
    int finalWidth = width ?? (_isSlowConnection ? 400 : 600);
    int finalQuality = quality ?? (_isSlowConnection ? 60 : 80);
    
    // Ajouter les paramètres d'optimisation à l'URL
    final separator = originalUrl.contains('?') ? '&' : '?';
    final optimizedUrl = '$originalUrl${separator}width=$finalWidth&quality=$finalQuality';
    
    return optimizedUrl;
  }
  
  /// Supprime le cache des images
  Future<void> clearImageCache() async {
    await _cacheManager.emptyCache();
    debugPrint('🖼️ Cache d\'images vidé');
  }
  
  /// Obtient la taille du cache des images
  Future<String> getImageCacheSize() async {
    final directory = await getTemporaryDirectory();
    final cacheDir = Directory('${directory.path}/$_cacheKey');
    
    if (!await cacheDir.exists()) {
      return '0 Mo';
    }
    
    int totalSize = 0;
    await for (final file in cacheDir.list(recursive: true, followLinks: false)) {
      if (file is File) {
        totalSize += await file.length();
      }
    }
    
    // Convertir en Mo
    final sizeInMb = totalSize / (1024 * 1024);
    return '${sizeInMb.toStringAsFixed(2)} Mo';
  }
  
  /// Construit un widget d'image optimisé pour les résidences avec chargement progressif
  Widget buildOptimizedImage({
    required String imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    // Déterminer si nous devons utiliser une version basse résolution pour le chargement progressif
    final shouldUseProgressiveLoading = !_isOffline && imageUrl.length > 0;
  
    // Utiliser CachedNetworkImage pour la mise en cache automatique
    if (shouldUseProgressiveLoading) {
      return ProgressiveImage(
        placeholder: NetworkImage(imageUrl + '?width=100&quality=40'), // Thumbnail de très faible qualité
        thumbnail: NetworkImage(imageUrl + '?width=300&quality=60'), // Version intermédiaire
        image: CachedNetworkImageProvider(
          _isSlowConnection 
              ? imageUrl + '?width=400&quality=60' // Version pour connexion lente
              : imageUrl,                          // Version complète
          cacheManager: _cacheManager,
        ),
        width: width,
        height: height,
        fit: fit,
        fadeOutDuration: const Duration(milliseconds: 300),
        fadeInDuration: const Duration(milliseconds: 300),
      );
    } else {
      // Fallback sur CachedNetworkImage standard pour le mode hors ligne
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => placeholder ?? 
            Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        errorWidget: (context, url, error) => errorWidget ?? 
            Container(
              color: Colors.grey[300],
              child: const Icon(Icons.error_outline, color: Colors.red),
            ),
        cacheManager: _cacheManager,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
      );
    }
  }
  
  /// Détermine si une URL d'image est valide
  Future<bool> isImageUrlValid(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('🖼️ Erreur lors de la validation de l\'URL d\'image: $e');
      return false;
    }
  }
  
  /// Nettoie les images anciennes et inutilisées du cache
  Future<void> cleanupUnusedImages() async {
    try {
      await _cacheManager.emptyCache();
      debugPrint('🧹 Nettoyage des images inutilisées terminé');
    } catch (e) {
      debugPrint('❌ Erreur lors du nettoyage des images inutilisées: $e');
    }
  }
}

/// Widget pour afficher des images avec chargement progressif
class ProgressiveImage extends StatelessWidget {
  final ImageProvider placeholder;
  final ImageProvider thumbnail;
  final ImageProvider image;
  final double width;
  final double height;
  final BoxFit fit;
  final Duration fadeOutDuration;
  final Duration fadeInDuration;

  const ProgressiveImage({
    Key? key,
    required this.placeholder,
    required this.thumbnail,
    required this.image,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.fadeOutDuration = const Duration(milliseconds: 300),
    this.fadeInDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image(
      image: image,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }
        return AnimatedSwitcher(
          duration: fadeInDuration,
          child: frame != null
              ? child
              : Image(
                  image: thumbnail,
                  width: width,
                  height: height,
                  fit: fit,
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    return AnimatedSwitcher(
                      duration: fadeOutDuration,
                      child: frame != null
                          ? child
                          : Image(
                              image: placeholder,
                              width: width,
                              height: height,
                              fit: fit,
                            ),
                    );
                  },
                ),
        );
      },
    );
  }
}
