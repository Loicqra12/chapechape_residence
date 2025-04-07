import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/rendering.dart';
import '../../../core/services/media/media_service.dart';

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

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildEmptyImage();
    }
    
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 300),
        placeholderFadeInDuration: const Duration(milliseconds: 300),
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
        placeholder: (context, url) => _buildLoadingWidget(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
      ),
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