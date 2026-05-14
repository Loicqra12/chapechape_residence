import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:intl/date_symbol_data_local.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/config/api_config.dart';
import 'core/config/app_config_manager.dart';
import 'core/theme/app_theme.dart';
import 'core/config/environment.dart';
import 'core/services/api/api_service.dart';
import 'core/services/api/auth_service.dart';
import 'core/services/api/residence_service.dart';
import 'core/services/api/dashboard_service.dart';
import 'core/services/api/message_service.dart';
import 'core/services/api/reservation_service.dart';
// import 'core/services/api/notification_service.dart'; // Non utilisé
import 'core/services/onesignal_service.dart';
import 'core/blocs/auth/auth_bloc.dart';
import 'core/blocs/residence/residence_bloc.dart';
import 'core/blocs/dashboard/dashboard_bloc.dart';
import 'core/blocs/message/message_bloc.dart';
import 'core/blocs/reservation/reservation_bloc.dart';
import 'core/blocs/sync/sync_bloc.dart';
import 'core/blocs/notification/notification_bloc.dart';
import 'core/blocs/notification/notification_event.dart';
import 'core/repositories/notification_repository.dart';
import 'router/app_router.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/cache_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/offline_queue_service.dart';
import 'core/services/offline_payment_service.dart';
import 'core/services/event_bus/residence_event_bus.dart' as event_bus;
import 'core/services/notification/twilio_service.dart';
import 'core/services/notification/sms_service.dart';
import 'core/services/notification/notification_service.dart';
import 'core/services/notification/notification_manager.dart';
import 'core/services/currency_service.dart';
import 'core/blocs/auth/auth_event.dart';
import 'core/services/api/payment_service.dart';
import 'core/services/api/help_service.dart';
// Ces services seront importés uniquement dans les fichiers où ils sont utilisés
// import 'core/services/api/favorite_service.dart';
// import 'core/services/api/promotion_service.dart';
// import 'core/services/api/review_service.dart';
import 'core/blocs/payment/payment_bloc.dart';
import 'core/blocs/help/help_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/blocs/theme/theme_bloc.dart';
import 'core/blocs/settings/settings_bloc.dart';
import 'presentation/blocs/pricing/pricing_bloc.dart';
import 'core/services/api/pricing_service.dart';
import 'core/utils/app_bloc_observer.dart';
// Temporairement désactivé pour résoudre les problèmes de build
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android 15+ : dessin sous les barres système (cohérent avec enableEdgeToEdge() dans MainActivity).
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  // Configurer le système de logging
  _setupLogging();
  
  // Configurer l'observateur de blocs pour le débogage
  Bloc.observer = AppBlocObserver();

  // Initialiser les données de localisation et timezone
  await initializeDateFormatting('fr_FR', null);
  tz.initializeTimeZones();
  
  // Initialiser les services de base
  final connectivityService = ConnectivityService();
  final cacheService = CacheService();
  await connectivityService.initialize();
  await cacheService.initialize();

  // Services
  final storage = const FlutterSecureStorage();
  
  // 🚀 FORCER L'ENVIRONNEMENT PRODUCTION (au lieu de development)
  await AppConfigManager.initialize(environment: Environment.production);
  debugPrint('🔧 [Partner] Initialisation forcée en PRODUCTION');
  debugPrint('🌐 [Partner] URL API finale: ${AppConfigManager.apiUrl}');
  
  // Ajouter des logs pour le token d'authentification
  storage.read(key: 'token').then((token) {
    if (token != null && token.isNotEmpty) {
      // Masquer le token dans les logs pour sécurité
      final maskedToken = token.length > 20 
          ? '${token.substring(0, 10)}...${token.substring(token.length - 5)}'
          : '****';
      Logger.root.info('Token d\'authentification trouvé: $maskedToken');
    } else {
      Logger.root.info('Aucun token d\'authentification trouvé');
    }
  }).catchError((error) {
    Logger.root.severe('Erreur lors de la lecture du token: $error');
  });
  
  // 🔧 UTILISER AppConfigManager.apiUrl au lieu de l'ancienne configuration
  final dio = Dio(BaseOptions(
    baseUrl: AppConfigManager.apiUrl,  // ← FIX: Utilise maintenant la config centralisée
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'x-mobile-app': 'true',  // Contourne la protection CSRF pour les applications mobiles
    },
  ));
  
  debugPrint('🔍 [Partner] Client Dio configuré avec baseUrl: ${dio.options.baseUrl}');

  // Create AuthService first
  final authService = AuthService(dio);
  
  // Create AuthBloc with the shared AuthService instance
  final authBloc = AuthBloc(
    authService: authService,
    storage: storage,
  )..add(AuthCheckRequested());

  // Initialize API service with authBloc for automatic logout on token expiration
  final apiService = ApiService(authBloc: authBloc);
  final residenceService = ResidenceService(baseUrl: AppConfigManager.apiUrl, storage: storage);
  
  // Initialiser le service OneSignal
  final oneSignalService = OneSignalService();
  oneSignalService.init(authService);
  debugPrint('✅ Service OneSignal initialisé avec succès pour les partenaires');

  // Initialiser les services
  final dashboardService = DashboardService(dio);
  final messageService = MessageService(dio);
  final reservationService = ReservationService(dio);
  
  // Initialiser les services offline
  await OfflineQueueService().initialize();
  await OfflinePaymentService().initialize();
  
  // Note: AvailabilityService est initialisé dans le provider au besoin

  // Create the router with authBloc
  final appRouter = AppRouter(authBloc);

  // Restaurer le mode sombre depuis les préférences pour le ThemeBloc
  final prefs = await SharedPreferences.getInstance();
  final darkMode = prefs.getBool('dark_mode') ?? false;
  final themeBloc = ThemeBloc(
    initialMode: darkMode ? ThemeMode.dark : ThemeMode.light,
  );

  // Initialiser le service de synchronisation
  final syncService = SyncService();
  syncService.initialize(
    apiService: apiService, 
    residenceService: residenceService,
    reservationService: reservationService,
    messageService: messageService,
  );

  // Créer le bloc de synchronisation
  final syncBloc = SyncBloc(
    syncService: syncService,
    connectivityService: connectivityService,
    cacheService: cacheService,
  );

  // SMS Partner : uniquement via backend (POST /api/sms/send), jamais de secrets Twilio dans l'APK
  final twilioService = TwilioService(apiService: apiService);
  await twilioService.initialize();
  final notificationRepository = NotificationRepository(twilioService, apiService); // Injection de apiService

  NotificationService().bindTwilioService(twilioService);

  // Initialiser le bus d'événements pour les résidences
  final eventBus = event_bus.ResidenceEventBus();
  debugPrint('🔔 Bus d\'événements pour les résidences initialisé');
  
  // Initialiser le service de devises
  final currencyService = CurrencyService();
  await currencyService.initialize();
  
  // Initialiser le NotificationManager unifié
  final notificationManager = NotificationManager();
  notificationManager.bindSmsService(twilioService);
  await notificationManager.initialize();
  debugPrint('✅ NotificationManager unifié initialisé avec succès');
  
  print('Services de devises initialisés avec succès');
  
  // Configurer la barre de navigation système Android pour une meilleure visibilité
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      // Barre de statut (en haut)
      statusBarColor: Colors.transparent, // Transparent pour s'adapter au thème
      statusBarIconBrightness: Brightness.dark, // Icônes sombres (noires) sur fond clair
      statusBarBrightness: Brightness.light, // Pour iOS
      
      // Barre de navigation système (en bas) - CRUCIAL pour la visibilité
      systemNavigationBarColor: Colors.black, // Fond noir pour contraste
      systemNavigationBarIconBrightness: Brightness.light, // Icônes blanches sur fond noir
      systemNavigationBarDividerColor: Colors.transparent, // Pas de séparateur
    ),
  );
  
  runApp(
    MultiProvider(
      providers: [
        Provider<MessageService>(
          create: (_) => messageService,
        ),
        Provider<AuthService>(
          create: (_) => authService,
        ),
        Provider<ReservationService>(
          create: (_) => reservationService,
        ),
        Provider<ConnectivityService>(
          create: (_) => connectivityService,
        ),
        Provider<CacheService>(
          create: (_) => cacheService,
        ),
        Provider<SyncService>(
          create: (_) => syncService,
        ),
        Provider<TwilioService>(
          create: (_) => twilioService,
          dispose: (_, service) => service.dispose(),
        ),
        Provider<NotificationRepository>(
          create: (context) => notificationRepository,
        ),
        // Ajouter le bus d'événements comme un provider
        Provider<event_bus.ResidenceEventBus>(
          create: (_) => eventBus,
        ),
        Provider<ResidenceService>(
          create: (_) => residenceService,
          lazy: false, // Charger immédiatement pour éviter les problèmes de chargement paresseux
        ),
        Provider<ApiService>(
          create: (_) => apiService,
          lazy: false, // Assurer que l'instance est disponible immédiatement
        ),
        Provider<SmsService>(create: (_) => SmsService(apiService: apiService)),
        Provider<NotificationManager>(
          create: (_) => notificationManager,
          lazy: false,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(
            value: authBloc,
          ),
          BlocProvider<ResidenceBloc>(
            create: (context) => ResidenceBloc(
              context.read<ResidenceService>(),
              eventBus: context.read<event_bus.ResidenceEventBus>(),
              notificationRepository: context.read<NotificationRepository>(),
            )..add(LoadMyResidences()),
          ),
          BlocProvider<DashboardBloc>(
            create: (context) => DashboardBloc(
              dashboardService,
            )..add(LoadDashboardData()),
          ),
          BlocProvider<MessageBloc>(
            create: (context) => MessageBloc(context.read<MessageService>()),
          ),
          BlocProvider<ReservationBloc>(
            create: (context) => ReservationBloc(context.read<ReservationService>())..add(LoadMyReservations()),
          ),
          BlocProvider<SyncBloc>.value(
            value: syncBloc,
          ),
          BlocProvider<NotificationBloc>(
            create: (context) => NotificationBloc(
              repository: context.read<NotificationRepository>(),
            )..add(const LoadNotifications(page: 1)),
          ),
          // Ajouter le PaymentBloc
          BlocProvider<PaymentBloc>(
            create: (context) => PaymentBloc(
              paymentService: PaymentService(dio),
            ),
          ),
          // Ajouter le HelpBloc
          BlocProvider<HelpBloc>(
            create: (context) => HelpBloc(
              helpService: HelpService(dio),
            ),
          ),
          BlocProvider<ThemeBloc>.value(value: themeBloc),
          BlocProvider<SettingsBloc>(
            create: (context) => SettingsBloc(),
          ),
          // Ajouter le PricingBloc
          BlocProvider<PricingBloc>(
            create: (context) => PricingBloc(
              pricingService: PricingService(),
            ),
          ),
        ],
        child: BlocBuilder<ThemeBloc, ThemeState>(
          buildWhen: (prev, curr) => prev.themeMode != curr.themeMode,
          builder: (context, state) {
            return MaterialApp.router(
              title: 'ChapeChape Partner',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                fontFamily: 'Poppins',
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF1A237E),
                  brightness: Brightness.light,
                ),
                useMaterial3: true,
                appBarTheme: const AppBarTheme(
                  centerTitle: true,
                  elevation: 0,
                ),
                cardTheme: CardThemeData(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              darkTheme: AppTheme.darkTheme,
              themeMode: state.themeMode,
              routerConfig: appRouter.router,
            );
          },
        ),
      ),
    ),
  );
}

/// Configure le système de logging
void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // Format: [LEVEL] LOGGER_NAME: MESSAGE
    final emoji = _getLogLevelEmoji(record.level);
    debugPrint('$emoji [${record.level.name}] ${record.loggerName}: ${record.message}');
    
    // Si une exception est présente, l'afficher aussi
    if (record.error != null) {
      debugPrint('╰─ ERROR: ${record.error}');
      if (record.stackTrace != null) {
        debugPrint('╰─ STACK: ${record.stackTrace}');
      }
    }
  });
}

/// Retourne un emoji approprié selon le niveau de log
String _getLogLevelEmoji(Level level) {
  if (level == Level.SEVERE) return '🔥'; // Erreur grave
  if (level == Level.WARNING) return '⚠️'; // Avertissement
  if (level == Level.INFO) return '📝'; // Information
  if (level == Level.CONFIG) return '⚙️'; // Configuration
  if (level == Level.FINE) return '🔍'; // Détail fin
  if (level == Level.FINER || level == Level.FINEST) return '🔬'; // Détail très fin
  return '��'; // Par défaut
}

/// Initialise tous les services nécessaires au démarrage de l'application
Future<void> _initializeServices() async {
  try {
    // Initialiser le service de devises
    final currencyService = CurrencyService();
    await currencyService.initialize();
    
    print('Services de devises initialisés avec succès');
    
    // Les nouveaux services (favoris, promotions, avis) seront initialisés au besoin
    // via leur constructeur avec apiService quand ils seront utilisés
    // dans les écrans ou composants appropriés
    print('Services API prêts pour favoris, promotions et avis');
    
    // Exemple d'utilisation d'un service :
    // final favoriteService = FavoriteService.withApiService(apiService: apiService);
    // final promotionService = PromotionService.withApiService(apiService: apiService);
    // final reviewService = ReviewService.withApiService(apiService: apiService);
  } catch (e) {
    print('Erreur lors de l\'initialisation des services: $e');
  }
}
