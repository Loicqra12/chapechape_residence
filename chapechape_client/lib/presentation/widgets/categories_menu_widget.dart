import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/residence_type_enum.dart';
import '../../core/models/residence_type.dart';
import '../../core/utils/responsive_utils.dart';

class CategoriesMenuWidget extends StatelessWidget {
  const CategoriesMenuWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: context.responsivePadding,
          child: Text(
            'Catégories',
            style: TextStyle(
              fontSize: context.responsiveFontSize(24),
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: context.responsiveHeight(400),
          child: context.screenWidth > 600
              ? GridView.count(
                  crossAxisCount: context.screenWidth > 900 ? 3 : 2,
                  childAspectRatio: 1.5,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: _getCategoryItems(context),
                )
              : ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: _getCategoryItems(context),
                ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  List<Widget> _getCategoryItems(BuildContext context) {
    final categories = [
      {'type': ResidenceType.apartment, 'title': 'Appartements'},
      {'type': ResidenceType.studio, 'title': 'Studios'},
      {'type': ResidenceType.villa, 'title': 'Villas'},
      {'type': ResidenceType.penthouse, 'title': 'Penthouses'},
      {'type': ResidenceType.bungalow, 'title': 'Bungalows'},
      {'type': ResidenceType.hotel, 'title': 'Hôtels'},
      {'type': ResidenceType.room, 'title': 'Chambres'},
      {'type': ResidenceType.luxury, 'title': 'Luxe'},
    ];

    return categories.map((category) {
      final type = category['type'] as ResidenceType;
      final title = category['title'] as String;
      return _buildCategoryItem(
        context,
        type,
        title,
      );
    }).toList();
  }

  Widget _buildCategoryItem(BuildContext context, ResidenceType type, String title) {
    final isHorizontalList = context.screenWidth <= 600;
    
    return Container(
      width: isHorizontalList ? context.responsiveWidth(300) : null,
      margin: EdgeInsets.symmetric(
        horizontal: isHorizontalList ? 10 : 8, 
        vertical: isHorizontalList ? 0 : 8
      ),
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
            padding: EdgeInsets.all(context.isMobileSmall ? 10 : 15),
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(type),
                  size: context.responsiveFontSize(30),
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: context.isMobileSmall ? 10 : 15
              ),
              children: _getCategoryFeatures(type).map((feature) => 
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.check_circle_outline,
                    color: AppTheme.secondaryColor,
                    size: context.responsiveFontSize(18),
                  ),
                  title: Text(
                    feature,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(14),
                    ),
                  ),
                )
              ).toList(),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(context.isMobileSmall ? 10 : 15),
            child: ElevatedButton(
              onPressed: () {
                // TODO: Naviguer vers la liste filtrée par type
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(
                  horizontal: context.isMobileSmall ? 12 : 16, 
                  vertical: context.isMobileSmall ? 8 : 12
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Explorer',
                style: TextStyle(
                  fontSize: context.responsiveFontSize(14),
                  fontWeight: FontWeight.bold,
                ),
              ),
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
      case ResidenceType.room:
        return Icons.bedroom_child;
      case ResidenceType.luxury:
        return Icons.star;
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
