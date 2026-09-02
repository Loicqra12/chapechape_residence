import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chapechape_client/presentation/screens/screens.dart'
    hide PaymentScreen, BookingHistoryScreen, BookingScreen;
import 'package:chapechape_client/presentation/screens/booking_screen.dart';
import 'package:chapechape_client/presentation/screens/auth/login_screen.dart';
import 'package:chapechape_client/presentation/screens/auth/register_screen.dart';
import 'package:chapechape_client/presentation/screens/auth/forgot_password_screen.dart';
import 'package:chapechape_client/presentation/screens/auth/reset_password_screen.dart';
import 'package:chapechape_client/presentation/screens/chat_conversation_screen.dart';
import 'package:chapechape_client/presentation/screens/payment_methods_screen.dart';
import '../core/models/chat_model.dart';
import '../core/services/chat_service.dart';
import '../core/services/api_service.dart';
import '../core/blocs/chat/chat_bloc.dart' as chat;
import '../core/blocs/auth/auth_bloc.dart';
import '../core/blocs/auth/auth_state.dart';
import '../presentation/screens/nearby_residences/nearby_residences_screen.dart';
import 'package:chapechape_client/presentation/screens/booking/booking_history_screen.dart'
    as booking;
import 'package:chapechape_client/presentation/screens/booking/booking_confirmation_screen.dart'
    as booking;
import 'package:chapechape_client/presentation/screens/booking/booking_details_screen.dart'
    as booking;
import 'package:chapechape_client/presentation/screens/booking/booking_status_screen.dart'
    as booking;
import 'package:chapechape_client/presentation/screens/booking/booking_modify_screen.dart'
    as booking;
import 'package:chapechape_client/presentation/screens/qr/qr_code_screen.dart';
import 'package:chapechape_client/presentation/screens/payment/payment_screen.dart'
    as payment;
import 'package:chapechape_client/presentation/screens/payment/payment_redirect_screen.dart';
import 'package:chapechape_client/presentation/screens/payment/payment_success_screen.dart';
import 'package:chapechape_client/presentation/screens/settings/temperature_screen.dart';
import 'package:chapechape_client/presentation/screens/settings/display_screen.dart';
import 'package:chapechape_client/presentation/screens/settings/about_screen.dart';
import 'package:chapechape_client/presentation/screens/settings/storage_screen.dart';
import 'package:chapechape_client/presentation/screens/settings_screen.dart';
import 'package:chapechape_client/presentation/screens/full_map_screen.dart';
import 'package:chapechape_client/presentation/screens/payment/payment_waiting_screen.dart';
import 'package:chapechape_client/presentation/screens/payment/payment_failed_screen.dart';
import 'package:chapechape_client/presentation/screens/payment/payment_history_screen.dart';
import 'package:chapechape_client/presentation/screens/search_criteria_screen.dart';

DateTime _parsePaymentWaitingExpiresAt(dynamic value) {
  if (value == null) {
    return DateTime.now().add(const Duration(minutes: 15));
  }
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ??
        DateTime.now().add(const Duration(minutes: 15));
  }
  return DateTime.now().add(const Duration(minutes: 15));
}

class AppRouter {
  static late final ApiService _apiService;
  static late final ChatService chatService;

  static StreamSubscription<Uri>? _deepLinkSubscription;

  static Future<void> initialize({
    required ChatService chatServiceInstance,
    required ApiService apiServiceInstance,
  }) async {
    chatService = chatServiceInstance;
    _apiService = apiServiceInstance;
  }

  /// Lance le listener deep link. À appeler une fois après initialize().
  static Future<void> initDeepLinks() async {
    final appLinks = AppLinks();

    // Lien initial : app lancée via deep link depuis un état fermé
    try {
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (_) {}

    // Liens entrants : app déjà ouverte
    _deepLinkSubscription = appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (_) {},
    );
  }

  static void _handleDeepLink(Uri uri) {
    // HTTPS : https://presentation.chapechaperesidence.com/reset-password/{token}
    // Custom scheme : chapechape://reset-password/{token}
    final isHttpsReset = (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.pathSegments.length >= 2 &&
        uri.pathSegments[0] == 'reset-password';

    final isCustomReset = uri.scheme == 'chapechape' &&
        uri.host == 'reset-password' &&
        uri.pathSegments.isNotEmpty;

    if (isHttpsReset) {
      final token = uri.pathSegments[1];
      if (token.isNotEmpty) {
        router.go('/reset-password/$token');
      }
    } else if (isCustomReset) {
      final token = uri.pathSegments[0];
      if (token.isNotEmpty) {
        router.go('/reset-password/$token');
      }
    }
  }

  static void dispose() {
    _deepLinkSubscription?.cancel();
  }

  // Helper pour vérifier si l'utilisateur est authentifié
  static bool _isAuthenticated(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    return authState is Authenticated;
  }

  // Rediriger vers la connexion avec une alerte
  static void _redirectToLogin(BuildContext context) {
    // Déplacer TOUTE la navigation après la phase de construction
    // pour éviter les erreurs "setState during build"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        // Navigation après la fin de la phase de construction
        context.go('/login');

        // Afficher un message explicatif
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Vous devez vous connecter pour accéder à cette fonctionnalité'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  static final router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true, // Activer les logs de diagnostic
    routes: [
      // Racine : l’app n’expose pas de page sur `/` (accueil = `/home` dans le ShellRoute).
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
      ),
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
        path: '/full-map',
        name: 'full-map',
        builder: (context, state) {
          final Map<String, dynamic> extra =
              state.extra as Map<String, dynamic>? ?? {};
          final centerLat = extra['centerLat'] ?? 0.0;
          final centerLng = extra['centerLng'] ?? 0.0;
          final title = extra['title'] as String?;
          final residenceId = extra['residenceId'] as String?;
          final radius = extra['radius'] as double? ?? 5.0;

          return FullMapScreen(
            centerLat: centerLat,
            centerLng: centerLng,
            title: title,
            residenceId: residenceId,
            searchRadius: radius, // Utilisation du rayon pour la recherche
          );
        },
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
      GoRoute(
        path: '/reset-password/:token',
        name: 'reset_password',
        builder: (context, state) => ResetPasswordScreen(
          token: state.pathParameters['token']!,
        ),
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
            path: '/nearby',
            name: 'nearby',
            builder: (context, state) => const NearbyResidencesScreen(),
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
                        return const Center(
                            child: Text(
                                'Erreur lors du chargement de la conversation'));
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
                redirect: (context, state) => '/profile/payments',
              ),
              GoRoute(
                path: 'payments',
                name: 'profile_payments',
                builder: (context, state) {
                  if (_isAuthenticated(context)) {
                    return const PaymentHistoryScreen();
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
                builder: (context, state) =>
                    const HelpSupportScreen(), // Accessible à tous
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
        path: '/map-fullscreen',
        name: 'map_fullscreen',
        builder: (context, state) {
          // Récupérer les paramètres de la carte en plein écran depuis extra
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            return const SizedBox(); // Redirection si pas de paramètres
          }

          return FullMapScreen(
            centerLat: extra['lat'] as double,
            centerLng: extra['lng'] as double,
            title: extra['title'] as String?,
            residenceId: extra['residenceId'] as String?,
          );
        },
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
        builder: (context, state) {
          final extra = state.extra;
          final searchParams = extra is Map<String, dynamic> ? extra : null;
          return SearchScreen(initialSearchParams: searchParams);
        },
      ),
      GoRoute(
        path: '/search-criteria',
        name: 'search_criteria',
        builder: (context, state) => const SearchCriteriaScreen(),
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
        builder: (context, state) => booking.BookingDetailsScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),
      GoRoute(
        path: '/booking-qr/:bookingId',
        name: 'booking_qr',
        builder: (context, state) => QRCodeScreen(
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
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return PaymentFailedScreen(
              paymentId: paymentId,
              transactionId: extra['transactionId'],
              method: extra['method'],
              phoneNumber: extra['phoneNumber'],
              amount: extra['amount'],
              reservationId: extra['reservationId'],
              failureReason: extra['failureReason'],
              isExpired: extra['isExpired'] ?? false,
            );
          } else {
            _redirectToLogin(context);
            return const SizedBox();
          }
        },
      ),
      GoRoute(
        path: '/payment-waiting',
        name: 'payment_waiting',
        builder: (context, state) {
          // Vérifier l'authentification
          if (_isAuthenticated(context)) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return PaymentWaitingScreen(
              method: extra['method']?.toString() ?? '',
              transactionId: extra['transactionId']?.toString() ?? '',
              paymentUrl: extra['paymentUrl']?.toString(),
              expiresAt: _parsePaymentWaitingExpiresAt(extra['expiresAt']),
              phoneNumber: extra['phoneNumber']?.toString(),
              reservationId: extra['reservationId']?.toString(),
              paymentId: extra['paymentId']?.toString(),
            );
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
      GoRoute(
        path: '/booking-rejected/:bookingId',
        name: 'booking_rejected',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'] ?? '';
          if (_isAuthenticated(context)) {
            return booking.BookingStatusScreen.rejected(
              bookingId: bookingId,
              onNewBooking: () => context.go('/search'),
              onBackToHome: () => context.go('/home'),
            );
          } else {
            _redirectToLogin(context);
            return const SizedBox();
          }
        },
      ),
      GoRoute(
        path: '/booking-expired/:bookingId',
        name: 'booking_expired',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'] ?? '';
          if (_isAuthenticated(context)) {
            return booking.BookingStatusScreen.expired(
              bookingId: bookingId,
              onNewBooking: () => context.go('/search'),
              onBackToHome: () => context.go('/home'),
            );
          } else {
            _redirectToLogin(context);
            return const SizedBox();
          }
        },
      ),
      GoRoute(
        path: '/booking-approved/:bookingId',
        name: 'booking_approved',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'] ?? '';
          if (_isAuthenticated(context)) {
            return booking.BookingStatusScreen.approved(
              bookingId: bookingId,
              onGoToPayment: () => context.go('/payment/$bookingId'),
              onViewDetails: () => context.go('/booking-details/$bookingId'),
            );
          } else {
            _redirectToLogin(context);
            return const SizedBox();
          }
        },
      ),
    ],
  );
}
