import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/models/residence_type_enum.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/services/logger_service.dart';
import '../../core/theme/app_theme.dart';
import 'common/premium_card.dart';

/// Widget amélioré affichant les catégories populaires avec des visuels attractifs,
/// animations fluides, et support du mode sombre.
/// 
/// Ce widget supporte différents styles d'affichage (grille, carrousel, liste)
/// et s'adapte automatiquement aux différentes tailles d'écran.
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

class _PopularCategoriesWidgetState extends State<PopularCategoriesWidget> with SingleTickerProviderStateMixin {
  final LoggerService _logger = LoggerService();
  int _hoveredIndex = -1;
  final _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  late AnimationController _animationController;
  bool _isLoading = true;
  
  // Liste des catégories populaires avec leurs types associés, images et icônes
  final List<Map<String, dynamic>> _popularCategories = [
    {
      'title': 'Résidences meublées',
      'description': 'Confort et élégance',
      'icon': Icons.apartment,
      'image': 'assets/images/residences/premium1.png',
      'gradient': [Colors.orange, Colors.amber],
      'count': '243',
      'categoryTypes': [
        ResidenceType.studioMeuble,
        ResidenceType.appartementMeuble,
        ResidenceType.villaMeublee,
        ResidenceType.penthouse,
        ResidenceType.loft,
        ResidenceType.grenier,
      ],
    },
    {
      'title': 'Hôtels & Hébergements',
      'description': 'Services hôteliers',
      'icon': Icons.hotel,
      'image': 'assets/images/residences/premium2.png',
      'gradient': [Colors.red, Colors.redAccent],
      'count': '78',
      'categoryTypes': [
        ResidenceType.hotelDePassage,
        ResidenceType.motel,
        ResidenceType.boutiqueHotel,
        ResidenceType.hotelDeLuxe,
        ResidenceType.aubergeEtMaisonDHotes,
        ResidenceType.residenceHoteliere,
      ],
    },
    {
      'title': 'Hébergements insolites',
      'description': 'Expériences uniques',
      'icon': Icons.landscape,
      'image': 'assets/images/residences/luxury/images (3).jpg',
      'gradient': [Colors.blueAccent, Colors.lightBlueAccent],
      'count': '89',
      'categoryTypes': [
        ResidenceType.bungalow,
        ResidenceType.lodgeEtEcolodge,
        ResidenceType.caseTraditionnelle,
        ResidenceType.maisonFlottante,
        ResidenceType.campementTouristique,
      ],
    },
    {
      'title': 'Colocation & partage',
      'description': 'Vivre ensemble',
      'icon': Icons.people,
      'image': 'assets/images/residences/promo1.png',
      'gradient': [Colors.teal, Colors.tealAccent],
      'count': '189',
      'categoryTypes': [
        ResidenceType.chambreEnColocation,
        ResidenceType.cohabitation,
        ResidenceType.residenceUniversitaire,
        ResidenceType.citeDortoir,
      ],
    },
    {
      'title': 'Résidences longue durée',
      'description': 'Pour s\'installer',
      'icon': Icons.home,
      'image': 'assets/images/backgrounds/city_skyline.png',
      'gradient': [Colors.green, Colors.lightGreen],
      'count': '122',
      'categoryTypes': [
        ResidenceType.appartementNonMeuble,
        ResidenceType.villaNonMeublee,
        ResidenceType.immeuble,
        ResidenceType.courCommune,
      ],
    },
    {
      'title': 'Hébergements économiques',
      'description': 'Budget raisonnable',
      'icon': Icons.monetization_on,
      'image': 'assets/images/residences/promo2.png',
      'gradient': [Colors.purple, Colors.deepPurple],
      'count': '95',
      'categoryTypes': [
        ResidenceType.maisonDHotesEconomique,
        ResidenceType.residenceFamilialeEnLocation,
        ResidenceType.chambresDePassage,
      ],
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _logger.debug('PopularCategoriesWidget - initState');
    
    // Initialisation de l'AnimationController pour les animations complexes
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Initialisation du PageController pour le carousel
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
    
    // Simuler un chargement pour les animations d'entrée
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _animationController.forward();
      }
    });
  }
  
  @override
  void dispose() {
    _logger.debug('PopularCategoriesWidget - dispose');
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(isDarkMode),
        const SizedBox(height: 16),
        // Afficher un widget de chargement ou les catégories
        _isLoading 
          ? _buildLoadingState(isDarkMode) 
          : _buildCategoriesSection(isDarkMode),
      ],
    );
  }
  
  // Widget de chargement avec shimmer effect
  Widget _buildLoadingState(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Shimmer.fromColors(
        baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.itemsPerRow,
            childAspectRatio: 1.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 4, // Afficher 4 éléments de chargement
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildHeader(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            semanticsLabel: 'Titre de section: ${widget.title}',
            style: TextStyle(
              fontSize: context.responsiveFontSize(20),
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.subtitle!,
              semanticsLabel: 'Description: ${widget.subtitle}',
              style: TextStyle(
                fontSize: context.responsiveFontSize(14),
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
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
  
  Widget _buildCategoriesSection(bool isDarkMode) {
    switch (widget.viewStyle) {
      case 'carousel':
        return _buildCarouselView(isDarkMode);
      case 'list':
        return _buildListView(isDarkMode);
      case 'grid':
      default:
        return _buildGridView(isDarkMode);
    }
  }
  
  // Affichage en grille (par défaut)
  Widget _buildGridView(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.itemsPerRow,
          // Augmenter légèrement le ratio pour éviter le débordement
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
        ),
        itemCount: _popularCategories.length,
        itemBuilder: (context, index) {
          final category = _popularCategories[index];
          final isHovered = _hoveredIndex == index;
          
          return _buildGridItem(category, index, isHovered, isDarkMode)
            .animate()
            .fadeIn(duration: 400.ms, delay: (100 * index).ms, curve: Curves.easeOutQuad)
            .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: (100 * index).ms, curve: Curves.easeOutQuad);
        },
      ),
    );
  }
  
  // Affichage en carousel
  Widget _buildCarouselView(bool isDarkMode) {
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
            child: _buildCarouselItem(category, index, isActive, isDarkMode),
          );
        },
      ),
    );
  }
  
  // Affichage en liste
  Widget _buildListView(bool isDarkMode) {
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
  Widget _buildGridItem(Map<String, dynamic> category, int index, bool isHovered, bool isDarkMode) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: InkWell(
        onTap: () {
          _navigateToCategory(category);
        },
        borderRadius: BorderRadius.circular(20),
        child: PremiumCard(
          borderRadius: 20,
          elevation: isHovered ? 8 : 4,
          backgroundColor: isDarkMode 
            ? AppTheme.primaryColor.withOpacity(0.1) 
            : Colors.white,
          border: Border.all(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.1),
            width: 1,
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
  Widget _buildCarouselItem(Map<String, dynamic> category, int index, bool isActive, bool isDarkMode) {
    return GestureDetector(
      onTap: () => _navigateToCategory(category),
      child: PremiumCard(
        borderRadius: 20,
        elevation: isActive ? 10 : 4,
        backgroundColor: isDarkMode
          ? AppTheme.primaryColor.withOpacity(isActive ? 0.25 : 0.15)
          : Colors.white,
        border: Border.all(
          color: isActive ? AppTheme.primaryColor : Colors.transparent,
          width: isActive ? 2 : 0,
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
        onTap: () => _navigateToCategory(category),
        child: PremiumCard(
          height: 80,
          borderRadius: 12,
          elevation: isHovered ? 8 : 4,
          backgroundColor: Colors.white,
          border: Border.all(
            color: Colors.black.withOpacity(0.05),
            width: 1,
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
  void _navigateToCategory(Map<String, dynamic> category) {
    _logger.info('Navigation vers la catégorie: ${category['title']}');
    
    // Obtenir les types de la catégorie
    final List<ResidenceType> types = category['categoryTypes'] as List<ResidenceType>;
    if (types.isNotEmpty) {
      final ResidenceType mainType = types.first;
      
      // Utiliser GoRouter pour naviguer vers la page de recherche avec le filtre
      context.push('/search?type=${mainType.toString().split('.').last}');
      
      // Retour haptique pour feedback utilisateur
      HapticFeedback.mediumImpact();
    } else {
      _logger.warning('Aucun type trouvé pour la catégorie: ${category['title']}');
    }
  }
}
