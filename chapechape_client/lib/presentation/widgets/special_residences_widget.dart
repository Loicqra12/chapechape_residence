import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart' as fcw;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/residence_model.dart';
import '../../core/constants/app_assets.dart' as assets;
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/residence_adapters.dart';

class SpecialResidencesWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<Residence> residences;
  final dynamic filterType; // Changé pour accepter différents types
  final bool isLoading;
  final bool showPrice;
  final bool showRating;
  final bool isHorizontal;
  final double cardHeight;
  final double? maxHeight;
  final EdgeInsets padding;
  final int maxItems;
  final ScrollController? scrollController;

  const SpecialResidencesWidget({
    super.key,
    required this.title,
    this.subtitle = '',
    this.residences = const [],
    required this.filterType,
    this.isLoading = false,
    this.showPrice = true,
    this.showRating = true,
    this.isHorizontal = true,
    this.cardHeight = 220,
    this.maxHeight,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.maxItems = 8,
    this.scrollController,
  });

  @override
  State<SpecialResidencesWidget> createState() => _SpecialResidencesWidgetState();
}

class _SpecialResidencesWidgetState extends State<SpecialResidencesWidget> {
  final ScrollController _scrollController = ScrollController();
  // État pour suivre l'index actuel du carousel
  int _currentCarouselIndex = 0;
  
  // Définition de constantes locales en remplacement de AppConstants
  static const String currencySymbol = 'FCFA'; // Remplace AppConstants.currencySymbol

  List<Residence> get _displayResidences {
    if (widget.residences.isEmpty) {
      return [];
    }
    return widget.residences.length > widget.maxItems 
      ? widget.residences.sublist(0, widget.maxItems)
      : widget.residences;
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculer la hauteur en fonction du contenu si pas horizontale
    final computedMaxHeight = widget.isHorizontal 
      ? widget.maxHeight
      : _displayResidences.isEmpty
        ? widget.cardHeight + 100 // Juste assez d'espace pour le titre et un message
        : (widget.cardHeight * ((_displayResidences.length / 2).ceil())) + 100;
    
    if (widget.isLoading) {
      return _buildLoadingSkeleton(context);
    }
    
    if (_displayResidences.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      constraints: BoxConstraints(
        maxHeight: computedMaxHeight ?? double.infinity,
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
      children: [
          Padding(
            padding: widget.padding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(20),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                      if (widget.subtitle.isNotEmpty) ... [
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(14),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.isHorizontal && _displayResidences.length > 1) ... [
                  // Indicateurs de navigation pour le carrousel
                  IconButton(
                    onPressed: () {
                      // Remplacer l'appel direct au contrôleur par une gestion d'état
                      setState(() {
                        _currentCarouselIndex = (_currentCarouselIndex - 1) % _displayResidences.length;
                        if (_currentCarouselIndex < 0) {
                          _currentCarouselIndex = _displayResidences.length - 1;
                        }
                      });
                    },
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () {
                      // Remplacer l'appel direct au contrôleur par une gestion d'état
                      setState(() {
                        _currentCarouselIndex = (_currentCarouselIndex + 1) % _displayResidences.length;
                      });
                    },
                    icon: const Icon(Icons.arrow_forward_ios, size: 20),
                  ),
                ],
                if (!widget.isHorizontal && _displayResidences.length > widget.maxItems) ... [
                  // Bouton "Voir plus" pour la vue en grille
                  TextButton(
                    onPressed: () => _onSeeAll(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Voir plus',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(14),
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: widget.isHorizontal
              ? _buildHorizontalList(context)
              : _buildGridView(context),
          ),
        ],
      ),
    );
  }
  
  void _onSeeAll(BuildContext context) {
    // Extraire le type pour le filtre
    String typeParam = '';
    if (widget.filterType is ResidenceType) {
      typeParam = widget.filterType.toString().split('.').last;
    } else if (widget.filterType is assets.ResidenceType) {
      typeParam = widget.filterType.toString().split('.').last;
    } else if (widget.filterType is String) {
      typeParam = widget.filterType;
    }
    
    // Naviguer vers la page de recherche avec le filtre
    context.push('/search?type=$typeParam');
  }
  
  void _onResidenceTap(BuildContext context, Residence residence) {
    // Utiliser GoRouter pour la navigation
    context.push('/residence/${residence.id}');
  }
  
  Widget _buildGridView(BuildContext context) {
    final controller = widget.scrollController ?? _scrollController;
    
    // En mode hors ligne ou quand les résidences sont vides, montrer un message
    if (_displayResidences.isEmpty && !widget.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(
              'Aucune résidence disponible',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Réessayez plus tard ou vérifiez votre connexion',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // Afficher un indicateur de chargement si nécessaire
    if (widget.isLoading) {
      return _buildLoadingGrid(context);
    }
    
    return MasonryGridView.count(
      shrinkWrap: true,
      controller: controller,
      padding: widget.padding,
      physics: const BouncingScrollPhysics(),
      crossAxisCount: context.screenWidth > 600 ? 3 : 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      itemCount: _displayResidences.length,
      itemBuilder: (context, index) {
        final residence = _displayResidences[index];
        
        // Utiliser les extensions ResidenceProperties de manière sécurisée
        // Vérifier que les propriétés existent pour éviter les erreurs
        final bool isSpecial = residence.isSpecial;
        final bool isVacation = residence.isVacationResidence;
        
        // Calculer un ratio dynamique pour créer un effet de grille Pinterest
        final double height = widget.cardHeight * (isSpecial || isVacation ? 1.2 : 1.0);
        
        // Animer l'apparition des cartes avec un délai progressif basé sur l'index
        // pour créer un effet d'apparition séquentielle
        return SizedBox(
          height: height,
          child: _buildResidenceCard(context, residence, false),
        )
        .animate(delay: Duration(milliseconds: 50 * index)) // Délai progressif
        .fadeIn(duration: const Duration(milliseconds: 600), curve: Curves.easeOutQuad)
        .slideY(begin: 0.2, end: 0, duration: const Duration(milliseconds: 500), curve: Curves.easeOutQuad);
      },
    );
  }
  
  // Widget pour afficher un état de chargement
  Widget _buildLoadingGrid(BuildContext context) {
    return MasonryGridView.count(
      shrinkWrap: true,
      padding: widget.padding,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: context.screenWidth > 600 ? 3 : 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      itemCount: 6, // Nombre d'éléments de chargement
      itemBuilder: (context, index) {
        // Varier les hauteurs pour un effet visuel plus naturel
        final double height = widget.cardHeight * (index % 2 == 0 ? 1.0 : 1.2);
        
        return SizedBox(
          height: height,
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildHorizontalList(BuildContext context) {
    if (_displayResidences.length == 1) {
      // Si une seule résidence, on affiche une seule carte centrée
      return Center(
        child: Container(
          width: context.screenWidth * 0.85,
          height: widget.cardHeight,
          padding: widget.padding,
          child: _buildResidenceCard(
            context, 
            _displayResidences.first,
            false,
          ),
        ),
      );
    }
    
    return fcw.FlutterCarousel.builder(
      itemCount: _displayResidences.length,
      itemBuilder: (context, index, realIndex) {
        final residence = _displayResidences[index];
        return _buildResidenceCard(context, residence, true);
      },
      options: fcw.CarouselOptions(
        height: widget.cardHeight,
        viewportFraction: context.screenWidth > 600 ? 0.4 : 0.85,
        enlargeCenterPage: true,
        enableInfiniteScroll: _displayResidences.length > 2,
        initialPage: _currentCarouselIndex,
        onPageChanged: (index, reason) {
          setState(() {
            _currentCarouselIndex = index;
          });
        },
      ),
    );
  }
  
  Widget _buildResidenceCard(
    BuildContext context, 
    Residence residence,
    bool isCarousel,
  ) {
    // Utiliser assets.convertModelTypeToAssetType pour vérifier si c'est luxe
    final assetType = assets.convertModelTypeToAssetType(residence.type);
    final bool isLuxury = assetType == assets.ResidenceType.luxury;
    
    return GestureDetector(
      onTap: () => _onResidenceTap(context, residence),
      child: Animate(
        effects: [
          FadeEffect(duration: 300.ms, delay: 50.ms),
          SlideEffect(begin: const Offset(0, 0.1), end: Offset.zero),
        ],
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image avec badge de luxe si applicable
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    // Image principale
                    SizedBox(
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: residence.images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: residence.images.first,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => Image.asset(
                                'assets/images/placeholders/placeholder.jpg',
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/images/placeholders/placeholder.jpg',
                              fit: BoxFit.cover,
                            ),
                      ),
                    ),
                    
                    // Badge de luxe
                    if (isLuxury) ... [
              Positioned(
                        top: 8,
                        right: 8,
                    child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                      decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.stars,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'LUXE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: context.responsiveFontSize(10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    // Prix
                    if (widget.showPrice && residence.price > 0) ... [
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${residence.price.toStringAsFixed(0)} $currencySymbol',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: context.responsiveFontSize(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Informations détaillées
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Titre de la résidence
                      Text(
                        residence.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: context.responsiveFontSize(14),
                        ),
                      ),
                      
                      // Adresse
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              residence.city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: context.responsiveFontSize(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Notation
                      if (widget.showRating) ... [
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${residence.rating.toStringAsFixed(1)} (${residence.reviewCount})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: context.responsiveFontSize(12),
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      // Commodités principales
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFeatureIcon(
                            context,
                            '${residence.bedrooms}',
                            Icons.bed,
                          ),
                          _buildFeatureIcon(
                            context,
                            '${residence.bathrooms}',
                            Icons.bathtub,
                          ),
                          _buildFeatureIcon(
                            context,
                            '${residence.surface} m²',
                            Icons.square_foot,
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
      ),
    );
  }
  
  Widget _buildFeatureIcon(BuildContext context, String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: context.responsiveFontSize(12),
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: widget.cardHeight + 60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Padding(
            padding: widget.padding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(20),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      if (widget.subtitle.isNotEmpty) ... [
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(14),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // État vide
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune résidence disponible',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(16),
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      context.push('/search');
                    },
                    child: const Text('Explorer toutes les résidences'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingSkeleton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: widget.cardHeight + 60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre skelette
          Padding(
            padding: widget.padding,
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 180,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 240,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Cards skelette
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              padding: widget.padding,
              itemBuilder: (context, index) {
                return Container(
                  width: context.screenWidth > 600 ? 300 : 250,
                  margin: const EdgeInsets.only(right: 16),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
