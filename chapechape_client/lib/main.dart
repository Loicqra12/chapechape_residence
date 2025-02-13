import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:chapechape_client/theme/app_theme.dart';
import 'package:chapechape_client/router/app_router.dart';

// Configuration par défaut
const defaultConfig = {
  'FLUTTER_APP_NAME': 'ChapeChape Résidences',
  'API_BASE_URL': 'https://api.chapechape.com',
  'API_VERSION': 'v1',
  'ENABLE_CHAT': 'true',
  'ENABLE_NOTIFICATIONS': 'true',
  'ENABLE_LOCATION': 'true',
  'ENABLE_OFFLINE_MODE': 'true',
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les services
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: .env file not found. Using default configuration.');
    // Charger la configuration par défaut
    for (var entry in defaultConfig.entries) {
      dotenv.env[entry.key] = entry.value;
    }
  }
  
  await Hive.initFlutter();
  
  // Ouvrir les boxes Hive nécessaires
  await Hive.openBox('settings');
  await Hive.openBox('cache');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appName = dotenv.env['FLUTTER_APP_NAME'] ?? defaultConfig['FLUTTER_APP_NAME']!;
    
    return MaterialApp.router(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
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
}
