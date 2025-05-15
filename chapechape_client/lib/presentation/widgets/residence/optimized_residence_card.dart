import 'package:flutter/material.dart';
import 'package:chapechape_client/core/models/residence_model.dart';
import 'package:chapechape_client/core/services/image_optimization_service.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';

/// Widget optimisé pour afficher une carte de résidence
class OptimizedResidenceCard extends StatelessWidget {
  final Residence residence;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool showFavoriteButton;
  final bool isDetailPage;

  const OptimizedResidenceCard({
    Key? key,
    required this.residence,
    this.onTap,
    this.onFavoriteToggle,
    this.showFavoriteButton = true,
    this.isDetailPage = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageOptimizationService = ImageOptimizationService();
    final mediaQuery = MediaQuery.of(context);
    
    // Déterminer la largeur optimale en fonction de la taille de l'écran
    final screenWidth = mediaQuery.size.width;
    final cardWidth = isDetailPage 
        ? screenWidth 
        : (screenWidth > 600 ? 280.0 : screenWidth * 0.85);
    
    // Hauteur proportionnelle à la largeur pour maintenir le ratio
    final imageHeight = cardWidth * 0.6;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image avec badges
              Stack(
                children: [
                  // Image optimisée
                  _buildResidenceImage(
                    imageOptimizationService, 
                    cardWidth, 
                    imageHeight
                  ),
                  
                  // Badge Prix
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, 
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        residence.formattedPrice,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  // Badge réduction (si applicable)
                  if (residence.hasDiscount)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, 
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_offer_outlined,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              residence.discountBadge,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                  // Bouton favoris (si activé)
                  if (showFavoriteButton)
                    Positioned(
                      top: 10,
                      right: residence.hasDiscount ? 80 : 10,
                      child: GestureDetector(
                        onTap: onFavoriteToggle,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            residence.isFavorite 
                                ? Icons.favorite 
                                : Icons.favorite_border,
                            color: residence.isFavorite 
                                ? Colors.red 
                                : Colors.grey,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              
              // Contenu texte
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre avec étoiles
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            residence.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.star, 
                              size: 16, 
                              color: Colors.amber[700],
                            ),
                            const SizedBox(width: 2),
                            Text(
                              residence.rating.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Emplacement
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            residence.formattedAddress,
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Caractéristiques
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFeature(
                          context,
                          Icons.bed_outlined,
                          '${residence.bedrooms} ${residence.bedrooms > 1 ? 'Chambres' : 'Chambre'}',
                        ),
                        _buildFeature(
                          context,
                          Icons.bathtub_outlined,
                          '${residence.bathrooms} ${residence.bathrooms > 1 ? 'SdB' : 'SdB'}',
                        ),
                        _buildFeature(
                          context,
                          Icons.square_foot_outlined,
                          '${residence.squareMeters}m²',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Construit l'image principale de la résidence
  Widget _buildResidenceImage(
    ImageOptimizationService imageService, 
    double width, 
    double height,
  ) {
    // Vérifier si des images sont disponibles
    if (residence.images.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.image_not_supported, size: 48)),
      );
    }
    
    // Utiliser la première image disponible
    final imageUrl = residence.images.first;
    
    // Utiliser le service d'optimisation d'images
    return imageService.buildOptimizedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.error_outline, color: Colors.grey, size: 36),
            SizedBox(height: 8),
            Text('Image non disponible'),
          ],
        ),
      ),
    );
  }
  
  /// Construit un indicateur de caractéristique
  Widget _buildFeature(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
