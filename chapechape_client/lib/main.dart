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
import 'package:chapechape_client/core/services/user_service.dart';
import 'package:chapechape_client/core/services/residence_service.dart';
import 'package:chapechape_client/core/services/notification_service.dart';
import 'package:chapechape_client/core/services/favorite_service.dart';
import 'package:chapechape_client/core/services/booking_service.dart';
import 'package:chapechape_client/core/repositories/chat_repository.dart';
import 'package:chapechape_client/core/repositories/notification_repository.dart';
import 'package:chapechape_client/core/repositories/favorite_repository.dart';
import 'dart:html' as html;
import 'package:chapechape_client/core/config/app_config.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser les configurations
  await AppConfig.initialize();
  
  // Initialiser Hive
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('cache');

  // Initialiser tous les services et repositories
  final authService = await AuthService.initialize();
  final chatRepository = await ChatRepository.initialize();
  final notificationRepository = await NotificationRepository.initialize();
  final favoriteRepository = await FavoriteRepository.initialize();
  final userService = await UserService.initialize();
  final residenceService = await ResidenceService.initialize();

  runApp(MyApp(
    services: AppServices(
      authService: authService,
      chatRepository: chatRepository,
      notificationRepository: notificationRepository,
      favoriteRepository: favoriteRepository,
      userService: userService,
      residenceService: residenceService,
    ),
  ));
}

// Classe pour regrouper tous les services
class AppServices {
  final AuthService authService;
  final ChatRepository chatRepository;
  final NotificationRepository notificationRepository;
  final FavoriteRepository favoriteRepository;
  final UserService userService;
  final ResidenceService residenceService;

  const AppServices({
    required this.authService,
    required this.chatRepository,
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
            chatService: services.chatRepository.chatService,
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