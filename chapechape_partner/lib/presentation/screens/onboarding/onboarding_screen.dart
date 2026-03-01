import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/onboarding_service.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/theme/colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Gère tes logements en toute simplicité',
      description:
          'Ajoute et gère tes logements facilement. Publie ton bien en quelques clics et commence à recevoir des réservations.',
      imagePath: AppImages.onboarding1,
    ),
    OnboardingPage(
      title: 'Choisis la durée qui t’arrange',
      description:
          'Choisis la durée de location. Adapte ton offre selon tes besoins : heure, jour ou mois.',
      imagePath: AppImages.onboarding2,
    ),
    OnboardingPage(
      title: 'Fais travailler tes logements pour toi',
      description:
          'Gagne de l’argent facilement. Les clients proches trouvent ton logement grâce à la géolocalisation.',
      imagePath: AppImages.onboarding3,
    ),
  ];

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _onSkip() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingService = OnboardingService(prefs);
    await onboardingService.completeOnboarding();
    if (mounted) {
      context.go('/auth/login');
    }
  }

  Future<void> _onDone() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingService = OnboardingService(prefs);
    await onboardingService.completeOnboarding();
    if (mounted) {
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Top bar légère (flèche retour + Passer)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: AppColors.textPrimary,
                    onPressed: _currentPage == 0
                        ? null
                        : () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                  ),
                  TextButton(
                    onPressed: _onSkip,
                    child: const Text('Passer'),
                  ),
                ],
              ),
            ),
          ),
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return OnboardingPageWidget(page: _pages[index]);
            },
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicateurs de page
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 18 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: _currentPage == index
                            ? const Color(0xFF7C4DFF) // violet actif
                            : const Color(0xFFE0D7FF), // violet très clair
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Bouton rond central avec halo
                GestureDetector(
                  onTap: () {
                    if (_currentPage == _pages.length - 1) {
                      _onDone();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF7C4DFF),
                        width: 3,
                      ),
                      color: Colors.transparent,
                    ),
                    child: Center(
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Icon(
                          _currentPage == _pages.length - 1
                              ? Icons.check
                              : Icons.arrow_forward_ios_rounded,
                          color: const Color(0xFF7C4DFF),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String imagePath;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;

  const OnboardingPageWidget({
    super.key,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Semantics(
            label: page.title,
            image: true,
            child: Image.asset(
              page.imagePath,
              height: 300,
              fit: BoxFit.contain,
              semanticLabel: page.title,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
