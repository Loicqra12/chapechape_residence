import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'favorites_screen.dart';
import 'notifications_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'home_screen.dart';
import '../widgets/notification_button.dart';
import '../widgets/language_selector.dart';
import '../widgets/location_selector_widget.dart';
import '../widgets/auth_button_widget.dart';
import '../widgets/connectivity_banner.dart';
import 'offline_screen.dart';
import '../../core/models/city.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/optimized_connectivity_service.dart';

class MainScreen extends StatefulWidget {
  final Widget child;
  const MainScreen({super.key, required this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const Color blackColor = Color(0xFF1A1A1A);
  static const Color whiteColor = Color(0xFFFFFFFF);
  
  // Variables pour gérer la sélection de ville
  City? _selectedCity;
  
  // Logger pour le monitoring
  final LoggerService _logger = LoggerService();
  
  // Service de connectivité optimisé
  final OptimizedConnectivityService _connectivityService = OptimizedConnectivityService();

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/favorites')) return 1;
    if (location.startsWith('/notifications')) return 2;
    if (location.startsWith('/chat')) return 3;
    if (location.startsWith('/profile')) return 4;
    if (location.startsWith('/bookings')) return 4; // Historique des réservations = Profil
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    final routes = [
      '/home',
      '/favorites',
      '/notifications',
      '/chat',
      '/profile'
    ];
    final routeLabels = [
      'Accueil',
      'Favoris',
      'Notifications',
      'Messages',
      'Profil'
    ];
    
    if (index >= 0 && index < routes.length) {
      _logger.debug('Navigation vers ${routeLabels[index]} (${routes[index]})');
      context.go(routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.debug('Construction du MainScreen');
    
    final location = GoRouterState.of(context).uri.path;
    final isHomeScreen = location.startsWith('/home') || location == '/';

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: isHomeScreen,
      appBar: AppBar(
        backgroundColor: isHomeScreen 
            ? Colors.transparent 
            : (Theme.of(context).brightness == Brightness.dark ? Colors.black12 : Colors.white),
        elevation: 0,
        iconTheme: IconThemeData(
          color: isHomeScreen ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: isHomeScreen ? BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ) : null,
          child: IconButton(
            icon: const Icon(Icons.menu),
            color: isHomeScreen ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
            onPressed: () => _showLocationMenu(context),
            tooltip: 'Menu',
            padding: EdgeInsets.zero,
          ),
        ),
        actions: [
          // Bouton mode offline
          StreamBuilder<bool>(
            stream: _connectivityService.connectivityStream,
            builder: (context, snapshot) {
              final isConnected = snapshot.data ?? true;
              if (!isConnected) {
                return IconButton(
                  icon: const Icon(Icons.cloud_off),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OfflineScreen(),
                      ),
                    );
                  },
                  tooltip: 'Mode Hors Ligne',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Icône notifications avec badge
          const NotificationButton(),
          // Avatar utilisateur en haut à droite
          const AuthButtonWidget(),
        ],
        title: _selectedCity != null 
          ? InkWell(
              onTap: () => _showLocationMenu(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 16, color: isHomeScreen ? Colors.white : AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _selectedCity!.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: isHomeScreen ? Colors.white : Colors.grey[800],
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      semanticsLabel: 'Localisation actuelle: ${_selectedCity!.name}',
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, size: 16, color: isHomeScreen ? Colors.white70 : Colors.grey[600]),
                ],
              ),
            )
          : null,
        centerTitle: false,
      ),
      body: ConnectivityBanner(
        child: widget.child,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: NavigationBar(
              selectedIndex: _calculateSelectedIndex(context),
              onDestinationSelected: (index) => _onItemTapped(index, context),
              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.black.withOpacity(0.6) 
                  : Colors.white.withOpacity(0.8),
              indicatorColor: Theme.of(context).brightness == Brightness.dark 
                  ? AppTheme.primaryColor.withOpacity(0.2) 
                  : AppTheme.primaryColor.withOpacity(0.15),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              height: 70,
              elevation: 0,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home, color: Theme.of(context).primaryColor),
                  label: 'Accueil',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.favorite_outline),
                  selectedIcon: Icon(Icons.favorite, color: Theme.of(context).primaryColor),
                  label: 'Favoris',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.notifications_outlined),
                  selectedIcon: Icon(Icons.notifications, color: Theme.of(context).primaryColor),
                  label: 'Notifs',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.chat_outlined),
                  selectedIcon: Icon(Icons.chat, color: Theme.of(context).primaryColor),
                  label: 'Messages',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person, color: Theme.of(context).primaryColor),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Méthode pour afficher le menu de localisation amélioré
  void _showLocationMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barre de poignée pour indiquer qu'on peut faire glisser
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Sélecteur de langue
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.language, color: Colors.grey[700]),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Langue',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  const LanguageSelector(),
                ],
              ),
            ),
            const Divider(),
            // Sélecteur de localisation
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, color: Colors.grey[700]),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Localisation',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        LocationSelectorWidget(
                          // À implémenter: support pour le sélecteur hiérarchique multiniveau
                          // (pays, région, ville, quartier) selon les spécifications du projet
                          onCitySelected: (city) {
                            setState(() {
                              _selectedCity = city;
                            });
                            
                            // Logger la sélection pour analytics
                            _logger.info('Localisation sélectionnée: ${city.name}');
                            
                            // Feedback visuel de sélection
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Localisation mise à jour : ${city.name}'),
                                backgroundColor: AppTheme.primaryColor,
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
