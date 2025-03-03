import 'package:flutter/material.dart';
import '../constants/app_assets.dart';

class Amenity {
  final String name;
  final String icon;
  final String description;

  const Amenity({
    required this.name,
    required this.icon,
    required this.description,
  });

  // Méthode pour obtenir tous les équipements disponibles
  static List<Amenity> getAllAmenities() {
    return [
      Amenity(
        name: 'Wi-Fi',
        icon: AppAssets.iconWifi,
        description: 'Internet haut débit gratuit',
      ),
      Amenity(
        name: 'Climatisation',
        icon: AppAssets.iconAc,
        description: 'Climatisation dans toutes les pièces',
      ),
      Amenity(
        name: 'Parking',
        icon: AppAssets.iconParking,
        description: 'Parking sécurisé disponible',
      ),
      Amenity(
        name: 'Piscine',
        icon: AppAssets.iconPool,
        description: 'Piscine privée ou commune',
      ),
      Amenity(
        name: 'Salle de sport',
        icon: AppAssets.iconGym,
        description: 'Équipements de fitness modernes',
      ),
      Amenity(
        name: 'Sécurité 24/7',
        icon: AppAssets.iconSecurity,
        description: 'Gardiennage et vidéosurveillance',
      ),
      Amenity(
        name: 'Ascenseur',
        icon: AppAssets.iconElevator,
        description: 'Accès facile aux étages supérieurs',
      ),
      Amenity(
        name: 'Jardin',
        icon: AppAssets.iconGarden,
        description: 'Zone verte aménagée',
      ),
      Amenity(
        name: 'Balcon/Terrasse',
        icon: AppAssets.iconBalcony,
        description: 'Vue extérieure privée',
      ),
      Amenity(
        name: 'Meublé',
        icon: AppAssets.iconFurnished,
        description: 'Entièrement équipé et meublé',
      ),
    ];
  }
}
