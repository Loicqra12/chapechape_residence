import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/config/api_config.dart';
import 'core/config/app_config_manager.dart';
import 'core/config/environment.dart';
import 'core/services/api/api_service.dart';
import 'core/services/api/auth_service.dart';
import 'core/services/api/residence_service.dart';
import 'core/services/api/availability_service.dart';
import 'core/services/api/dashboard_service.dart';
import 'core/services/api/message_service.dart';
import 'core/services/api/reservation_service.dart';
import 'core/services/api/notification_service.dart';
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
import 'package:logging/logging.dart';
import 'core/services/event_bus/residence_event_bus.dart' as event_bus;
import 'core/services/notification/twilio_service.dart';
import 'core/services/currency_service.dart';
import 'core/blocs/auth/auth_event.dart';
import 'core/services/api/payment_service.dart';
import 'core/services/api/help_service.dart';
import 'core/blocs/payment/payment_bloc.dart';
import 'core/blocs/help/help_bloc.dart';
import 'core/blocs/theme/theme_bloc.dart';
import 'core/blocs/settings/settings_bloc.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
// Temporairement désactivé pour résoudre les problèmes de build
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser OneSignal
  OneSignal.initialize("43531899-4645-4f52-a2bf-f4e4a4095513");
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.Notifications.requestPermission(true);
  
  // Ajouter un tag pour identifier qu'il s'agit d'un partenaire
  OneSignal.User.addTags({"userType": "partner"});

  // Configurer le système de logging
  _setupLogging();

  // Initialiser les données de localisation française
  await initializeDateFormatting('fr_FR', null);
  Intl.defaultLocale = 'fr_FR';
  
  // Initialiser les services de base
  final connectivityService = ConnectivityService();
  final cacheService = CacheService();
  await connectivityService.initialize();
  await cacheService.initialize();

  // Services
  final storage = const FlutterSecureStorage();
  final apiConfig = ApiConfig.development();
  
  await AppConfigManager.initialize(environment: Environment.development);
  
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
  
  final dio = Dio(BaseOptions(
    baseUrl: apiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  // Create AuthBloc first since it's needed for the router
  final authBloc = AuthBloc(
    authService: AuthService(dio),
    storage: storage,
  )..add(AuthCheckRequested());

  // Initialize API service with authBloc for automatic logout on token expiration
  final apiService = ApiService(authBloc: authBloc);
  
  final authService = AuthService(dio);
  final residenceService = ResidenceService(baseUrl: apiConfig.baseUrl, storage: storage);
  
  // Initialiser le service OneSignal
  final oneSignalService = OneSignalService();
  oneSignalService.init(authService);
  debugPrint('✅ Service OneSignal initialisé avec succès pour les partenaires');

  final availabilityService = AvailabilityService(dio);
  final dashboardService = DashboardService(dio);
  final messageService = MessageService(dio);
  final reservationService = ReservationService(dio);

  // Create the router with authBloc
  final appRouter = AppRouter(authBloc);

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

  // Créer le repository de notification et le service
  final twilioService = TwilioService();
  // Temporairement désactivé pour résoudre les problèmes de build
  // await twilioService.initialize();
  final notificationRepository = NotificationRepository(twilioService);

  // Initialiser le bus d'événements pour les résidences
  final eventBus = event_bus.ResidenceEventBus();
  debugPrint('🔔 Bus d\'événements pour les résidences initialisé');
  
  // Initialiser le service de devises
  final currencyService = CurrencyService();
  await currencyService.initialize();
  
  print('Services de devises initialisés avec succès');
  
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
          BlocProvider<ThemeBloc>(
            create: (context) => ThemeBloc(),
          ),
          BlocProvider<SettingsBloc>(
            create: (context) => SettingsBloc(),
          ),
        ],
        child: MaterialApp.router(
          title: 'ChapeChape Partner',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A237E),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
            ),
            cardTheme: CardTheme(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          routerConfig: appRouter.router,
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
    
    // ... autres initialisations de services ...
  } catch (e) {
    print('Erreur lors de l\'initialisation des services: $e');
  }
}
