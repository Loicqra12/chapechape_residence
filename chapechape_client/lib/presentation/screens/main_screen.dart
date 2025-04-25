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
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/favorites');
        break;
      case 2:
        context.go('/notifications');
        break;
      case 3:
        context.go('/chat');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Définir des constantes pour la cohérence visuelle
    const double iconSize = 22.0;
    const double iconSpacing = 8.0;
    const EdgeInsets iconPadding = EdgeInsets.all(8.0);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 120,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Image.asset(
            'assets/logos/app_logo.png',
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
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                  icon: const Icon(Icons.menu, size: iconSize),
                  onPressed: () => _showLocationMenu(context),
                  constraints: const BoxConstraints(),
                  padding: iconPadding,
                ),
                const SizedBox(width: iconSpacing),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: iconSize),
                  onPressed: () => context.go('/notifications'),
                  constraints: const BoxConstraints(),
                  padding: iconPadding,
                ),
                const SizedBox(width: iconSpacing),
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
        backgroundColor: whiteColor,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 60,
        elevation: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppTheme.primaryColor),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite, color: AppTheme.primaryColor),
            label: 'Favoris',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications, color: AppTheme.primaryColor),
            label: 'Notifs',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat, color: AppTheme.primaryColor),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.primaryColor),
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
                          onCitySelected: (city) {
                            setState(() {
                              _selectedCity = city;
                            });
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
