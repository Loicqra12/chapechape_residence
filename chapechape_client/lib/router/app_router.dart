import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chapechape_client/presentation/screens/screens.dart';
import 'package:chapechape_client/presentation/screens/auth/login_screen.dart';
import 'package:chapechape_client/presentation/screens/auth/register_screen.dart';
import 'package:chapechape_client/presentation/screens/auth/forgot_password_screen.dart';
import 'package:chapechape_client/presentation/screens/chat_conversation_screen.dart';

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
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot_password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/favorites',
            name: 'favorites',
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/chat',
            name: 'chat',
            builder: (context, state) => const ChatScreen(),
            routes: [
              GoRoute(
                path: 'conversation/:id',
                name: 'chat_conversation',
                builder: (context, state) => ChatConversationScreen(
                  conversationId: state.pathParameters['id']!,
                ),
              ),
            ],
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
        path: '/password-change',
        name: 'password_change',
        builder: (context, state) => const PasswordChangeScreen(),
      ),
    ],
  );
}