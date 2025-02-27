import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';
import '../../core/models/residence_type_enum.dart';

class CategoriesMenuWidget extends StatelessWidget {
  const CategoriesMenuWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Catégories',
            style: AppTheme.headingLarge,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 400,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: _getCategoryItems(context),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  List<Widget> _getCategoryItems(BuildContext context) {
    final categories = [
      (type: ResidenceType.apartment, title: 'Appartements'),
      (type: ResidenceType.studio, title: 'Studios'),
      (type: ResidenceType.villa, title: 'Villas'),
      (type: ResidenceType.penthouse, title: 'Penthouses'),
      (type: ResidenceType.bungalow, title: 'Bungalows'),
      (type: ResidenceType.hotel, title: 'Hôtels'),
      (type: ResidenceType.coworking, title: 'Espaces Coworking'),
      (type: ResidenceType.student, title: 'Logements Étudiants'),
    ];

    return categories.map((category) => _buildCategoryItem(
      context,
      category.type,
      category.title,
    )).toList();
  }

  Widget _buildCategoryItem(BuildContext context, ResidenceType type, String title) {
    return Container(
      width: 300,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(type),
                  size: 30,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.headingMedium,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: _getCategoryFeatures(type).map((feature) => 
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle_outline, size: 20),
                  title: Text(
                    feature,
                    style: AppTheme.bodyMedium,
                  ),
                ),
              ).toList(),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(ResidenceType type) {
    switch (type) {
      case ResidenceType.apartment:
        return Icons.apartment;
      case ResidenceType.studio:
        return Icons.single_bed;
      case ResidenceType.villa:
        return Icons.house;
      case ResidenceType.penthouse:
        return Icons.location_city;
      case ResidenceType.bungalow:
        return Icons.holiday_village;
      case ResidenceType.hotel:
        return Icons.hotel;
      case ResidenceType.coworking:
        return Icons.business_center;
      case ResidenceType.student:
        return Icons.school;
    }
  }

  List<String> _getCategoryFeatures(ResidenceType type) {
    if (type.isVacationResidence) {
      return [
        'Locations saisonnières',
        'Séjours courts',
        'Vacances',
        'Événements',
      ];
    }

    if (type.isSpecialResidence) {
      return [
        'Espaces de travail',
        'Salles de réunion',
        'Bureaux privés',
      ];
    }

    return [
      'Location longue durée',
      'Achat',
      'Investissement',
    ];
  }
}
