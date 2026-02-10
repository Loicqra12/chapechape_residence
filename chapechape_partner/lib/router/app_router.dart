import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/blocs/auth/auth_bloc.dart';
import '../core/blocs/reservation/reservation_bloc.dart';
import '../core/services/api/reservation_service.dart';
import '../core/models/residence/residence.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/main/main_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/residences/edit_residence_screen.dart';
import '../presentation/screens/residences/residence_details_screen.dart';
import '../presentation/screens/residences/residences_screen.dart';
import '../presentation/screens/reservations/reservation_details_screen.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/notifications/notification_settings_screen.dart';
import '../presentation/screens/notifications/notification_list_screen.dart';
import '../presentation/screens/payments/payouts/payouts.dart';
import '../presentation/screens/payments/payouts/payout_details_screen.dart';
import '../presentation/screens/payments/transactions/transactions.dart';
import '../presentation/screens/profile/edit_profile_screen.dart';
import '../presentation/screens/help/help_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Transition de page personnalisée avec fade + slide
CustomTransitionPage<T> buildPageWithTransition<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Fade + légère slide depuis la droite
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0), // Légère slide depuis la droite
            end: Offset.zero,
          ).animate(CurveTween(curve: Curves.easeOutCubic).animate(animation)),
          child: child,
        ),
      );
    },
  );
}

class AppRouter {
  final AuthBloc authBloc;

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
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/login',
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/register',
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/main',
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: const MainScreen(),
        ),
      ),
      GoRoute(
        path: '/residences/add',
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: EditResidenceScreen(),
        ),
      ),
      GoRoute(
        path: '/residences/details',
        pageBuilder: (context, state) {
          final residence = state.extra as Residence;
          return buildPageWithTransition(
            context: context,
            state: state,
            child: ResidenceDetailsScreen(residence: residence),
          );
        },
      ),
      GoRoute(
        path: '/residences',
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: const ResidencesScreen(),
        ),
      ),
      GoRoute(
        path: '/reservations/:id',
        pageBuilder: (context, state) {
          final reservationId = state.pathParameters['id'] ?? '';
          return buildPageWithTransition(
            context: context,
            state: state,
            child: ReservationDetailsScreen(reservationId: reservationId),
          );
        },
      ),
      GoRoute(
        path: '/profile/edit',
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: const EditProfileScreen(),
        ),
      ),
      GoRoute(
        path: '/messages/support',
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: HelpScreen.withBloc(context),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/notifications/preferences',
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: const NotificationSettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: const NotificationListScreen(),
        ),
      ),
      GoRoute(
        path: '/payouts',
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: PayoutHistoryScreen.withService(context),
        ),
      ),
      GoRoute(
        path: '/payouts/:id',
        pageBuilder: (context, state) {
          final payoutId = state.pathParameters['id'] ?? '';
          return buildPageWithTransition(
            context: context,
            state: state,
            child: PayoutDetailsScreen(payoutId: payoutId),
          );
        },
      ),
      GoRoute(
        path: '/transactions',
        pageBuilder: (context, state) => buildPageWithTransition(
          context: context,
          state: state,
          child: const TransactionsScreen(),
        ),
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
      final prefs = await SharedPreferences.getInstance();
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
