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

  AppRouter(this.authBloc);

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

      // Pendant le chargement, rester sur le splash screen
      if (isLoading && isSplashScreen) {
        return null;
      }

      // Vérifier si l'onboarding a déjà été vu
      final prefs = await _prefs;
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

      // Si on est sur le splash screen et qu'on n'est plus en chargement
      if (isSplashScreen && !isLoading) {
        if (isAuthenticated) {
          return '/main';
        }
        // Si l'onboarding n'a pas été vu, rediriger vers l'onboarding
        if (!hasSeenOnboarding) {
          return '/onboarding';
        }
        return '/auth/login';
      }

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
