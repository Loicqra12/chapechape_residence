import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:chapechape_client/core/services/logger_service.dart';
import 'package:chapechape_client/core/config/feature_flags.dart';
import 'package:chapechape_client/core/services/media/cloudinary_service.dart';

/// Classe 
///  l'état de la connexion
class ConnectionStatus {
  final bool isSlowConnection;
  final bool isOffline;
  
  ConnectionStatus({required this.isSlowConnection, required this.isOffline});
}

/// Service pour optimiser et gérer les images des résidences
class ImageOptimizationService {
  static const String _cacheKey = 'residence_images_cache';
  static final ImageOptimizationService _instance = ImageOptimizationService._internal();
  
  late final BaseCacheManager _cacheManager;
  final LoggerService _logger = LoggerService();
  
  // Paramètres de gestion du cache
  static const int _maxCacheSize = 200 * 1024 * 1024; // 200 MB maximum
  static const double _minDiskSpaceRequired = 500; // 500 MB d'espace libre minimum
  static const int _defaultMaxCacheObjects = 200;
  static const int _maxPreloadImages = 5; // Nombre maximum d'images à précharger
  
  // Drapeau pour savoir si le cache a été initialisé
  bool _isInitialized = false;
  
  // Gestion des événements de changement de connexion
  final StreamController<ConnectionStatus> _connectionStatusController = 
      StreamController<ConnectionStatus>.broadcast();
  Stream<ConnectionStatus> get connectionStatusStream => _connectionStatusController.stream;
  
  // État de la connexion (mis à jour par ConnectionQualityService)
  bool _isSlowConnection = false;
  bool _isOffline = false;
  
  /// Singleton instance
  factory ImageOptimizationService() => _instance;
  
  /// Constructeur privé
  ImageOptimizationService._internal() {
    _initializeCacheManager();
  }
  
  /// Initialise le gestionnaire de cache avec les paramètres appropriés
  Future<void> _initializeCacheManager() async {
    try {
      // Vérifier l'espace disque disponible
      final availableDiskSpace = await _getAvailableDiskSpace();
      
      // Ajuster le nombre d'objets en cache en fonction de l'espace disponible
      int maxObjects = _defaultMaxCacheObjects;
      if (availableDiskSpace < _minDiskSpaceRequired) {
        // Réduire la taille du cache si l'espace est limité
        _logger.warning('💾 Espace disque limité (${availableDiskSpace.toStringAsFixed(2)} MB), réduction du cache d\'images');
        maxObjects = _defaultMaxCacheObjects ~/ 2; // Réduire de moitié
      }
      
      _cacheManager = CacheManager(
        Config(
          _cacheKey,
          stalePeriod: const Duration(days: 14), // Support hors ligne étendu
          maxNrOfCacheObjects: maxObjects,
          repo: JsonCacheInfoRepository(databaseName: _cacheKey),
          fileService: HttpFileService(),
        ),
      );
      
      _logger.info('💾 Gestionnaire de cache d\'images initialisé avec $maxObjects objets maximum');
      
      // Nettoyer le cache si nécessaire lors de l'initialisation
      _performCacheMaintenanceIfNeeded();
      
      // Marquer comme initialisé
      _isInitialized = true;
    } catch (e) {
      _logger.error('❌ Erreur lors de l\'initialisation du gestionnaire de cache', e, StackTrace.current);
      
      // Fallback sur une configuration par défaut en cas d'erreur
      _cacheManager = CacheManager(
        Config(
          _cacheKey,
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 100,
          repo: JsonCacheInfoRepository(databaseName: _cacheKey),
          fileService: HttpFileService(),
        ),
      );
    }
  }
  
  /// Met à jour l'état de la connexion et notifie les observateurs
  void updateConnectionStatus({bool isSlowConnection = false, bool isOffline = false}) {
    // Ne mettre à jour que si l'état a changé
    if (_isSlowConnection != isSlowConnection || _isOffline != isOffline) {
      _isSlowConnection = isSlowConnection;
      _isOffline = isOffline;
      
      // Notifier les observateurs du changement
      _connectionStatusController.add(ConnectionStatus(
        isSlowConnection: _isSlowConnection,
        isOffline: _isOffline,
      ));
      
      _logger.info('🌍 État de connexion mis à jour: lent=$_isSlowConnection, hors ligne=$_isOffline');
      
      // Si la connexion s'améliore, précharger les images importantes
      if (!_isOffline && !_isSlowConnection) {
        _preloadCriticalImages();
      }
    }
  }
  
  /// Précharge les images critiques lorsque la connexion s'améliore
  Future<void> _preloadCriticalImages() async {
    // Implémentation à compléter selon les besoins de l'application
    // Par exemple, précharger les images de la page d'accueil
  }
  
  /// Précharge une liste d'images pour une résidence avec différentes résolutions
  Future<void> preloadResidenceImages(List<String> imageUrls) async {
    if (imageUrls.isEmpty) return;
    
    _logger.info('📸 Préchargement de ${imageUrls.length} images de résidence');

    try {
      // Vérifier l'espace disque disponible avant le préchargement
      final hasEnoughSpace = await _hasEnoughDiskSpace();
      if (!hasEnoughSpace) {
        _logger.warning('⚠️ Espace disque insuffisant pour le préchargement d\'images, nettoyage du cache...');
        await cleanupUnusedImages();
        
        // Revérifier l'espace après le nettoyage
        final spaceAfterCleanup = await _hasEnoughDiskSpace();
        if (!spaceAfterCleanup) {
          _logger.error('❌ Espace disque toujours insuffisant après nettoyage, abandon du préchargement');
          return;
        }
      }

      // Adapter la stratégie de préchargement en fonction de la connexion
      // Limiter le nombre d'images à précharger
      final limitedUrls = imageUrls.take(_maxPreloadImages).toList();
      
      // Si la connexion est lente, nous préchargeons uniquement des images de basse qualité
      if (_isSlowConnection) {
        _logger.info('📡 Connexion lente détectée, préchargement d\'images basse résolution');
        for (final url in limitedUrls) {
          if (url.isEmpty || !isImageUrlValid(url)) continue;
          final optimizedUrl = getOptimizedImageUrl(url, width: 100, quality: 30);
          await _cacheManager.getSingleFile(optimizedUrl);
        }
      } else if (_isOffline) {
        // En mode hors ligne, nous ne préchargeons rien de nouveau
        _logger.info('📰 Mode hors ligne, aucun préchargement d\'images');
        return;
      } else {
        // Pour une connexion normale, nous préchargeons des images de résolution moyenne
        for (final url in limitedUrls) {
          if (url.isEmpty || !isImageUrlValid(url)) continue;
          final optimizedUrl = getOptimizedImageUrl(url, width: 300);
          await _cacheManager.getSingleFile(optimizedUrl);
        }
        
        // Et la première image est préchargée en haute qualité (pour l'affichage détaillé)
        if (limitedUrls.isNotEmpty) {
          final firstUrl = limitedUrls.first;
          if (firstUrl.isNotEmpty && isImageUrlValid(firstUrl)) {
            final optimizedUrl = getOptimizedImageUrl(firstUrl, width: 600);
            await _cacheManager.getSingleFile(optimizedUrl);
          }
        }

        // Effectuer une maintenance du cache après le préchargement si nécessaire
        _performCacheMaintenanceIfNeeded();
      }
      
      _logger.info('✅ Préchargement des images terminé');
    } catch (e) {
      _logger.error('🖼️ Erreur lors du préchargement des images', e, StackTrace.current);
    }
  }
  
  /// Récupère une image optimisée avec des paramètres de redimensionnement adaptés à la qualité de connexion
  /// Supporte les URLs Cloudinary pour une optimisation avancée
  String getOptimizedImageUrl(String originalUrl, {int? width, int? quality}) {
    // Vérifier si l'URL est valide
    if (!isImageUrlValid(originalUrl)) return originalUrl;
    
    // Déterminer la qualité en fonction de la connexion
    final adaptiveQuality = _isSlowConnection 
      ? 50  // Basse qualité pour les connexions lentes
      : 85; // Haute qualité pour les connexions rapides
    
    final finalQuality = quality ?? adaptiveQuality;
    
    // Si Cloudinary est activé et que c'est une URL Cloudinary
    if (FeatureFlags.useCloudinary && originalUrl.contains('cloudinary.com')) {
      try {
        // Utiliser CloudinaryService pour les transformations
        final cloudinaryService = CloudinaryService();
        return cloudinaryService.getOptimizedUrl(
          originalUrl,
          width: width,
          quality: finalQuality,
        );
      } catch (e) {
        _logger.error('Erreur lors de l\'optimisation Cloudinary', e);
        // En cas d'erreur, retourner l'URL originale
        return originalUrl;
      }
    }
    
    // Pour les autres URLs, retourner l'URL originale pour l'instant
    // car la manipulation d'URL dépend du CDN
    return originalUrl;
  }
  
  /// Supprime le cache des images
  Future<void> clearImageCache() async {
    try {
      await _cacheManager.emptyCache();
      _logger.info('🖼️ Cache d\'images vidé avec succès');
    } catch (e) {
      _logger.error('🖼️ Erreur lors du vidage du cache d\'images', e, StackTrace.current);
    }
  }
  
  /// Obtient la taille du cache des images en octets
  Future<int> getImageCacheSize() async {
    try {
      if (!_isInitialized) return 0;
      if (kIsWeb) return 0; // Pas de cache sur le web
      
      final tempDir = await getTemporaryDirectory();
      final cachePath = '${tempDir.path}/$_cacheKey';
      final cacheDir = Directory(cachePath);
      
      if (!await cacheDir.exists()) return 0;
      
      int totalSize = 0;
      await for (final file in cacheDir.list(recursive: true, followLinks: false)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      
      // Log la taille en Mo pour information, mais retourne la taille en octets
      final sizeInMb = totalSize / (1024 * 1024);
      _logger.info('🖼️ Taille actuelle du cache d\'images: ${sizeInMb.toStringAsFixed(2)} Mo');
      return totalSize;
    } catch (e) {
      _logger.error('🖼️ Erreur lors de la récupération de la taille du cache', e, StackTrace.current);
      return 0;
    }
  }
  
  /// Formate la taille du cache en texte lisible
  Future<String> getFormattedCacheSize() async {
    final size = await getImageCacheSize();
    return '${size.toStringAsFixed(2)} Mo';
  }
  
  /// Construit un widget d'image optimisé pour les résidences avec chargement progressif
  /// Supporte les images Cloudinary pour des optimisations avancées
  Widget buildOptimizedImage({
    required String imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    // Vérifier si l'URL est valide
    if (!isImageUrlValid(imageUrl)) {
      return errorWidget ?? Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
    
    // Détecter si c'est une URL Cloudinary
    final bool isCloudinaryUrl = imageUrl.contains('cloudinary.com');
    
    // Placeholder par défaut si non fourni
    final defaultPlaceholder = Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
    
    // Widget d'erreur par défaut si non fourni
    final defaultErrorWidget = Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.grey),
          SizedBox(height: 4),
          Text(
            'Image indisponible',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    
    // Si c'est une URL Cloudinary et que le feature flag est activé,
    // utiliser une stratégie avancée de chargement progressif
    if (FeatureFlags.useCloudinary && isCloudinaryUrl) {
      final CloudinaryService cloudinaryService = CloudinaryService();
      
      // URL optimisée complète avec Cloudinary
      final optimizedUrl = cloudinaryService.getOptimizedUrl(
        imageUrl,
        width: width.toInt(),
        quality: _isSlowConnection ? 60 : 85,
      );
      
      // URL basse qualité pour le chargement ultra-rapide
      final lowQualityUrl = cloudinaryService.getOptimizedUrl(
        imageUrl,
        width: (width / 4).toInt(), // Très basse résolution
        quality: 20, // Très basse qualité
      );
      
      // Utiliser CachedNetworkImage avec une stratégie de placeholder progressif
      return CachedNetworkImage(
        imageUrl: optimizedUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) {
          if (placeholder != null) return placeholder;
          
          // Utiliser une image basse qualité comme placeholder
          return CachedNetworkImage(
            imageUrl: lowQualityUrl,
            width: width,
            height: height,
            fit: fit,
            placeholder: (_, __) => defaultPlaceholder,
            errorWidget: (_, __, ___) => defaultPlaceholder,
          );
        },
        errorWidget: (context, url, error) => errorWidget ?? defaultErrorWidget,
        memCacheWidth: (width * 1.2).toInt(),
        fadeInDuration: const Duration(milliseconds: 300),
      );
    }
    
    // Pour les images non-Cloudinary, utiliser l'approche standard
    return CachedNetworkImage(
      imageUrl: getOptimizedImageUrl(imageUrl, width: width.toInt()),
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? defaultPlaceholder,
      errorWidget: (context, url, error) => errorWidget ?? defaultErrorWidget,
      memCacheWidth: (width * 1.2).toInt(), // Cache légèrement plus grand pour les zooms
      fadeInDuration: const Duration(milliseconds: 300),
      cacheManager: _cacheManager,
    );
  }
  
  /// Détermine si une URL d'image est valide (vérification simple sans appel réseau)
  bool isImageUrlValid(String url) {
    try {
      // Vérification simple et rapide, sans appel réseau
      final uri = Uri.parse(url);
      return uri.isAbsolute && 
             (url.toLowerCase().endsWith('.jpg') ||
              url.toLowerCase().endsWith('.jpeg') ||
              url.toLowerCase().endsWith('.png') ||
              url.toLowerCase().endsWith('.webp') ||
              url.toLowerCase().endsWith('.gif') ||
              url.contains('image'));
    } catch (e) {
      _logger.error('🖼️ URL d\'image invalide: $url', e, StackTrace.current);
      return false;
    }
  }
  
  /// Vérifie de manière approfondie si une URL d'image est valide (avec appel réseau)
  Future<bool> isImageUrlValidWithNetworkCheck(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      _logger.error('🖼️ URL d\'image invalide: $url', e, StackTrace.current);
      return false;
    }
  }
  
  /// Nettoie les images anciennes et inutilisées du cache avec une stratégie intelligente
  Future<void> cleanupUnusedImages() async {
    try {
      final cacheSize = await getImageCacheSize();
      final availableSpace = await _getAvailableDiskSpace();
      
      // Ne nettoyer que si le cache est trop grand ou l'espace disque est limité
      if (cacheSize > _maxCacheSize / 2 || availableSpace < _minDiskSpaceRequired) {
        _logger.info('🧹 Nettoyage intelligent du cache d\'images (taille actuelle: ${cacheSize.toStringAsFixed(2)} Mo)');
        
        // Utiliser la stratégie LRU (Least Recently Used) du CacheManager
        // Garder seulement la moitié des objets en cas de problème d'espace
        if (availableSpace < _minDiskSpaceRequired) {
          // Nettoyage agressif si l'espace est très limité
          await _cacheManager.emptyCache();
          _logger.warning('🧹 Nettoyage complet du cache d\'images en raison d\'un espace disque limité');
        } else {
          // Supprime les fichiers les plus anciens (au moins 1/3 du cache)
          await _cleanupOldestFiles();
          _logger.info('🧹 Suppression sélective des images les moins récemment utilisées');
        }
        
        // Vérifier la nouvelle taille du cache
        final newSize = await getImageCacheSize();
        _logger.info('🧹 Nettoyage terminé, nouvelle taille: ${newSize.toStringAsFixed(2)} Mo');
      } else {
        _logger.info('✅ Aucun nettoyage du cache d\'images nécessaire (taille: ${cacheSize.toStringAsFixed(2)} Mo)');
      }
    } catch (e) {
      _logger.error('❌ Erreur lors du nettoyage des images inutilisées', e, StackTrace.current);
    }
  }
  
  /// Vérifie régulièrement l'état du cache et effectue une maintenance si nécessaire
  Future<void> _performCacheMaintenanceIfNeeded() async {
    try {
      if (!_isInitialized) return; // Éviter les appels avant initialisation complète
      
      final cacheSize = await getImageCacheSize();
      final availableSpace = await _getAvailableDiskSpace();
      
      // Vérifier si le cache est trop grand ou si l'espace disque est limité
      if (cacheSize > (_maxCacheSize ~/ 2) || availableSpace < _minDiskSpaceRequired) {
        await cleanupUnusedImages();
      }
    } catch (e) {
      _logger.error('❌ Erreur lors de la maintenance du cache', e, StackTrace.current);
    }
  }
  
  /// Récupère l'espace disque disponible en Mo
  Future<double> _getAvailableDiskSpace() async {
    try {
      if (kIsWeb) return double.infinity; // Pas de limite sur le web
      
      // Méthode simple pour estimer l'espace disponible
      final directory = await getTemporaryDirectory();
      final stat = directory.statSync();
      
      // Si nous ne pouvons pas accéder aux statistiques, nous supposons un espace suffisant
      if (stat.type == FileSystemEntityType.notFound) {
        return _minDiskSpaceRequired * 2;
      }
      
      // Créer un fichier test pour vérifier si nous pouvons écrire
      try {
        final testFile = File('${directory.path}/disk_space_test.tmp');
        await testFile.writeAsString('test');
        await testFile.delete();
        
        // Si nous pouvons écrire, nous supposons un espace suffisant
        return _minDiskSpaceRequired * 2;
      } catch (e) {
        // Si nous ne pouvons pas écrire, nous supposons un espace insuffisant
        return _minDiskSpaceRequired / 2;
      }
    } catch (e) {
      _logger.error('💾 Erreur lors de la vérification de l\'espace disque', e, StackTrace.current);
      return _minDiskSpaceRequired; // Valeur par défaut en cas d'erreur
    }
  }
  
  /// Vérifie s'il y a assez d'espace disque disponible pour les opérations de cache
  Future<bool> _hasEnoughDiskSpace() async {
    final availableSpace = await _getAvailableDiskSpace();
    return availableSpace >= _minDiskSpaceRequired;
  }
  
  /// Supprime les fichiers les plus anciens du cache
  Future<void> _cleanupOldestFiles() async {
    try {
      // Récupérer le répertoire du cache
      final directory = await getTemporaryDirectory();
      final cacheDir = Directory('${directory.path}/$_cacheKey');
      
      if (!await cacheDir.exists()) return;
      
      // Liste tous les fichiers de cache et trie-les par date de modification
      final files = await cacheDir
          .list(recursive: true, followLinks: false)
          .where((entity) => entity is File)
          .cast<File>()
          .toList();
          
      // Trier les fichiers par date de modification (du plus ancien au plus récent)
      files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
      
      // Nombre de fichiers à supprimer (environ 1/3 des fichiers)
      final filesToDeleteCount = (files.length / 3).round();
      if (filesToDeleteCount <= 0) return;
      
      _logger.info('🧹 Suppression de $filesToDeleteCount fichiers les plus anciens');
      
      // Supprimer les fichiers les plus anciens
      for (int i = 0; i < filesToDeleteCount && i < files.length; i++) {
        await files[i].delete();
      }
    } catch (e) {
      _logger.error('❌ Erreur lors de la suppression des fichiers les plus anciens', e, StackTrace.current);
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
