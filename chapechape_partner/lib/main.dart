import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/blocs/auth/auth_bloc.dart';
import 'core/blocs/dashboard/dashboard_bloc.dart';
import 'core/blocs/residence/residence_bloc.dart';
import 'core/blocs/message/message_bloc.dart';
import 'core/services/api/api_service.dart';
import 'core/services/api/auth_service.dart';
import 'core/services/api/residence_service.dart';
import 'core/services/api/availability_service.dart';
import 'core/services/api/dashboard_service.dart';
import 'core/services/api/message_service.dart';
import 'core/services/api/user_service.dart';
import 'router/app_router.dart';
import 'core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Services
  final storage = const FlutterSecureStorage();
  final apiService = ApiService();
  final authService = AuthService(apiService.dio);
  final residenceService = ResidenceService(baseUrl: AppConfig.apiUrl, storage: storage);
  final availabilityService = AvailabilityService(apiService);
  final dashboardService = DashboardService(apiService.dio);
  final messageService = MessageService(apiService);
  final userService = UserService(apiService);

  // Create AuthBloc first since it's needed for the router
  final authBloc = AuthBloc(
    authService: authService,
    storage: storage,
  );

  // Create router with AuthBloc
  final appRouter = AppRouter(authBloc);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: authBloc..add(AuthCheckRequested()),
        ),
        BlocProvider<ResidenceBloc>(
          create: (context) => ResidenceBloc(residenceService)..add(LoadResidences()),
        ),
        BlocProvider<DashboardBloc>(
          create: (context) => DashboardBloc(dashboardService)
            ..add(LoadDashboardData()),
        ),
        BlocProvider<MessageBloc>(
          create: (context) => MessageBloc(messageService),
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
  );
}
