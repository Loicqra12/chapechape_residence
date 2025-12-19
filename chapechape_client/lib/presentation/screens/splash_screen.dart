import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chapechape_client/core/blocs/auth/auth_bloc.dart';
import 'package:chapechape_client/core/blocs/auth/auth_event.dart';
import 'package:chapechape_client/core/blocs/auth/auth_state.dart';
import 'package:chapechape_client/core/services/onboarding_service.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // Couleurs raffinées
  static const Color goldColor = Color(0xFFFFD700);
  static const Color darkGold = Color(0xFFCCAC00);
  static const Color orangeColor = Color(0xFFFF8C00);
  static const Color blackColor = Color(0xFF1A1A1A);

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();

    // Vérifier l'état d'authentification et l'onboarding
    try {
      // Attendre que l'animation soit terminée (max 2s)
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;

      // Vérifier l'authentification
      final authBloc = context.read<AuthBloc>();
      authBloc.add(const AuthCheckRequested());

      // Attendre la réponse de l'auth (max 500ms)
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      // Vérifier si l'onboarding a déjà été vu
      final hasSeenOnboarding = await OnboardingService.hasSeenOnboarding();
      final authState = authBloc.state;
      final isAuthenticated = authState is Authenticated;
      
      // Navigation intelligente
      if (!mounted) return;
      
      if (isAuthenticated) {
        // Utilisateur connecté → Aller directement à l'accueil
        context.go('/home');
      } else if (hasSeenOnboarding) {
        // Onboarding déjà vu → Aller à l'accueil
        context.go('/home');
      } else {
        // Premier lancement → Afficher l'onboarding
        context.go('/onboarding');
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation: $e');
      if (mounted) {
        // En cas d'erreur, vérifier l'onboarding pour décider
        final hasSeenOnboarding = await OnboardingService.hasSeenOnboarding();
        if (mounted) {
          if (hasSeenOnboarding) {
            context.go('/home');
          } else {
            context.go('/onboarding');
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blackColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: goldColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/logos/splash_logo.png',
                        width: 180,
                        height: 180,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Votre résidence idéale vous attend',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}