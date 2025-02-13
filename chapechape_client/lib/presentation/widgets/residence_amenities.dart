import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import 'svg_icon.dart';

class ResidenceAmenities extends StatelessWidget {
  final List<Amenity> amenities;

  const ResidenceAmenities({
    Key? key,
    required this.amenities,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: amenities.map((amenity) {
        return Tooltip(
          message: _getAmenityLabel(amenity),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AmenityIcon(
              amenityName: _getAmenityIconName(amenity),
              size: 24,
              color: const Color(0xFFD4AF37),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getAmenityLabel(Amenity amenity) {
    switch (amenity) {
      case Amenity.wifi:
        return 'Wi-Fi';
      case Amenity.ac:
        return 'Climatisation';
      case Amenity.parking:
        return 'Parking';
      case Amenity.pool:
        return 'Piscine';
      case Amenity.gym:
        return 'Salle de sport';
      case Amenity.security:
        return 'Sécurité 24/7';
      case Amenity.elevator:
        return 'Ascenseur';
      case Amenity.garden:
        return 'Jardin';
      case Amenity.balcony:
        return 'Balcon';
      case Amenity.furnished:
        return 'Meublé';
    }
  }

  String _getAmenityIconName(Amenity amenity) {
    switch (amenity) {
      case Amenity.wifi:
        return 'wifi';
      case Amenity.ac:
        return 'climatisation';
      case Amenity.parking:
        return 'parking';
      case Amenity.pool:
        return 'pool';
      case Amenity.gym:
        return 'gym';
      case Amenity.security:
        return 'security';
      case Amenity.elevator:
        return 'elevator';
      case Amenity.garden:
        return 'garden';
      case Amenity.balcony:
        return 'balcony';
      case Amenity.furnished:
        return 'furnished';
    }
  }
}

// Exemple d'utilisation :
class ResidenceCard extends StatelessWidget {
  final String title;
  final String image;
  final List<Amenity> amenities;
  final VoidCallback onTap;

  const ResidenceCard({
    Key? key,
    required this.title,
    required this.image,
    required this.amenities,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ResidenceAmenities(amenities: amenities),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
