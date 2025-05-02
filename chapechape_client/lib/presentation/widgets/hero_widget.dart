import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart'; // Importer la bibliothèque intl
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/constants/app_assets.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/models/residence_model.dart';

class HeroWidget extends StatefulWidget {
  const HeroWidget({Key? key}) : super(key: key);

  @override
  State<HeroWidget> createState() => _HeroWidgetState();
}

class _HeroWidgetState extends State<HeroWidget> {
  final carousel.CarouselController _carouselController = carousel.CarouselController();
  int _currentIndex = 0;
  List<Residence> _featuredResidences = [];

  @override
  void initState() {
    super.initState();
    // Charger les résidences vedettes au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeaturedResidences();
    });
  }

  void _loadFeaturedResidences() {
    final residenceBloc = BlocProvider.of<ResidenceBloc>(context);
    residenceBloc.add(const LoadFeaturedResidences());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ResidenceBloc, ResidenceState>(
      listener: (context, state) {
        if (state is FeaturedResidencesLoaded) {
          setState(() {
            _featuredResidences = state.residences;
          });
        }
      },
      builder: (context, state) {
        // Utiliser des images par défaut pendant le chargement
        final List<dynamic> items = _featuredResidences.isNotEmpty 
            ? _featuredResidences 
            : [
                AppAssets.heroBg,
                AppAssets.onboardingBackground1,
                AppAssets.onboardingBackground2,
              ];

        return Stack(
          children: [
            // Carousel
            carousel.CarouselSlider(
              carouselController: _carouselController,
              options: carousel.CarouselOptions(
                height: context.screenHeight * 0.6,
                viewportFraction: 1.0,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 5),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                autoPlayCurve: Curves.fastOutSlowIn,
                pauseAutoPlayOnTouch: true,
                aspectRatio: 16/9,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
              items: items.map((item) {
                return Builder(
                  builder: (BuildContext context) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image de fond
                        _buildBackgroundImage(item),
                        
                        // Dégradé pour améliorer la lisibilité du texte
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        
                        // Contenu du slide
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ..._buildSlideContent(item),
                            ],
                          ),
                        ).animate()
                          .fadeIn(duration: 800.ms, curve: Curves.easeOutQuad)
                          .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOutQuad),
                      ],
                    );
                  },
                );
              }).toList(),
            ),
            
            // Indicateurs de slide
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: items.asMap().entries.map((entry) {
                  return _buildDotIndicator(entry.key);
                }).toList(),
              ),
            ),
            
            // Boutons de navigation
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildNavigationButton(
                  icon: Icons.arrow_back_ios,
                  onPressed: () => _carouselController.previousPage(),
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildNavigationButton(
                  icon: Icons.arrow_forward_ios,
                  onPressed: () => _carouselController.nextPage(),
                ),
              ),
            ),
            
            // Barre de recherche
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: _buildSearchBar(context),
            ),
          ],
        );
      },
    );
  }
  
  // Construction de l'image d'arrière-plan
  Widget _buildBackgroundImage(dynamic item) {
    if (item is Residence) {
      return CachedNetworkImage(
        imageUrl: item.imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Image.asset(
          AppAssets.placeholderImage,
          fit: BoxFit.cover,
        ),
        errorWidget: (context, url, error) => Image.asset(
          AppAssets.heroBg,
          fit: BoxFit.cover,
        ),
      );
    } else if (item is String) {
      return Image.asset(
        item,
        fit: BoxFit.cover,
      );
    } else {
      return Image.asset(
        AppAssets.heroBg,
        fit: BoxFit.cover,
      );
    }
  }
  
  // Construction du contenu du slide
  List<Widget> _buildSlideContent(dynamic item) {
    if (item is Residence) {
      // Contenu pour une résidence
      final String locationText = item.location['city'] ?? 'Emplacement de choix';
      
      return [
        Text(
          item.title,
          style: TextStyle(
            fontSize: context.responsiveFontSize(32),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 8),
        Text(
          item.description,
          style: TextStyle(
            fontSize: context.responsiveFontSize(18),
            color: Colors.white,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildFeatureChip(
              icon: Icons.location_on,
              text: locationText,
            ),
            const SizedBox(width: 8),
            _buildFeatureChip(
              icon: Icons.hotel,
              text: '${item.bedrooms} chambres',
            ),
            const SizedBox(width: 8),
            _buildFeatureChip(
              icon: Icons.monetization_on,
              text: _formatPrice(item.price),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            context.push('/residence/${item.id}');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Découvrir cette résidence',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ];
    } else {
      // Contenu par défaut
      return [
        Text(
          'Trouvez votre résidence idéale',
          style: TextStyle(
            fontSize: context.responsiveFontSize(32),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Des résidences de qualité pour tous vos besoins',
          style: TextStyle(
            fontSize: context.responsiveFontSize(18),
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
      ];
    }
  }

  // Construction d'un indicateur de point pour les slides
  Widget _buildDotIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: _currentIndex == index ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: _currentIndex == index 
            ? AppTheme.primaryColor 
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4.0),
      ),
    );
  }
  
  // Construction du bouton de navigation
  Widget _buildNavigationButton({
    required IconData icon, 
    required VoidCallback onPressed
  }) {
    return Opacity(
      opacity: 0.7,
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 20),
          onPressed: onPressed,
        ),
      ),
    );
  }
  
  // Construction de la barre de recherche
  Widget _buildSearchBar(BuildContext context) {
    return Center(
      child: Container(
        width: context.screenWidth * 0.8,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher une résidence...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(28),
              ),
              child: IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  // Implémenter la recherche
                  context.go('/residences', extra: {'search': 'query'});
                },
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 800.ms, delay: 500.ms)
      .slideY(begin: 0.2, end: 0, duration: 600.ms, delay: 500.ms, curve: Curves.easeOutQuad);
  }

  // Création d'une puce pour les caractéristiques de la résidence
  Widget _buildFeatureChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  // Formatage du prix
  String _formatPrice(num price) {
    return NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    ).format(price);
  }
}
