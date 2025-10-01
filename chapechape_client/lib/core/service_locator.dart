import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';
import 'config/app_config_manager.dart';

import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/cache_service.dart';
import 'services/optimized_connectivity_service.dart';
import 'services/user_service.dart';
import 'services/residence_service.dart';
import 'services/app_settings_service.dart';
import 'services/logger_service.dart';
import 'services/type_sync_service.dart';
import 'services/category_cache_service.dart';
import 'services/favorite_service.dart';
import 'services/connectivity/connection_quality_service.dart';

import 'repositories/auth_repository.dart';
import 'repositories/favorite_repository.dart';
import 'repositories/residence_repository.dart';
import 'repositories/user_repository.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/user/user_bloc.dart';
import 'blocs/residence/residence_bloc.dart';

// Définir les blocs en attendant de créer les fichiers
class ConnectivityBloc {
  final OptimizedConnectivityService connectivityService;
  ConnectivityBloc({required this.connectivityService});
}

class AppSettingsBloc {
  final AppSettingsService appSettingsService;
  AppSettingsBloc({required this.appSettingsService});
}

final GetIt sl = GetIt.instance;

// Drapeau pour éviter les initialisations multiples
bool _isInitialized = false;

/// Configure l'injection des dépendances
Future<void> setupServiceLocator() async {
  // Protection contre les initialisations multiples
  if (_isInitialized) {
    print('ServiceLocator déjà initialisé, ignoré');
    return;
  }
  
  // Initialiser Hive pour le stockage local
  await Hive.initFlutter();
  
  // Services externes
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);
  
  // 🚀 Utiliser l'URL de l'API depuis AppConfigManager (production ou dev)
  final dio = Dio(BaseOptions(
    baseUrl: AppConfigManager.apiUrl, 
    connectTimeout: const Duration(milliseconds: 15000),
    receiveTimeout: const Duration(milliseconds: 15000),
  ));
  sl.registerSingleton<Dio>(dio);

  // Services
  sl.registerSingleton<LoggerService>(LoggerService());
  
  // Initialisation des services principaux
  final apiService = await ApiService.initialize();
  sl.registerSingleton<ApiService>(apiService);
  
  // CacheService utilise un singleton interne
  sl.registerSingleton<CacheService>(CacheService.getInstance());
  
  // Connectivité
  sl.registerSingleton<OptimizedConnectivityService>(OptimizedConnectivityService());
  
  // Initialisation des services qui dépendent de l'API service
  final authService = await AuthService.initialize();
  sl.registerSingleton<AuthService>(authService);
  
  final userService = await UserService.initialize();
  sl.registerSingleton<UserService>(userService);
  
  final residenceService = await ResidenceService.initialize();
  sl.registerSingleton<ResidenceService>(residenceService);
  
  // Initialisation des services additionnels
  final favoriteService = await FavoriteService.initialize();
  sl.registerSingleton<FavoriteService>(favoriteService);
  
  sl.registerSingleton<TypeSyncService>(TypeSyncService(
    apiService: sl<ApiService>(),
    logger: sl<LoggerService>(),
  ));
  
  sl.registerSingleton<CategoryCacheService>(CategoryCacheService(
    apiService: sl<ApiService>(),
    logger: sl<LoggerService>(),
  ));
  
  sl.registerSingleton<AppSettingsService>(AppSettingsService(
    cacheService: sl<CacheService>(),
    logger: sl<LoggerService>(),
  ));
  
  // Ajout du service de qualité de connexion 
  sl.registerSingleton<ConnectionQualityService>(ConnectionQualityService());
  await sl<ConnectionQualityService>().initialize();
  
  // Repositories
  sl.registerSingleton<AuthRepository>(AuthRepository(
    authService: sl<AuthService>(),
  ));
  
  sl.registerSingleton<UserRepository>(UserRepository(
    userService: sl<UserService>(),
  ));
  
  sl.registerSingleton<ResidenceRepository>(ResidenceRepository(
    residenceService: sl<ResidenceService>(),
    favoriteService: sl<FavoriteService>(),
  ));
  
  sl.registerSingleton<FavoriteRepository>(FavoriteRepository(
    favoriteService: sl<FavoriteService>(),
    residenceService: sl<ResidenceService>(),
  ));

  // Blocs
  sl.registerFactory<AuthBloc>(() => AuthBloc(
    authService: sl<AuthService>(),
  ));
  
  sl.registerFactory<UserBloc>(() => UserBloc(
    userService: sl<UserService>(),
  ));
  
  sl.registerFactory<ResidenceBloc>(() => ResidenceBloc(
    residenceService: sl<ResidenceService>(),
    favoriteService: sl<FavoriteService>(),
    typeSyncService: sl<TypeSyncService>(),
  ));
  
  sl.registerFactory(
    () => ConnectivityBloc(
      connectivityService: sl<OptimizedConnectivityService>(),
    ),
  );
  
  sl.registerFactory(
    () => AppSettingsBloc(
      appSettingsService: sl<AppSettingsService>(),
    ),
  );

  // Marquer comme initialisé
  _isInitialized = true;
  print('ServiceLocator initialisé avec succès');
}