// lib/presentation/widgets/card_widget.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/residence_model_alias.dart';
import '../../core/models/residence_model.dart';
import '../../core/models/amenity.dart' as amenity;
import 'residence_amenities.dart';
import 'animated_favorite_button.dart';

// Renommé pour éviter les conflits avec l'autre widget ResidenceCard
class StandardResidenceCard extends StatelessWidget {
  final ResidenceModel residence;
  final VoidCallback? onTap;
  final VoidCallback? onFavoritePressed;

  const StandardResidenceCard({
    super.key,
    required this.residence,
    this.onTap,
    this.onFavoritePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: residence.imageUrl.startsWith('assets/')
                      ? Image.asset(
                          residence.imageUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : CachedNetworkImage(
                          imageUrl: residence.imageUrl,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: theme.disabledColor.withOpacity(0.1),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: theme.disabledColor.withOpacity(0.1),
                            child: const Icon(Icons.error),
                          ),
                        ),
                ),
                if (onFavoritePressed != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: AnimatedFavoriteButton(
                      isFavorite: residence.isFavorite,
                      onPressed: onFavoritePressed!,
                      size: 20,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    residence.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: theme.hintColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          residence.location.displayAddress,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${residence.price.toStringAsFixed(0)} FCFA',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (residence.rating > 0)
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              residence.rating.toStringAsFixed(1),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (residence.amenities.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ResidenceAmenities(
                      amenities: residence.amenities
                          .map((amenityName) => amenity.Amenity.getAllAmenities()
                              .firstWhere(
                                (a) => a.name.toLowerCase() == amenityName.toLowerCase(),
                                orElse: () => amenity.Amenity.getAllAmenities().first,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}