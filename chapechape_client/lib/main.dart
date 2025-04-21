import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:chapechape_client/core/blocs/auth/auth_bloc.dart';
import 'package:chapechape_client/core/blocs/auth/auth_event.dart';
import 'package:chapechape_client/core/blocs/locale/locale_cubit.dart';
import 'package:chapechape_client/core/blocs/locale/locale_state.dart';
import 'package:chapechape_client/core/blocs/residence/residence_bloc.dart';
import 'package:chapechape_client/core/blocs/chat/chat_bloc.dart';
import 'package:chapechape_client/core/blocs/user/user_bloc.dart';
import 'package:chapechape_client/core/blocs/notification/notification_bloc.dart';
import 'package:chapechape_client/core/blocs/favorite/favorite_bloc.dart';
import 'package:chapechape_client/core/services/auth_service.dart';
import 'package:chapechape_client/core/services/chat_service.dart';
import 'package:chapechape_client/core/services/api_service.dart';
import 'package:chapechape_client/core/services/cache_service.dart';
import 'package:chapechape_client/core/services/user_service.dart';
import 'package:chapechape_client/core/services/residence_service.dart';
import 'package:chapechape_client/core/services/notification_service.dart';
import 'package:chapechape_client/core/services/favorite_service.dart';
import 'package:chapechape_client/core/services/currency_service.dart';
import 'package:chapechape_client/core/services/exchange_rate_service.dart';
import 'package:chapechape_client/core/services/booking_service.dart';
import 'package:chapechape_client/core/services/payment_service.dart';
import 'package:chapechape_client/core/services/type_sync_service.dart';
import 'package:chapechape_client/core/repositories/notification_repository.dart';
import 'package:chapechape_client/core/repositories/favorite_repository.dart';
import 'dart:ui' as ui;
import 'package:chapechape_client/core/config/app_config.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/router/app_router.dart';
import 'package:chapechape_client/core/blocs/booking/booking_bloc.dart';
import 'package:chapechape_client/core/blocs/payment/payment_bloc.dart';
import 'core/service_locator.dart';

void main() async {
  // Assurer que les liaisons Flutter sont initialisées
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser les configurations
  await AppConfig.initialize();
  debugPrint('✅ Configuration de l\'application initialisée avec succès');
  
  // Configurer le service locator (GetIt)
  await setupServiceLocator();
  debugPrint('✅ Service locator initialisé avec succès');
  
  // Initialiser les services
  await _initializeServices();
  
  // Initialiser Hive
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('cache');

  // Initialiser le service de cache
  await CacheService.initialize();
  debugPrint('✅ Service de cache initialisé avec succès');

  // Initialiser tous les services et repositories
  final authService = await AuthService.initialize();
  final apiService = await ApiService.initialize();
  final chatService = ChatService(apiService: apiService);
  final notificationRepository = await NotificationRepository.initialize();
  final favoriteRepository = await FavoriteRepository.initialize();
  final userService = await UserService.initialize();
  final residenceService = await ResidenceService.initialize();
  final bookingService = await BookingService.initialize();
  final paymentService = await PaymentService.initialize();
  final typeSyncService = await TypeSyncService.initialize();

  // Initialiser le router avec les services nécessaires
  await AppRouter.initialize(
    chatServiceInstance: chatService,
    apiServiceInstance: apiService,
  );

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authService: authService,
          )..add(AuthCheckRequested()),
        ),
        BlocProvider<LocaleCubit>(
          create: (context) => LocaleCubit(
            defaultLocale: const Locale('fr'), // Utiliser une valeur par défaut directe
          ),
        ),
        BlocProvider<ResidenceBloc>(
          create: (context) => ResidenceBloc(
            residenceService: residenceService,
            favoriteService: favoriteRepository.favoriteService,
            typeSyncService: typeSyncService,
          ),
        ),
        BlocProvider<ChatBloc>(
          create: (context) => ChatBloc(
            chatService: chatService,
          ),
        ),
        BlocProvider<UserBloc>(
          create: (context) => UserBloc(
            userService: userService,
          ),
        ),
        BlocProvider<NotificationBloc>(
          create: (context) => NotificationBloc(
            notificationRepository: notificationRepository,
          ),
        ),
        BlocProvider<FavoriteBloc>(
          create: (context) => FavoriteBloc(
            favoriteRepository: favoriteRepository,
          ),
        ),
        BlocProvider<BookingBloc>(
          create: (context) => BookingBloc(
            bookingService: bookingService,
          ),
        ),
        BlocProvider<PaymentBloc>(
          create: (context) => PaymentBloc(
            paymentService: paymentService,
          ),
        ),
      ],
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, localeState) {
          return FlutterEasyLoading(
            child: MaterialApp.router(
              title: AppConfig.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.system,
              locale: localeState?.locale ?? const Locale('fr'),
              routerConfig: AppRouter.router,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('fr', ''),
                Locale('en', ''),
              ],
              builder: EasyLoading.init(), // Initialiser EasyLoading
            ),
          );
        }
      ),
    ),
  );
  
  // Configurer EasyLoading avec un style moderne
  _configureEasyLoading();
}

/// Initialise tous les services nécessaires au démarrage de l'application
Future<void> _initializeServices() async {
  try {
    // Initialiser le service de taux de change
    final exchangeService = ExchangeRateService();
    await exchangeService.initialize();
    
    // Initialiser le service de devises
    final currencyService = CurrencyService();
    await currencyService.initialize();
    
    print('Services de devises initialisés avec succès');
  } catch (e) {
    print('Erreur lors de l\'initialisation des services de devises: $e');
  }
}

/// Configure l'apparence et le comportement de Flutter EasyLoading
void _configureEasyLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = const Color(0xFFFFD700) // Gold
    ..backgroundColor = Colors.white
    ..indicatorColor = const Color(0xFFFFD700) // Gold
    ..textColor = Colors.black
    ..maskColor = Colors.black.withOpacity(0.5)
    ..userInteractions = false
    ..dismissOnTap = false
    ..toastPosition = EasyLoadingToastPosition.bottom;
}

// Classe pour regrouper tous les services
class AppServices {
  final AuthService authService;
  final ChatService chatService;
  final NotificationRepository notificationRepository;
  final FavoriteRepository favoriteRepository;
  final UserService userService;
  final ResidenceService residenceService;
  final TypeSyncService typeSyncService;

  const AppServices({
    required this.authService,
    required this.chatService,
    required this.notificationRepository,
    required this.favoriteRepository,
    required this.userService,
    required this.residenceService,
    required this.typeSyncService,
  });
}

class MyApp extends StatelessWidget {
  final AppServices services;
  
  const MyApp({
    Key? key,
    required this.services,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authService: services.authService,
          )..add(AuthCheckRequested()),
        ),
        BlocProvider<LocaleCubit>(
          create: (context) => LocaleCubit(
            defaultLocale: const Locale('fr'), // Utiliser une valeur par défaut directe
          ),
        ),
        BlocProvider<ResidenceBloc>(
          create: (context) => ResidenceBloc(
            residenceService: services.residenceService,
            favoriteService: services.favoriteRepository.favoriteService,
            typeSyncService: services.typeSyncService,
          ),
        ),
        BlocProvider<ChatBloc>(
          create: (context) => ChatBloc(
            chatService: services.chatService,
          ),
        ),
        BlocProvider<UserBloc>(
          create: (context) => UserBloc(
            userService: services.userService,
          ),
        ),
        BlocProvider<NotificationBloc>(
          create: (context) => NotificationBloc(
            notificationRepository: services.notificationRepository,
          ),
        ),
        BlocProvider<FavoriteBloc>(
          create: (context) => FavoriteBloc(
            favoriteRepository: services.favoriteRepository,
          ),
        ),
      ],
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, localeState) {
          return MaterialApp.router(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            locale: localeState?.locale ?? const Locale('fr'),
            routerConfig: AppRouter.router,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('fr', ''),
              Locale('en', ''),
            ],
          );
        }
      ),
    );
  }
}