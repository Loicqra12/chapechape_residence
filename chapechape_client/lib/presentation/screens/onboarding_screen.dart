import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chapechape_client/core/services/onboarding_service.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/core/theme/text_styles.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/images/onboarding/onboarding-1.png',
      'title': 'Trouvez votre résidence idéale',
      'description': 'Découvrez des résidences autour de vous\ngrâce à la carte interactive.',
    },
    {
      'image': 'assets/images/onboarding/onboarding-2.png',
      'title': 'Réservez en quelques secondes',
      'description': 'Choisissez votre logement et confirmez\nvotre réservation en un instant.',
    },
    {
      'image': 'assets/images/onboarding/onboarding-3.png',
      'title': 'Restez le temps que vous voulez',
      'description': 'Réservez par heure, par jour ou par mois\nselon votre séjour.',
    },
  ];

  void _goBack() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _nextPage() async {
    if (_currentPage < _pages.length - 1) {
      setState(() {
        _currentPage++;
      });
    } else {
      await OnboardingService.markOnboardingAsSeen();
      if (mounted) {
        context.go('/home');
      }
    }
  }

  /// Anneau dégradé or : plus on avance (page 0→1→2), plus l'intensité augmente
  List<Color> _ringGradientColors() {
    switch (_currentPage) {
      case 0:
        return [AppTheme.lightGold, AppTheme.primaryColor.withOpacity(0.6)];
      case 1:
        return [AppTheme.lightGold, AppTheme.primaryColor, AppTheme.secondaryColor];
      default:
        return [AppTheme.secondaryColor, AppTheme.primaryColor, AppTheme.darkGold];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md + AppSpacing.xs),
          child: Column(
            children: [
              // ----- HAUT : Retour + Passer -----
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: Theme.of(context).colorScheme.onSurface,
                      onPressed: _currentPage == 0
                          ? null
                          : _goBack,
                    ),
                    IntrinsicWidth(
                      child: TextButton(
                        onPressed: () async {
                          await OnboardingService.markOnboardingAsSeen();
                          if (mounted) context.go('/home');
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Passer',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ----- Contenu : image + texte -----
              Expanded(
                flex: 3,
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: AppSpacing.md + AppSpacing.xs),
                  child: Image.asset(
                    _pages[_currentPage]['image']!,
                    key: ValueKey('image_$_currentPage'),
                    fit: BoxFit.contain,
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideX(begin: 0.2, end: 0, curve: Curves.easeOutQuart),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      _pages[_currentPage]['title']!,
                      style: AppTextStyles.headline.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate(key: ValueKey('title_$_currentPage'))
                        .fadeIn(duration: 500.ms, delay: 200.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuart),
                    AppSpacing.verticalMd,
                    Text(
                      _pages[_currentPage]['description']!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            height: 1.5,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                        .animate(key: ValueKey('desc_$_currentPage'))
                        .fadeIn(duration: 500.ms, delay: 400.ms)
                        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuart),
                  ],
                ),
              ),
              // ----- BAS : indicateurs + bouton circulaire (style capture 1) -----
              Container(
                margin: EdgeInsets.only(bottom: AppSpacing.xl),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? AppTheme.primaryColor
                                : AppTheme.dividerColor,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _nextPage,
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Anneau dégradé (plus on passe, plus il s'augmente / s'intensifie)
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: _ringGradientColors(),
                                  startAngle: 0,
                                  endAngle: 2 * 3.14159,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.25),
                                    blurRadius: 12,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                            ),
                            // Cercle intérieur (bord blanc pour effet anneau)
                            Container(
                              width: 66,
                              height: 66,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                            // Cercle principal + icône (code couleur or)
                            Container(
                              width: 58,
                              height: 58,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryColor,
                              ),
                              child: Icon(
                                isLastPage ? Icons.check_rounded : Icons.arrow_forward_ios_rounded,
                                color: Colors.black,
                                size: isLastPage ? 28 : 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
