import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_theme.dart';
import 'residence_amenities.dart';

class PersonalizedSuggestionsWidget extends StatelessWidget {
  const PersonalizedSuggestionsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Suggestions personnalisées',
            style: AppTheme.headingLarge,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 400,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildSuggestionCard(
                title: 'Villa de luxe avec piscine',
                location: 'Cocody, Abidjan',
                price: '250,000',
                image: ResidenceImages.luxury[0],
                amenities: [
                  Amenity.pool,
                  Amenity.wifi,
                  Amenity.ac,
                  Amenity.security,
                  Amenity.parking,
                ],
                rating: 4.8,
                reviews: 24,
              ),
              _buildSuggestionCard(
                title: 'Appartement moderne',
                location: 'Plateau, Abidjan',
                price: '150,000',
                image: ResidenceImages.apartments[0],
                amenities: [
                  Amenity.wifi,
                  Amenity.ac,
                  Amenity.furnished,
                  Amenity.elevator,
                ],
                rating: 4.5,
                reviews: 18,
              ),
              _buildSuggestionCard(
                title: 'Studio meublé',
                location: 'Marcory, Abidjan',
                price: '80,000',
                image: ResidenceImages.studios[0],
                amenities: [
                  Amenity.wifi,
                  Amenity.ac,
                  Amenity.furnished,
                ],
                rating: 4.2,
                reviews: 15,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard({
    required String title,
    required String location,
    required String price,
    required String image,
    required List<Amenity> amenities,
    required double rating,
    required int reviews,
  }) {
    return Container(
      width: 300,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.asset(
                    image,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$price FCFA/mois',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.headingMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: AppTheme.primaryGold),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ResidenceAmenities(amenities: amenities),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.star, size: 20, color: AppTheme.primaryGold),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '($reviews avis)',
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
