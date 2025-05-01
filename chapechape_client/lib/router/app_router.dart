import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chapechape_client/presentation/screens/screens.dart' 
    hide PaymentScreen, BookingHistoryScreen, BookingScreen;
import 'package:chapechape_client/presentation/screens/booking_screen.dart';
import 'package:chapechape_client/presentation/screens/auth/login_screen.dart';
import 'package:chapechape_client/presentation/screens/auth/register_screen.dart';
import 'package:chapechape_client/presentation/screens/auth/forgot_password_screen.dart';
import 'package:chapechape_client/presentation/screens/chat_conversation_screen.dart';
import 'package:chapechape_client/presentation/screens/wallet_screen.dart';
import 'package:chapechape_client/presentation/screens/payment_methods_screen.dart';
import '../core/models/chat_model.dart';
import '../core/services/chat_service.dart';
import '../core/services/api_service.dart';
import '../core/blocs/chat/chat_bloc.dart' as chat;
import '../core/blocs/auth/auth_bloc.dart';
import '../core/blocs/auth/auth_state.dart';
import 'package:chapechape_client/presentation/screens/booking/booking_history_screen.dart' as booking;
import 'package:chapechape_client/presentation/screens/booking/booking_confirmation_screen.dart' as booking;
import 'package:chapechape_client/presentation/screens/booking/booking_modify_screen.dart' as booking;
import 'package:chapechape_client/presentation/screens/payment/payment_screen.dart' as payment;
import 'package:chapechape_client/presentation/screens/payment/payment_redirect_screen.dart';
import 'package:chapechape_client/presentation/screens/payment/payment_success_screen.dart';
import 'package:chapechape_client/presentation/screens/settings/temperature_screen.dart';
import 'package:chapechape_client/presentation/screens/settings/display_screen.dart';
import 'package:chapechape_client/presentation/screens/settings/about_screen.dart';
import 'package:chapechape_client/presentation/screens/settings/storage_screen.dart';

class AppRouter {
  static late final ApiService _apiService;
  static late final ChatService chatService;

  static Future<void> initialize({
    required ChatService chatServiceInstance,
    required ApiService apiServiceInstance,
  }) async {
    chatService = chatServiceInstance;
    _apiService = apiServiceInstance;
  }

  // Helper pour vérifier si l'utilisateur est authentifié
  static bool _isAuthenticated(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    return authState is Authenticated;
  }

  // Rediriger vers la connexion avec une alerte
  static void _redirectToLogin(BuildContext context) {
    // D'abord rediriger vers la page de connexion
    context.go('/login');
    
    // Puis afficher le SnackBar après la fin de la construction
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez vous connecter pour accéder à cette fonctionnalité'),
          duration: Duration(seconds: 3),
        ),
      );
    });
  }

  static final router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,  // Activer les logs de diagnostic
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
            builder: (context, state) {
              // Vérifier l'authentification pour les favoris
              if (_isAuthenticated(context)) {
                return const FavoritesScreen();
              } else {
                _redirectToLogin(context);
                return const SizedBox(); // Ne sera jamais affiché grâce à la redirection
              }
            },
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) {
              // Vérifier l'authentification pour les notifications
              if (_isAuthenticated(context)) {
                return const NotificationsScreen();
              } else {
                _redirectToLogin(context);
                return const SizedBox();
              }
            },
          ),
          GoRoute(
            path: '/chat',
            name: 'chat',
            builder: (context, state) {
              // Vérifier l'authentification pour le chat
              if (_isAuthenticated(context)) {
                return ChatScreen(
              chatService: chatService,
              apiService: _apiService,
                );
              } else {
                _redirectToLogin(context);
                return const SizedBox();
              }
            },
            routes: [
              GoRoute(
                path: 'conversation/:id',
                name: 'chat_conversation',
                builder: (context, state) {
                  // Vérifier l'authentification pour une conversation
                  if (!_isAuthenticated(context)) {
                    _redirectToLogin(context);
                    return const SizedBox();
                  }
                  
                  final id = state.pathParameters['id']!;
                  
                  // Charger la conversation à partir de son ID
                  return FutureBuilder<ChatConversation>(
                    future: chatService.getConversation(id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasError || !snapshot.hasData) {
                        return const Center(child: Text('Erreur lors du chargement de la conversation'));
                      }
                      
                      final conversation = snapshot.data!;
                      
                      // Fournir le ChatBloc pour cet écran
                      return BlocProvider(
                        create: (context) {
                          final bloc = chat.ChatBloc(chatService: chatService);
                          // Charger immédiatement les messages pour cette conversation
                          bloc.add(chat.LoadMessages(conversationId: id));
                          return bloc;
                        },
                        child: ChatConversationScreen(
                    conversation: conversation,
                    chatService: chatService,
                    apiService: _apiService,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) {
              // Vérifier l'authentification pour le profil
              if (_isAuthenticated(context)) {
                return const ProfileScreen();
              } else {
                _redirectToLogin(context);
                return const SizedBox();
              }
            },
            routes: [
              GoRoute(
                path: 'settings',
                name: 'settings',
                builder: (context, state) {
                  // Vérifier l'authentification pour les paramètres
                  if (_isAuthenticated(context)) {
                    return const SettingsScreen();
                  } else {
                    _redirectToLogin(context);
                    return const SizedBox();
                  }
                },
                routes: [
                  GoRoute(
                    path: 'temperature',
                    name: 'temperature',
                    builder: (context, state) {
                      if (_isAuthenticated(context)) {
                        return const TemperatureScreen();
                      } else {
                        _redirectToLogin(context);
                        return const SizedBox();
                      }
                    },
                  ),
                  GoRoute(
                    path: 'display',
                    name: 'display',
                    builder: (context, state) {
                      if (_isAuthenticated(context)) {
                        return const DisplayScreen();
                      } else {
                        _redirectToLogin(context);
                        return const SizedBox();
                      }
                    },
                  ),
                  GoRoute(
                    path: 'about',
                    name: 'about',
                    builder: (context, state) {
                      if (_isAuthenticated(context)) {
                        return const AboutScreen();
                      } else {
                        _redirectToLogin(context);
                        return const SizedBox();
                      }
                    },
                  ),
                  GoRoute(
                    path: 'storage',
                    name: 'storage',
                    builder: (context, state) {
                      if (_isAuthenticated(context)) {
                        return const StorageScreen();
                      } else {
                        _redirectToLogin(context);
                        return const SizedBox();
                      }
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'wallet',
                name: 'wallet',
                builder: (context, state) {
                  // Vérifier l'authentification pour le portefeuille
                  if (_isAuthenticated(context)) {
                    return const WalletScreen();
                  } else {
                    _redirectToLogin(context);
                    return const SizedBox();
                  }
                },
              ),
              GoRoute(
                path: 'payment-methods',
                name: 'payment_methods',
                builder: (context, state) {
                  // Vérifier l'authentification pour les moyens de paiement
                  if (_isAuthenticated(context)) {
                    return const PaymentMethodsScreen();
                  } else {
                    _redirectToLogin(context);
                    return const SizedBox();
                  }
                },
              ),
              GoRoute(
                path: 'help',
                name: 'help',
                builder: (context, state) => const HelpSupportScreen(), // Accessible à tous
              ),
            ],
          ),
          GoRoute(
            path: '/bookings',
            name: 'bookings',
            builder: (context, state) => const booking.BookingHistoryScreen(),
          ),
          GoRoute(
            path: '/reviews/:residenceId',
            name: 'reviews',
            builder: (context, state) {
              // Les avis peuvent être vus sans connexion
              return ReviewsScreen(
              residenceId: state.pathParameters['residenceId']!,
              );
            },
          ),
          GoRoute(
            path: '/faq',
            name: 'faq',
            builder: (context, state) => const FaqScreen(), // Accessible à tous
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
        path: '/residences/:id',
        name: 'residence_details_alt',
        redirect: (context, state) {
          final id = state.pathParameters['id'];
          return '/residence/$id';
        },
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(), // Accessible à tous
      ),
      GoRoute(
        path: '/make-reservation/:id',
        name: 'make_reservation',
        builder: (context, state) {
          // Vérifier l'authentification pour la réservation
          if (_isAuthenticated(context)) {
            // Récupérer directement le paramètre
            final residenceId = state.pathParameters['id'];
            
            // Utiliser simplement BookingScreen sans qualifier avec un namespace particulier
            return BookingScreen(
              residenceId: residenceId ?? '',
            );
          } else {
            _redirectToLogin(context);
            return const SizedBox();
          }
        },
      ),
      GoRoute(
        path: '/payment/:reservationId',
        name: 'payment_booking',
        builder: (context, state) => payment.PaymentScreen(
          reservationId: state.pathParameters['reservationId']!,
        ),
      ),
      GoRoute(
        path: '/password-change',
        name: 'password_change',
        builder: (context, state) {
          // Vérifier l'authentification pour le changement de mot de passe
          if (_isAuthenticated(context)) {
            return const PasswordChangeScreen();
          } else {
            _redirectToLogin(context);
            return const SizedBox();
          }
        },
      ),
      GoRoute(
        path: '/booking-confirmation/:bookingId',
        name: 'booking_confirmation',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'] ?? '';
          // Vérifier l'authentification
          if (_isAuthenticated(context)) {
            return booking.BookingConfirmationScreen(bookingId: bookingId);
          } else {
            _redirectToLogin(context);
            return const SizedBox();
          }
        },
      ),
      GoRoute(
        path: '/booking-details/:bookingId',
        name: 'booking_details',
        builder: (context, state) => booking.BookingConfirmationScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),
      GoRoute(
        path: '/payment/:paymentId',
        name: 'payment',
        builder: (context, state) {
          final paymentId = state.pathParameters['paymentId'] ?? '';
          // Vérifier l'authentification
          if (_isAuthenticated(context)) {
            return payment.PaymentScreen(paymentId: paymentId);
          } else {
            _redirectToLogin(context);
            return const SizedBox();
          }
        },
      ),
      GoRoute(
        path: '/payment-redirect/:paymentId',
        name: 'payment_redirect',
        builder: (context, state) {
          final paymentId = state.pathParameters['paymentId'] ?? '';
          // Vérifier l'authentification
          if (_isAuthenticated(context)) {
            return PaymentRedirectScreen(paymentId: paymentId);
          } else {
            _redirectToLogin(context);
            return const SizedBox();
          }
        },
      ),
      GoRoute(
        path: '/payment-success/:paymentId',
        name: 'payment_success',
        builder: (context, state) {
          final paymentId = state.pathParameters['paymentId'] ?? '';
          // Vérifier l'authentification
          if (_isAuthenticated(context)) {
            return PaymentSuccessScreen(paymentId: paymentId);
          } else {
            _redirectToLogin(context);
            return const SizedBox();
          }
        },
      ),
      GoRoute(
        path: '/payment-pending/:paymentId',
        name: 'payment_pending',
        builder: (context, state) {
          final paymentId = state.pathParameters['paymentId'] ?? '';
          // Vérifier l'authentification
          if (_isAuthenticated(context)) {
            // Vous pouvez créer un écran spécifique pour les paiements en attente
            // ou réutiliser l'écran de redirection
            return PaymentRedirectScreen(paymentId: paymentId);
          } else {
            _redirectToLogin(context);
            return const SizedBox();
          }
        },
      ),
      GoRoute(
        path: '/payment-failed/:paymentId',
        name: 'payment_failed',
        builder: (context, state) {
          final paymentId = state.pathParameters['paymentId'] ?? '';
          // Vérifier l'authentification
          if (_isAuthenticated(context)) {
            // Vous pouvez créer un écran spécifique pour les échecs de paiement
            return PaymentRedirectScreen(paymentId: paymentId); // À remplacer par votre écran d'échec
          } else {
            _redirectToLogin(context);
            return const SizedBox();
          }
        },
      ),
      GoRoute(
        path: '/booking-payment/:bookingId',
        name: 'booking_payment',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'] ?? '';
          // Vérifier l'authentification
          if (_isAuthenticated(context)) {
            // Cette route pourrait rediriger vers l'écran de confirmation où l'utilisateur
            // peut choisir de payer
            return booking.BookingConfirmationScreen(bookingId: bookingId);
          } else {
            _redirectToLogin(context);
            return const SizedBox();
          }
        },
      ),
      GoRoute(
        path: '/booking-modify/:bookingId',
        name: 'booking_modify',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'] ?? '';
          // Vérifier l'authentification
          if (_isAuthenticated(context)) {
            return booking.BookingModifyScreen(bookingId: bookingId);
          } else {
            _redirectToLogin(context);
            return const SizedBox();
          }
        },
      ),
    ],
  );
}