import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
import 'package:chapechape_client/core/services/booking_service.dart';
import 'package:chapechape_client/core/repositories/notification_repository.dart';
import 'package:chapechape_client/core/repositories/favorite_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' as ui;
import 'package:chapechape_client/core/config/app_config.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/router/app_router.dart';
import 'package:chapechape_client/core/blocs/booking/booking_bloc.dart';
import 'package:chapechape_client/core/services/payment_service.dart';
import 'package:chapechape_client/core/blocs/payment/payment_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser les configurations
  await AppConfig.initialize();
  
  // Initialiser Hive
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('cache');

  // Initialiser le service de cache
  final cacheService = await CacheService.initialize(
    defaultCacheDuration: const Duration(minutes: 10),
  );
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
    ),
  );
}

// Classe pour regrouper tous les services
class AppServices {
  final AuthService authService;
  final ChatService chatService;
  final NotificationRepository notificationRepository;
  final FavoriteRepository favoriteRepository;
  final UserService userService;
  final ResidenceService residenceService;

  const AppServices({
    required this.authService,
    required this.chatService,
    required this.notificationRepository,
    required this.favoriteRepository,
    required this.userService,
    required this.residenceService,
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