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
      'image': 'assets/images/onboarding/search.png',
      'title': 'Recherchez facilement',
      'description': 'Trouvez la résidence de vos rêves en quelques clics',
    },
    {
      'image': 'assets/images/onboarding/book.png',
      'title': 'Réservez en toute simplicité',
      'description': 'Un processus de réservation rapide et sécurisé',
    },
    {
      'image': 'assets/images/onboarding/enjoy.png',
      'title': 'Profitez de votre séjour',
      'description': 'Vivez une expérience unique dans nos résidences',
    },
  ];

  void _nextPage() async {
    if (_currentPage < _pages.length - 1) {
      setState(() {
        _currentPage++;
      });
    } else {
      // Marquer l'onboarding comme vu avant de naviguer
      await OnboardingService.markOnboardingAsSeen();
      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md + AppSpacing.xs),
          child: Column(
            children: [
              AppSpacing.verticalXl,
              // Skip button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    // Marquer l'onboarding comme vu même si on passe
                    await OnboardingService.markOnboardingAsSeen();
                    if (mounted) {
                      context.go('/home');
                    }
                  },
                  child: Text(
                    'Passer',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              // Image section
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
              // Text section
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      _pages[_currentPage]['title']!,
                      style: AppTextStyles.headline.copyWith(
                        color: AppTheme.textPrimary,
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
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    )
                    .animate(key: ValueKey('desc_$_currentPage'))
                    .fadeIn(duration: 500.ms, delay: 400.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuart),
                  ],
                ),
              ),
              // Bottom section with indicators and button
              Container(
                margin: EdgeInsets.only(bottom: AppSpacing.xl),
                child: Column(
                  children: [
                    // Page indicators
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
                            borderRadius: BorderRadius.circular(AppSpacing.xs),
                          ),
                        ),
                      ),
                    ),
                    AppSpacing.verticalLg,
                    // Next/Start button
                    SizedBox(
                      width: screenSize.width * 0.8,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXl + AppSpacing.smd),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          _currentPage < _pages.length - 1
                              ? 'Suivant'
                              : 'Commencer',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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