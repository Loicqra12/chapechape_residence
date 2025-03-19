import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/config/api_config.dart';
import 'core/services/api/api_service.dart';
import 'core/services/api/auth_service.dart';
import 'core/services/api/residence_service.dart';
import 'core/services/api/availability_service.dart';
import 'core/services/api/dashboard_service.dart';
import 'core/services/api/message_service.dart';
import 'core/services/api/reservation_service.dart';
import 'core/blocs/auth/auth_bloc.dart';
import 'core/blocs/residence/residence_bloc.dart';
import 'core/blocs/dashboard/dashboard_bloc.dart';
import 'core/blocs/message/message_bloc.dart';
import 'core/blocs/reservation/reservation_bloc.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les données de localisation française
  await initializeDateFormatting('fr_FR', null);
  Intl.defaultLocale = 'fr_FR';

  // Services
  final storage = const FlutterSecureStorage();
  final apiConfig = ApiConfig.development();
  
  // Ajouter des logs pour le token d'authentification
  storage.read(key: 'token').then((token) {
    print('Token d\'authentification: ${token?.substring(0, 20)}...');
  }).catchError((error) {
    print('Erreur lors de la lecture du token: $error');
  });
  
  final dio = Dio(BaseOptions(
    baseUrl: apiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  final apiService = ApiService();
  final authService = AuthService(dio);
  final residenceService = ResidenceService(baseUrl: apiConfig.baseUrl, storage: storage);
  final availabilityService = AvailabilityService(dio);
  final dashboardService = DashboardService(dio);
  final messageService = MessageService(dio);
  final reservationService = ReservationService(dio);

  // Create AuthBloc first since it's needed for the router
  final authBloc = AuthBloc(
    authService: authService,
    storage: storage,
  )..add(AuthCheckRequested());

  // Create the router with authBloc
  final appRouter = AppRouter(authBloc);

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
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(
            value: authBloc,
          ),
          BlocProvider<ResidenceBloc>(
            create: (context) => ResidenceBloc(residenceService)..add(LoadMyResidences()),
          ),
          BlocProvider<DashboardBloc>(
            create: (context) => DashboardBloc(dashboardService)..add(LoadDashboardData()),
          ),
          BlocProvider<MessageBloc>(
            create: (context) => MessageBloc(context.read<MessageService>()),
          ),
          BlocProvider<ReservationBloc>(
            create: (context) => ReservationBloc(context.read<ReservationService>())..add(LoadMyReservations()),
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
