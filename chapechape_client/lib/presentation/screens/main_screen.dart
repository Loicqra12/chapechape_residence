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
        actions: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LanguageSelector(),
                const SizedBox(width: 8),
                const LocationSelectorWidget(),
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, size: 20),
                        onPressed: () => context.go('/notifications'),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor, // Or doré
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: const Text(
                            '0',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const AuthButtonWidget(),
                const SizedBox(width: 16),
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppTheme.secondaryColor),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite, color: AppTheme.secondaryColor),
            label: 'Favoris',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications, color: AppTheme.secondaryColor),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat, color: AppTheme.secondaryColor),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.secondaryColor),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
