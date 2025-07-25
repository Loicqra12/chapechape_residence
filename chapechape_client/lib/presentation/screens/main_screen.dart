import 'package:flutter/material.dart';
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
import '../../core/models/city.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/logger_service.dart';

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

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/favorites')) return 1;
    if (location.startsWith('/notifications')) return 2;
    if (location.startsWith('/chat')) return 3;
    if (location.startsWith('/profile')) return 4;
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
    // Calculer les tailles d'interface en fonction de l'appareil
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 360;
    
    // Définir des constantes pour la cohérence visuelle avec adaptation à la taille d'écran
    final double iconSize = isSmallScreen ? 18.0 : 22.0;
    final double iconSpacing = isSmallScreen ? 4.0 : 8.0;
    final EdgeInsets iconPadding = isSmallScreen 
        ? const EdgeInsets.all(4.0)
        : const EdgeInsets.all(8.0);
        
    _logger.debug('Écran détecté: ${screenSize.width}x${screenSize.height}, isSmallScreen: $isSmallScreen');
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black12 : Colors.white,
        elevation: 0,
        leadingWidth: 120,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Image.asset(
            Theme.of(context).brightness == Brightness.dark 
              ? 'assets/logos/app_logo_dark.png'
              : 'assets/logos/app_logo.png',
            fit: BoxFit.contain,
          ),
        ),
        title: _selectedCity != null 
          ? InkWell(
              onTap: () => _showLocationMenu(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _selectedCity!.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      semanticsLabel: 'Localisation actuelle: ${_selectedCity!.name}',
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey[600]),
                ],
              ),
            )
          : null,
        centerTitle: false,
        actions: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.menu, size: iconSize),
                  onPressed: () => _showLocationMenu(context),
                  constraints: BoxConstraints(),
                  padding: iconPadding,
                ),
                SizedBox(width: iconSpacing),
                IconButton(
                  icon: Icon(Icons.notifications_outlined, size: iconSize),
                  onPressed: () => context.go('/notifications'),
                  constraints: BoxConstraints(),
                  padding: iconPadding,
                ),
                SizedBox(width: iconSpacing),
                const AuthButtonWidget(),
              ],
            ),
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? blackColor : whiteColor,
        indicatorColor: Theme.of(context).brightness == Brightness.dark 
            ? AppTheme.primaryColor.withOpacity(0.2) 
            : Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 60,
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
