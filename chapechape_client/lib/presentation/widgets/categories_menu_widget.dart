import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/residence_type_enum.dart';
import '../../core/models/residence_type.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/blocs/residence/residence_event.dart';

class CategoriesMenuWidget extends StatefulWidget {
  final bool showTitle;
  
  const CategoriesMenuWidget({
    super.key,
    this.showTitle = false, // Le titre est désactivé par défaut
  });

  @override
  State<CategoriesMenuWidget> createState() => _CategoriesMenuWidgetState();
}

class _CategoriesMenuWidgetState extends State<CategoriesMenuWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    if (_scrollController.hasClients) {
      final double currentPosition = _scrollController.offset;
      final double newPosition = currentPosition - 240;
      _scrollController.animateTo(
        newPosition < 0 ? 0 : newPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollRight() {
    if (_scrollController.hasClients) {
      final double currentPosition = _scrollController.offset;
      final double maxPosition = _scrollController.position.maxScrollExtent;
      final double newPosition = currentPosition + 240;
      _scrollController.animateTo(
        newPosition > maxPosition ? maxPosition : newPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = context.screenWidth <= 600;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ... [
          Padding(
            padding: context.responsivePadding,
            child: Row(
              children: [
                Text(
                  'Catégories',
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(24),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                if (isMobile) ...[
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.swipe,
                    color: Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Faites défiler',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: Stack(
            children: [
              if (isMobile)
                Positioned.fill(
                  child: ListView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: _getCategoryItems(context),
                  ),
                )
              else
                Positioned.fill(
                  child: GridView.count(
                    crossAxisCount: context.screenWidth > 900 ? 3 : 2,
                    childAspectRatio: 1.5,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: _getCategoryItems(context),
                  ),
                ),
              
              // Boutons de navigation (visible seulement en mode mobile)
              if (isMobile) ...[
                // Bouton Précédent
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: InkWell(
                      onTap: _scrollLeft,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_ios, size: 24),
                      ),
                    ),
                  ),
                ),
                
                // Bouton Suivant
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: InkWell(
                      onTap: _scrollRight,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_forward_ios, size: 24),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
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
    final features = _getCategoryFeatures(type);
    
    return Container(
      width: isHorizontalList ? 220 : null, // Largeur fixe pour mobile
      margin: EdgeInsets.symmetric(
        horizontal: isHorizontalList ? 8 : 8, 
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
          // Titre et icône
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Icon(
                  _getCategoryIcon(type),
                  size: 24,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Options (features)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: features.map((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: AppTheme.secondaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          feature,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Bouton Explorer
          Padding(
            padding: const EdgeInsets.all(15),
            child: ElevatedButton(
              onPressed: () {
                _navigateToFilteredResidences(context, type, title);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Center(
                child: Text(
                  'Explorer',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToFilteredResidences(BuildContext context, ResidenceType type, String title) {
    // Créer un filtre pour le type de résidence
    final Map<String, dynamic> filters = {
      'type': type.toString().split('.').last, // Récupérer le nom du type sans le préfixe
    };
    
    // Charger les résidences filtrées en utilisant le bloc
    context.read<ResidenceBloc>().add(
      LoadResidences(
        filters: filters,
        page: 1,
        limit: 20,
      ),
    );
    
    // Afficher une notification pour informer l'utilisateur
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recherche de $title en cours...'),
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Naviguer vers l'écran de recherche
    context.go('/search');
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
