import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/rendering.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/services/media/media_service.dart';
import '../../../core/services/media/cloudinary_service.dart';
import '../../../core/config/feature_flags.dart';

/// Widget optimisé pour le chargement d'images avec cache
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final Duration cacheDuration;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  
  /// Qualité de l'image (1-100), uniquement utilisé avec Cloudinary
  final int quality;
  
  /// Indique si l'image doit être optimisée pour les connexions lentes
  final bool optimizeForLowBandwidth;
  
  /// Widget pour l'affichage optimisé d'images avec cache et gestion d'erreurs
  /// 
  /// [imageUrl] URL de l'image à afficher
  /// [width] Largeur optionnelle de l'image
  /// [height] Hauteur optionnelle de l'image
  /// [fit] Mode d'ajustement de l'image (par défaut: BoxFit.cover)
  /// [errorWidget] Widget à afficher en cas d'erreur
  /// [loadingWidget] Widget à afficher pendant le chargement
  /// [cacheDuration] Durée de mise en cache (par défaut: 30 jours)
  /// [borderRadius] Rayon de bordure optionnel
  /// [backgroundColor] Couleur de fond optionnelle
  const OptimizedImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.loadingWidget,
    this.cacheDuration = const Duration(days: 30),
    this.borderRadius,
    this.backgroundColor,
    this.quality = 80,
    this.optimizeForLowBandwidth = false,
  }) : super(key: key);
  
  /// Précharge une image pour un affichage instantané
  static Future<void> precacheImage(String url, BuildContext context) async {
    if (url.isNotEmpty) {
      await MediaService().precacheImages([url], context);
    }
  }
  
  /// Efface une image spécifique du cache
  static Future<void> clearImageFromCache(String url) async {
    try {
      // Effacer l'image des caches
      final cacheKey = Uri.parse(url).pathSegments.last;
      await CachedNetworkImage.evictFromCache(url);
    } catch (e) {
      debugPrint('Erreur lors de la suppression de l\'image du cache: $e');
    }
  }

  /// Déterminer si nous sommes sur une connexion lente/économe en données
  Future<bool> _isLowBandwidthConnection() async {
    if (!FeatureFlags.adaptiveImageQuality) return false;
    if (optimizeForLowBandwidth) return true;
    
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult == ConnectivityResult.mobile && FeatureFlags.dataSavingMode;
    } catch (e) {
      debugPrint('Erreur détection connectivité: $e');
      return false;
    }
  }
  
  /// Optimise l'URL de l'image selon les paramètres et la connectivité
  Future<String> _getOptimizedUrl(String url) async {
    // Si Cloudinary n'est pas activé, retourner l'URL avec un cache buster
    if (!FeatureFlags.useCloudinary || !url.contains('cloudinary.com')) {
      return url.contains('?') 
        ? '$url&cache=${DateTime.now().millisecondsSinceEpoch}' 
        : '$url?cache=${DateTime.now().millisecondsSinceEpoch}';
    }
    
    // Déterminer si nous sommes sur une connexion lente
    final isLowBandwidth = await _isLowBandwidthConnection();
    
    // Utiliser CloudinaryService pour optimiser l'URL
    final cloudinaryService = CloudinaryService();
    return cloudinaryService.getOptimizedUrl(
      url,
      width: width?.toInt(),
      height: height?.toInt(),
      quality: isLowBandwidth ? 40 : quality, // Réduire la qualité si connexion lente
      isLowBandwidth: isLowBandwidth,
      progressive: true, // Toujours utiliser le chargement progressif
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug: afficher l'URL
    debugPrint('OptimizedImage: URL reçue = $imageUrl');
    
    if (imageUrl.isEmpty) {
      debugPrint('OptimizedImage: URL vide, affichage de l\'image par défaut');
      return _buildEmptyImage();
    }
    
    return FutureBuilder<String>(
      future: _getOptimizedUrl(imageUrl),
      builder: (context, snapshot) {
        final String urlToUse = snapshot.data ?? imageUrl;
        
        debugPrint('OptimizedImage: URL optimisée = $urlToUse');
        
        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: CachedNetworkImage(
            imageUrl: urlToUse,
            width: width,
            height: height,
            fit: fit,
            fadeInDuration: const Duration(milliseconds: 300),
            fadeOutDuration: const Duration(milliseconds: 300),
            placeholderFadeInDuration: const Duration(milliseconds: 300),
            memCacheWidth: width?.toInt(),
            memCacheHeight: height?.toInt(),
            // Utiliser le cache disque selon les feature flags
            maxHeightDiskCache: FeatureFlags.aggressiveImageCaching ? 2048 : 0,
            maxWidthDiskCache: FeatureFlags.aggressiveImageCaching ? 2048 : 0,
            // Cache manager
            cacheManager: FeatureFlags.aggressiveImageCaching ? null : null,
            useOldImageOnUrlChange: false,
            placeholder: (context, url) => _buildLoadingWidget(),
            errorWidget: (context, url, error) {
              debugPrint('OptimizedImage: ERREUR chargement de $url - Erreur: $error');
              return _buildErrorWidget();
            },
            // Garder les en-têtes de cache seulement si nous n'utilisons pas Cloudinary
            httpHeaders: FeatureFlags.useCloudinary ? {} : {
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              'Pragma': 'no-cache',
              'Expires': '0',
              'If-Modified-Since': DateTime.now().toUtc().toString(),
            },
          ),
        );
      },
    );
  }
  
  /// Construit le widget à afficher pendant le chargement
  Widget _buildLoadingWidget() {
    if (loadingWidget != null) return loadingWidget!;
    
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.grey.shade200,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
          ),
        ),
      ),
    );
  }
  
  /// Construit le widget à afficher en cas d'erreur
  Widget _buildErrorWidget() {
    if (errorWidget != null) return errorWidget!;
    
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey.shade400,
          size: 24,
        ),
      ),
    );
  }
  
  /// Construit le widget à afficher si l'URL est vide
  Widget _buildEmptyImage() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey.shade400,
          size: 24,
        ),
      ),
    );
  }
} 