import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import 'carousel_widget.dart';

class HomeBannerCarousel extends StatefulWidget {
  final BoxConstraints constraints;
  
  const HomeBannerCarousel({
    Key? key,
    required this.constraints,
  }) : super(key: key);

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  final List<Map<String, dynamic>> _bannerItems = [
    {
      'background': 'assets/images/backgrounds/hero_bg.png',
      'title': 'Trouvez votre résidence idéale',
      'subtitle': 'Des milliers de résidences vous attendent',
      'color': AppTheme.primaryColor,
    },
    {
      'background': 'assets/images/residences/premium1.png',
      'title': 'Résidences de luxe',
      'subtitle': 'Découvrez notre sélection exclusive',
      'color': Colors.amber[800]!,
    },
    {
      'background': 'assets/images/residences/promo1.png',
      'title': 'Offres spéciales',
      'subtitle': 'Jusqu\'à 30% de réduction sur des résidences sélectionnées',
      'color': Colors.green[700]!,
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Démarrer l'animation dès l'initialisation
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      height: 220,
      child: CarouselWidget(
        height: 220,
        autoPlayInterval: const Duration(seconds: 5),
        animationDuration: const Duration(milliseconds: 800),
        items: _bannerItems.map((item) => _buildBannerItem(item)).toList(),
      ),
    );
  }
  
  Widget _buildBannerItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        image: DecorationImage(
          image: AssetImage(item['background']),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.4),
            BlendMode.darken,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              item['color'].withOpacity(0.7),
              item['color'].withOpacity(0.3),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              item['title'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            )
            .animate(controller: _animationController)
            .fadeIn(duration: 800.ms, curve: Curves.easeOutQuad)
            .slideY(begin: 0.2, end: 0, duration: 800.ms, curve: Curves.easeOutQuad),
            
            const SizedBox(height: 12),
            
            Text(
              item['subtitle'],
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            )
            .animate(controller: _animationController)
            .fadeIn(delay: 300.ms, duration: 800.ms, curve: Curves.easeOutQuad)
            .slideY(begin: 0.2, end: 0, delay: 300.ms, duration: 800.ms),
          ],
        ),
      ),
    );
  }
}
