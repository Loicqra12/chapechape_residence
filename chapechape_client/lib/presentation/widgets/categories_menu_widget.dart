import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import 'svg_icon.dart';
import '../../core/theme/app_theme.dart';

class CategoriesMenuWidget extends StatelessWidget {
  const CategoriesMenuWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Explorez nos catégories',
              style: AppTheme.headingLarge,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: ResidenceType.values.map((type) => _buildCategoryCard(type)).toList(),
            ),
          ),
          const SizedBox(height: 30),
          _buildCountrySection(),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(ResidenceType type) {
    return Container(
      width: 300,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.lightGold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.lightGold,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                CategoryIcon(
                  categoryName: _getCategoryIconName(type),
                  size: 30,
                  color: AppTheme.primaryGold,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getCategoryTitle(type),
                    style: AppTheme.headingMedium,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _getCategoryItems(type).length,
            itemBuilder: (context, index) {
              final item = _getCategoryItems(type)[index];
              return ListTile(
                title: Text(
                  item,
                  style: AppTheme.bodyMedium,
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.primaryGold,
                ),
                onTap: () {
                  // TODO: Implémenter la navigation
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _getCategoryIconName(ResidenceType type) {
    switch (type) {
      case ResidenceType.apartment:
        return 'apartment';
      case ResidenceType.studio:
        return 'bed';
      case ResidenceType.villa:
        return 'villa';
      case ResidenceType.room:
        return 'bed';
      case ResidenceType.bungalow:
        return 'bungalow';
      case ResidenceType.penthouse:
        return 'penthouse';
      case ResidenceType.hotel:
        return 'five-stars';
      case ResidenceType.luxury:
        return 'five-stars';
    }
  }

  String _getCategoryTitle(ResidenceType type) {
    switch (type) {
      case ResidenceType.apartment:
        return 'Appartements';
      case ResidenceType.studio:
        return 'Studios';
      case ResidenceType.villa:
        return 'Villas';
      case ResidenceType.room:
        return 'Chambres';
      case ResidenceType.bungalow:
        return 'Bungalows';
      case ResidenceType.penthouse:
        return 'Penthouses';
      case ResidenceType.hotel:
        return 'Hôtels';
      case ResidenceType.luxury:
        return 'Luxe';
    }
  }

  List<String> _getCategoryItems(ResidenceType type) {
    switch (type) {
      case ResidenceType.apartment:
        return ['1 Chambre', '2 Chambres', '3 Chambres', 'Duplex'];
      case ResidenceType.studio:
        return ['Meublé', 'Non meublé', 'Étudiant'];
      case ResidenceType.villa:
        return ['Moderne', 'Traditionnelle', 'Avec piscine'];
      case ResidenceType.room:
        return ['Chambre simple', 'Suite', 'Colocation'];
      case ResidenceType.bungalow:
        return ['Vue mer', 'Jardin privé', 'Plage'];
      case ResidenceType.penthouse:
        return ['Vue panoramique', 'Terrasse', 'Luxe'];
      case ResidenceType.hotel:
        return ['Business', 'Vacances', 'Résidentiel'];
      case ResidenceType.luxury:
        return ['Premium', 'VIP', 'Ultra luxe'];
    }
  }

  Widget _buildCountrySection() {
    final countries = [
      ('Côte d\'Ivoire', '🇨🇮'),
      ('Sénégal', '🇸🇳'),
      ('Mali', '🇲🇱'),
      ('Burkina Faso', '🇧🇫'),
      ('Ghana', '🇬🇭'),
      ('Togo', '🇹🇬'),
      ('Bénin', '🇧🇯'),
      ('Guinée', '🇬🇳'),
      ('Niger', '🇳🇪'),
      ('Nigéria', '🇳🇬'),
      ('Libéria', '🇱🇷'),
      ('Sierra Leone', '🇸🇱'),
      ('Gambie', '🇬🇲'),
      ('Cap Vert', '🇨🇻'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Pays disponibles',
            style: AppTheme.headingLarge,
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: countries.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                // TODO: Implémenter la navigation
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.softShadow,
                  border: Border.all(color: AppTheme.lightGold),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      countries[index].$2,
                      style: AppTheme.bodyMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      countries[index].$1,
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
