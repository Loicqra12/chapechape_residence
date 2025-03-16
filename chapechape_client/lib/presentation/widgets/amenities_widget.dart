import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_theme.dart';

class AmenitiesWidget extends StatelessWidget {
  final List<String> amenities;
  final bool isDetailed;

  const AmenitiesWidget({
    Key? key,
    required this.amenities,
    this.isDetailed = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isDetailed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Équipements et services',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: amenities.map((amenity) => _buildAmenityItem(amenity)).toList(),
          ),
        ],
      );
    } else {
      // Version simplifiée pour les petits espaces
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: amenities
            .take(3)
            .map((amenity) => Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _buildSimpleAmenityItem(amenity),
                ))
            .toList(),
      );
    }
  }

  Widget _buildSimpleAmenityItem(String amenity) {
    final String iconPath = _getAmenityIconPath(amenity);
    
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: iconPath.endsWith('.svg')
          ? SvgPicture.asset(
              iconPath,
              height: 16,
              width: 16,
              color: AppTheme.primaryColor,
            )
          : Image.asset(
              iconPath,
              height: 16,
              width: 16,
            ),
    );
  }

  Widget _buildAmenityItem(String amenity) {
    final String iconPath = _getAmenityIconPath(amenity);
    final String displayName = _getAmenityDisplayName(amenity);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconPath.endsWith('.svg'))
            SvgPicture.asset(
              iconPath,
              height: 20,
              width: 20,
              color: AppTheme.primaryColor,
            )
          else
            Image.asset(
              iconPath,
              height: 20,
              width: 20,
            ),
          const SizedBox(width: 8),
          Text(
            displayName,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _getAmenityIconPath(String amenity) {
    // Mapper les noms d'équipements aux chemins d'icônes
    final Map<String, String> amenityIcons = {
      'wifi': 'assets/icons/amenities/wifi.png',
      'pool': 'assets/icons/amenities/pool.svg',
      'parking': 'assets/icons/amenities/parking.svg',
      'gym': 'assets/icons/amenities/gym.svg',
      'security': 'assets/icons/amenities/security.svg',
      'furnished': 'assets/icons/amenities/furnished.svg',
      'garden': 'assets/icons/amenities/garden.svg',
      'elevator': 'assets/icons/amenities/elevator.svg',
      'balcony': 'assets/icons/amenities/balcony.svg',
      'air_conditioning': 'assets/icons/amenities/climatisation.png',
      // Ajouter d'autres équipements au besoin
    };

    // Retourner le chemin de l'icône ou une icône par défaut
    return amenityIcons[amenity.toLowerCase()] ?? 'assets/icons/amenities/furnished.svg';
  }

  String _getAmenityDisplayName(String amenity) {
    // Mapper les noms d'équipements aux noms d'affichage en français
    final Map<String, String> amenityNames = {
      'wifi': 'Wi-Fi',
      'pool': 'Piscine',
      'parking': 'Parking',
      'gym': 'Salle de sport',
      'security': 'Sécurité',
      'furnished': 'Meublé',
      'garden': 'Jardin',
      'elevator': 'Ascenseur',
      'balcony': 'Balcon',
      'air_conditioning': 'Climatisation',
      // Ajouter d'autres équipements au besoin
    };

    // Retourner le nom d'affichage ou le nom d'origine avec une première lettre majuscule
    return amenityNames[amenity.toLowerCase()] ?? 
           amenity.substring(0, 1).toUpperCase() + amenity.substring(1).toLowerCase();
  }
}
