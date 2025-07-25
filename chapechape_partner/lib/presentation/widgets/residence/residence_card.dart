import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/models/residence/residence.dart';
import '../../../core/models/residence/residence_extensions.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/constants/app_icons.dart';
import 'package:logging/logging.dart';
import '../../../core/config/app_config.dart';

class ResidenceCard extends StatelessWidget {
  static final _logger = Logger('ResidenceCard');
  final Residence residence;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ResidenceCard({
    Key? key,
    required this.residence,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extraire l'URL de l'image de la même manière que dans residences_screen.dart
    String imageUrl = residence.mainImage ?? '';
    if (imageUrl.isEmpty && residence.images.isNotEmpty) {
      if (residence.images.first is String) {
        imageUrl = residence.images.first as String;
      } else if (residence.images.first is Map) {
        final imgMap = residence.images.first as Map;
        imageUrl = imgMap['url'] ?? '';
      }
    }
    
    // Ajouter le domaine si nécessaire
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      // Récupérer l'URL de base
      String baseUrl = AppConfig.apiUrl;
      if (baseUrl.endsWith("/api")) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 4);
      }
      
      // Construire l'URL complète
      if (imageUrl.startsWith('/')) {
        if (imageUrl.startsWith('/uploads/') && !imageUrl.startsWith('/uploads/residences/')) {
          imageUrl = imageUrl.replaceAll('/uploads/', '/uploads/residences/');
        }
        imageUrl = '$baseUrl$imageUrl';
      } else {
        imageUrl = '$baseUrl/uploads/residences/$imageUrl';
      }
    }
    
    // Si c'est une URL complète, ajouter /residences/ si nécessaire
    if (imageUrl.startsWith('http') && imageUrl.contains('/uploads/') && !imageUrl.contains('/uploads/residences/')) {
      imageUrl = imageUrl.replaceAll('/uploads/', '/uploads/residences/');
    }
    
    _logger.info('URL finale de l\'image: $imageUrl');
    
    final bool hasValidImage = imageUrl.isNotEmpty && imageUrl != AppImages.residencePlaceholder;
    
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image avec ombre et transition
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Hero(
                          tag: 'residence_${residence.id}',
                          child: !hasValidImage
                            ? Image.asset(
                                AppImages.residencePlaceholder,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              // Désactiver complètement le cache pour forcer le rechargement
                              cacheHeight: null,
                              cacheWidth: null,
                              // Ajouter des en-têtes pour éviter les problèmes de cache
                              headers: {
                                'Cache-Control': 'no-cache, no-store, must-revalidate',
                                'Pragma': 'no-cache',
                                'Expires': '0',
                                'If-Modified-Since': DateTime.now().toUtc().toString(),
                              },
                              // Ajouter un timestamp à l'URL pour forcer le rechargement
                              key: ValueKey('${imageUrl}_${DateTime.now().millisecondsSinceEpoch}'),
                              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                if (wasSynchronouslyLoaded) return child;
                                return AnimatedOpacity(
                                  opacity: frame == null ? 0 : 1,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                  child: child,
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                _logger.warning('Error loading image: $error\nImage URL was: $imageUrl');
                                return Image.asset(
                                  AppImages.residencePlaceholder,
                                  fit: BoxFit.cover,
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
                      Text(
                        residence.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Adresse
                      Row(
                        children: [
                          SvgPicture.asset(
                            AppIcons.location,
                            height: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              // Utiliser l'adresse formatée en priorité, sinon utiliser l'adresse courte
                              residence.formattedAddress ?? residence.address,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Caractéristiques
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Chambres
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  AppIcons.bedroom,
                                  height: 16,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${residence.bedrooms} ch.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          // Salles de bain
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  AppIcons.bathroom,
                                  height: 16,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${residence.bathrooms} SDB',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          // Surface
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset(
                                  AppIcons.area,
                                  height: 16,
                                  color: Colors.grey[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${residence.surface.toInt()} m²',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Prix et Statut
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Réduire la largeur de la rangée de prix pour laisser plus d'espace au statut
                          Expanded(
                            // Utiliser Expanded au lieu de Flexible pour forcer le Row à prendre tout l'espace disponible
                            flex: 3, // Donner 3/4 de l'espace au prix
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Rendre l'icône "compressible" en cas d'espace très limité
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 16),
                                  child: SvgPicture.asset(
                                    AppIcons.price,
                                    height: 14, // Réduire légèrement la taille
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 2), // Réduire l'espacement
                                Expanded(
                                  // Expanded au lieu de Flexible pour forcer le texte à respecter l'espace disponible
                                  child: Text(
                                    residence.priceDisplay,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12, // Réduire la taille du texte
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4), // Réduire l'espacement
                          // Statut avec taille fixe
                          Expanded(
                            flex: 1, // Donner 1/4 de l'espace au statut
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4, // Réduire le padding
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: residence.isAvailable
                                    ? Colors.green[100]
                                    : Colors.red[100],
                                borderRadius: BorderRadius.circular(8), // Réduire le rayon
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Supprimer l'icône en cas d'espace très limité
                                  if (MediaQuery.of(context).size.width > 320)
                                    SvgPicture.asset(
                                      residence.isAvailable
                                          ? AppIcons.available
                                          : AppIcons.unavailable,
                                      height: 12, // Réduire la taille
                                      color: residence.isAvailable
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                    ),
                                  if (MediaQuery.of(context).size.width > 320)
                                    const SizedBox(width: 2), // Réduire l'espacement
                                  Flexible(
                                    child: Text(
                                      residence.statusText,
                                      style: TextStyle(
                                        color: residence.isAvailable
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                        fontSize: 10, // Réduire la taille du texte
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bouton de suppression avec icône appropriée
          if (onDelete != null)
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                elevation: 4,
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: SvgPicture.asset(
                      AppIcons.delete,
                      height: 20,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
