import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/residence_type_enum.dart';
import '../../core/utils/responsive_utils.dart';

/// Widget affichant les catégories populaires avec des visuels attractifs
class PopularCategoriesWidget extends StatefulWidget {
  /// Titre de la section
  final String title;
  
  /// Sous-titre explicatif
  final String? subtitle;
  
  /// Nombre de catégories à afficher par ligne
  final int itemsPerRow;
  
  /// Style d'affichage (grid, carousel, list)
  final String viewStyle;
  
  /// Si true, utilisera des effets visuels plus élaborés
  final bool useEnhancedVisuals;
  
  const PopularCategoriesWidget({
    Key? key,
    this.title = 'Catégories populaires',
    this.subtitle,
    this.itemsPerRow = 2,
    this.viewStyle = 'grid',
    this.useEnhancedVisuals = true,
  }) : super(key: key);

  @override
  State<PopularCategoriesWidget> createState() => _PopularCategoriesWidgetState();
}

class _PopularCategoriesWidgetState extends State<PopularCategoriesWidget> {
  int _hoveredIndex = -1;
  final _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  
  // Liste des catégories populaires avec leurs images et icônes
  final List<Map<String, dynamic>> _popularCategories = [
    {
      'type': ResidenceType.villa,
      'title': 'Villas de luxe',
      'description': 'Espaces spacieux et élégants',
      'icon': Icons.villa,
      'image': 'assets/images/residences/luxury/images (3).jpg',
      'gradient': [Colors.blueAccent, Colors.lightBlueAccent],
      'count': '157',
    },
    {
      'type': ResidenceType.apartment,
      'title': 'Appartements',
      'description': 'Confort et praticité',
      'icon': Icons.apartment,
      'image': 'assets/images/residences/premium1.png',
      'gradient': [Colors.orange, Colors.amber],
      'count': '243',
    },
    {
      'type': ResidenceType.studio,
      'title': 'Studios',
      'description': 'Parfait pour les célibataires',
      'icon': Icons.single_bed,
      'image': 'assets/images/residences/promo1.png',
      'gradient': [Colors.teal, Colors.tealAccent],
      'count': '189',
    },
    {
      'type': ResidenceType.hotelDePassage,
      'title': 'Court séjour',
      'description': 'Location à l\'heure',
      'icon': Icons.timer,
      'image': 'assets/images/residences/promo2.png',
      'gradient': [Colors.purple, Colors.deepPurple],
      'count': '95',
    },
    {
      'type': ResidenceType.residenceHoteliere,
      'title': 'Résidences hôt.',
      'description': 'Services hôteliers inclus',
      'icon': Icons.hotel,
      'image': 'assets/images/residences/premium2.png',
      'gradient': [Colors.red, Colors.redAccent],
      'count': '78',
    },
    {
      'type': ResidenceType.house,
      'title': 'Maisons',
      'description': 'Pour toute la famille',
      'icon': Icons.home,
      'image': 'assets/images/backgrounds/city_skyline.png',
      'gradient': [Colors.green, Colors.lightGreen],
      'count': '122',
    },
  ];
  
  @override
  void initState() {
    super.initState();
    // Écouteur pour le carousel
    if (widget.viewStyle == 'carousel') {
      _pageController.addListener(() {
        int next = _pageController.page!.round();
        if (_currentPage != next) {
          setState(() {
            _currentPage = next;
          });
        }
      });
    }
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildCategoriesSection(),
      ],
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: context.responsiveFontSize(20),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.subtitle!,
              style: TextStyle(
                fontSize: context.responsiveFontSize(14),
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      )
      .animate()
      .fadeIn(duration: 400.ms, curve: Curves.easeOutQuad)
      .slideX(begin: -0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
    );
  }
  
  Widget _buildCategoriesSection() {
    switch (widget.viewStyle) {
      case 'carousel':
        return _buildCarouselView();
      case 'list':
        return _buildListView();
      case 'grid':
      default:
        return _buildGridView();
    }
  }
  
  // Affichage en grille (par défaut)
  Widget _buildGridView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.itemsPerRow,
          childAspectRatio: 1.1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _popularCategories.length,
        itemBuilder: (context, index) {
          final category = _popularCategories[index];
          final isHovered = _hoveredIndex == index;
          
          return _buildGridItem(category, index, isHovered);
        },
      ),
    );
  }
  
  // Affichage en carousel
  Widget _buildCarouselView() {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _popularCategories.length,
        itemBuilder: (context, index) {
          final category = _popularCategories[index];
          final isActive = _currentPage == index;
          
          return AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: isActive ? 0 : 8,
            ),
            child: _buildCarouselItem(category, index, isActive),
          );
        },
      ),
    );
  }
  
  // Affichage en liste
  Widget _buildListView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _popularCategories.length,
      itemBuilder: (context, index) {
        final category = _popularCategories[index];
        final isHovered = _hoveredIndex == index;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
          child: _buildListItem(category, index, isHovered),
        );
      },
    );
  }
  
  // Item de la grille
  Widget _buildGridItem(Map<String, dynamic> category, int index, bool isHovered) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: GestureDetector(
        onTap: () => _navigateToCategory(category['type']),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isHovered ? 0.15 : 0.08),
                blurRadius: isHovered ? 8 : 4,
                offset: Offset(0, isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Arrière-plan ou image
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    category['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback en cas d'erreur de chargement d'image
                      return Container(
                        color: category['gradient'][0].withOpacity(0.7),
                        child: Center(
                          child: Icon(
                            category['icon'],
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Dégradé pour la lisibilité
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Contenu
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            category['icon'],
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              category['title'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              category['description'],
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${category['count']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .animate(target: isHovered ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 200.ms,
          curve: Curves.easeOutQuad,
        ),
      )
      .animate(delay: 100.ms * index)
      .fadeIn(duration: 600.ms, curve: Curves.easeOutQuad)
      .moveY(begin: 20, end: 0, duration: 600.ms, curve: Curves.easeOutQuad),
    );
  }
  
  // Item du carousel
  Widget _buildCarouselItem(Map<String, dynamic> category, int index, bool isActive) {
    return GestureDetector(
      onTap: () => _navigateToCategory(category['type']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isActive ? 0.15 : 0.08),
              blurRadius: isActive ? 8 : 4,
              offset: Offset(0, isActive ? 4 : 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Arrière-plan avec image
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  category['image'],
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            // Overlay avec dégradé
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      category['gradient'][0].withOpacity(0.5),
                      category['gradient'][1].withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
            
            // Contenu
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icône et titre
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          category['icon'],
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category['description'],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    
                    // Compteur et bouton
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${category['count']} résidences',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Text(
                            'Explorer',
                            style: TextStyle(
                              color: category['gradient'][0],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Item de la liste
  Widget _buildListItem(Map<String, dynamic> category, int index, bool isHovered) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: GestureDetector(
        onTap: () => _navigateToCategory(category['type']),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isHovered ? 0.15 : 0.08),
                blurRadius: isHovered ? 8 : 4,
                offset: Offset(0, isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Image de gauche
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Image.asset(
                    category['image'],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              
              // Contenu
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Titre et description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              category['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category['description'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Compteur et icône
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: category['gradient'][0].withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${category['count']}',
                              style: TextStyle(
                                color: category['gradient'][0],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Icon(
                            category['icon'],
                            color: category['gradient'][0],
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .animate(target: isHovered ? 1 : 0)
        .elevation(begin: 0, end: 6, duration: 200.ms)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.01, 1.01),
          duration: 200.ms,
          curve: Curves.easeOutQuad,
        ),
      )
      .animate(delay: 50.ms * index)
      .fadeIn(duration: 500.ms, curve: Curves.easeOutQuad)
      .slideX(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOutQuad),
    );
  }
  
  // Navigation vers la page de catégorie
  void _navigateToCategory(ResidenceType type) {
    final typeCode = type.typeCode;
    context.push('/residences?type=$typeCode');
  }
}
