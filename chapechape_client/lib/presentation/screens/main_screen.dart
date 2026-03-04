import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'favorites_screen.dart';
import 'notifications_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'home_screen.dart';
import '../widgets/notification_button.dart';
import '../widgets/language_selector.dart';
import '../widgets/location_selector_widget.dart';
import '../widgets/connectivity_banner.dart';
import 'offline_screen.dart';
import '../../core/models/city.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/optimized_connectivity_service.dart';
import '../../core/blocs/notification/notification_bloc.dart';
import '../../core/blocs/notification/notification_state.dart';

class MainScreen extends StatefulWidget {
  final Widget child;
  const MainScreen({super.key, required this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Variables pour gérer la sélection de ville
  City? _selectedCity;
  
  // Logger pour le monitoring
  final LoggerService _logger = LoggerService();
  
  // Service de connectivité optimisé
  final OptimizedConnectivityService _connectivityService = OptimizedConnectivityService();
  
  // Variables pour le hide-on-scroll du bottom navigation bar
  bool _isNavBarVisible = true;
  double _lastScrollOffset = 0;
  
  /// Gère la détection du scroll pour afficher/masquer la barre de navigation
  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final currentOffset = notification.metrics.pixels;
      final delta = currentOffset - _lastScrollOffset;
      
      // Seuil de 15 pixels pour éviter les micro-scrolls
      if (delta > 15 && _isNavBarVisible && currentOffset > 50) {
        setState(() => _isNavBarVisible = false);
      } else if (delta < -15 && !_isNavBarVisible) {
        setState(() => _isNavBarVisible = true);
      }
      
      _lastScrollOffset = currentOffset;
    }
    
    // Réafficher la navbar quand on atteint le haut
    if (notification is ScrollEndNotification) {
      if (notification.metrics.pixels <= 0 && !_isNavBarVisible) {
        setState(() => _isNavBarVisible = true);
      }
    }
    
    return false; // Ne pas intercepter les notifications
  }

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
      HapticFeedback.selectionClick();
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
      extendBodyBehindAppBar: false,
      appBar: isHomeScreen
          ? null
          : AppBar(
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black12 : Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
              ),
              leading: Container(
                margin: EdgeInsets.all(AppSpacing.sm),
                child: IconButton(
                  icon: const Icon(Icons.menu),
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  onPressed: () => _showLocationMenu(context),
                  tooltip: 'Menu',
                  padding: EdgeInsets.zero,
                ),
              ),
              actions: [
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
                const NotificationButton(),
              ],
              title: _selectedCity != null
                  ? InkWell(
                      onTap: () => _showLocationMenu(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, size: 16, color: AppTheme.primaryColor),
                          SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              'À ${_selectedCity!.name}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              semanticsLabel: 'Localisation: ${_selectedCity!.name}',
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey[600]),
                        ],
                      ),
                    )
                  : null,
              centerTitle: false,
            ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: ConnectivityBanner(
              child: widget.child,
            ),
          ),
          // Sur home : header en overlay, animé au scroll comme la bottom nav bar
          if (isHomeScreen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  offset: _isNavBarVisible ? Offset.zero : const Offset(0, -1.2),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isNavBarVisible ? 1.0 : 0.0,
                    child: _buildHomeOverlayAppBar(context),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        offset: _isNavBarVisible ? Offset.zero : const Offset(0, 1.5),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isNavBarVisible ? 1.0 : 0.0,
          child: Container(
            margin: EdgeInsets.only(bottom: AppSpacing.lg, left: AppSpacing.lg, right: AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl + AppSpacing.smd),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl + AppSpacing.smd),
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
                  height: 56,
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
                      icon: BlocBuilder<NotificationBloc, NotificationState>(
                        builder: (context, state) {
                          int unreadCount = 0;
                          if (state is NotificationLoaded) {
                            unreadCount = state.notifications.where((n) => !n.isRead).length;
                          }
                          
                          return Badge(
                            label: unreadCount > 0 
                              ? Text(unreadCount > 99 ? '99+' : unreadCount.toString())
                              : null,
                            child: const Icon(Icons.notifications_outlined),
                          );
                        },
                      ),
                      selectedIcon: BlocBuilder<NotificationBloc, NotificationState>(
                        builder: (context, state) {
                          int unreadCount = 0;
                          if (state is NotificationLoaded) {
                            unreadCount = state.notifications.where((n) => !n.isRead).length;
                          }
                          
                          return Badge(
                            label: unreadCount > 0 
                              ? Text(unreadCount > 99 ? '99+' : unreadCount.toString())
                              : null,
                            child: Icon(Icons.notifications, color: Theme.of(context).primaryColor),
                          );
                        },
                      ),
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
        ),
      ),
    );
  }
  
  /// Barre du haut en overlay sur l'écran d'accueil : même visuel que l'ancienne AppBar, animée au scroll.
  Widget _buildHomeOverlayAppBar(BuildContext context) {
    return IconTheme(
      data: const IconThemeData(color: Colors.white),
      child: Material(
        color: Colors.transparent,
        child: Container(
        padding: EdgeInsets.only(
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          top: AppSpacing.xs,
          bottom: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Container(
              margin: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: IconButton(
                icon: const Icon(Icons.menu),
                color: Colors.white,
                onPressed: () => _showLocationMenu(context),
                tooltip: 'Menu',
                padding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: _selectedCity != null
                  ? InkWell(
                      onTap: () => _showLocationMenu(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.white),
                          SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              'À ${_selectedCity!.name}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              semanticsLabel: 'Localisation: ${_selectedCity!.name}',
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, size: 16, color: Colors.white70),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
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
            const NotificationButton(),
          ],
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
        padding: AppSpacing.cardPadding,
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
              margin: EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(AppSpacing.xs / 2),
              ),
            ),
            // Sélecteur de langue
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Icon(Icons.language, color: Colors.grey[700]),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Langue',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, color: Colors.grey[700]),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Localisation',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[800],
                          ),
                        ),
                        AppSpacing.verticalSm,
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
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
