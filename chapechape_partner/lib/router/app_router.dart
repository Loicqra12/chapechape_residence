import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/blocs/auth/auth_bloc.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/main/main_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/residences/edit_residence_screen.dart';
import '../presentation/screens/splash/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRouter {
  final AuthBloc authBloc;
  final _prefs = SharedPreferences.getInstance();

  AppRouter(this.authBloc) {
    // Essayer de restaurer la session lors des hot reloads
    _tryRestoreSession();
  }

  Future<void> _tryRestoreSession() async {
    // Déclencher un petit délai pour s'assurer que tout est initialisé
    Future.delayed(const Duration(milliseconds: 100), () {
      // Réactiver la session si possible
      _checkPersistedAuth();
    });
  }

  Future<void> _checkPersistedAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token != null && token.isNotEmpty) {
        print("Session restaurée après hot reload");
      }
    } catch (e) {
      print("Erreur lors de la restauration de session: $e");
    }
  }

  late final router = GoRouter(
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/main',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/residences/add',
        builder: (context, state) => EditResidenceScreen(),
      ),
    ],
    redirect: (context, state) async {
      final isAuthenticated = authBloc.state is AuthAuthenticated;
      final isLoading = authBloc.state is AuthLoading;
      final isUnauthenticated = authBloc.state is AuthUnauthenticated;
      final isSplashScreen = state.matchedLocation == '/';
      final isAuthScreen = state.matchedLocation.startsWith('/auth');
      final isOnboardingScreen = state.matchedLocation == '/onboarding';

      // Si l'utilisateur accède au /home par erreur, rediriger vers /main
      if (state.matchedLocation.startsWith('/home')) {
        return '/main';
      }

      // Pendant le chargement, rester sur le splash screen
      if (isLoading && isSplashScreen) {
        return null;
      }

      // Ne pas interrompre le splash screen - le SplashScreen lui-même s'occupera de la redirection après 5 secondes
      if (isSplashScreen) {
        return null;
      }

      // Vérifier si l'onboarding a déjà été vu
      final prefs = await _prefs;
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

      // Si authentifié, rediriger vers main sauf si déjà sur main
      if (isAuthenticated && !state.matchedLocation.startsWith('/main')) {
        return '/main';
      }

      // Si non authentifié et pas sur un écran d'auth ou d'onboarding
      if (isUnauthenticated && !isAuthScreen && !isOnboardingScreen && !isSplashScreen) {
        // Si l'onboarding n'a pas été vu, rediriger vers l'onboarding
        if (!hasSeenOnboarding) {
          return '/onboarding';
        }
        return '/auth/login';
      }

      return null;
    },
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
