import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chapechape_client/presentation/screens/screens.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/residence/:id',
        name: 'residence_details',
        builder: (context, state) => ResidenceDetailsScreen(
          residenceId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/booking/:residenceId',
        name: 'booking',
        builder: (context, state) => BookingScreen(
          residenceId: state.pathParameters['residenceId']!,
        ),
      ),
      GoRoute(
        path: '/payment/:bookingId',
        name: 'payment',
        builder: (context, state) => PaymentScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/bookings',
        name: 'bookings',
        builder: (context, state) => const BookingHistoryScreen(),
      ),
      GoRoute(
        path: '/reviews/:residenceId',
        name: 'reviews',
        builder: (context, state) => ReviewsScreen(
          residenceId: state.pathParameters['residenceId']!,
        ),
      ),
      GoRoute(
        path: '/help',
        name: 'help',
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: '/faq',
        name: 'faq',
        builder: (context, state) => const FaqScreen(),
      ),
    ],
  );
}