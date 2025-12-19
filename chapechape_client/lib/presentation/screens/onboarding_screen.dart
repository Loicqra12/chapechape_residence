import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chapechape_client/core/services/onboarding_service.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
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
                  child: const Text(
                    'Passer',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              // Image section
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 20),
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
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    )
                    .animate(key: ValueKey('title_$_currentPage'))
                    .fadeIn(duration: 500.ms, delay: 200.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuart),
                    
                    const SizedBox(height: 20),
                    
                    Text(
                      _pages[_currentPage]['description']!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
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
                margin: const EdgeInsets.only(bottom: 40),
                child: Column(
                  children: [
                    // Page indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? const Color(0xFFFFD700)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Next/Start button
                    SizedBox(
                      width: screenSize.width * 0.8,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          _currentPage < _pages.length - 1
                              ? 'Suivant'
                              : 'Commencer',
                          style: const TextStyle(
                            fontSize: 18,
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