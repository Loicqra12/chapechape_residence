


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/message/message_bloc.dart';
import '../../../core/blocs/notification/notification_bloc.dart';
import '../../../core/blocs/notification/notification_state.dart';
import '../../../core/blocs/reservation/reservation_bloc.dart';
import '../../widgets/common/partner_count_badge.dart';
import '../dashboard/dashboard_screen.dart';
import '../messages/messages_screen.dart';
import '../profile/profile_screen.dart';
import '../residences/residences_screen.dart';
import '../reservations/reservations_screen.dart';

/// InheritedWidget pour permettre la navigation entre les onglets depuis les enfants
class MainScreenNavigator extends InheritedWidget {
  final void Function(BuildContext context, int index) navigateToTab;

  const MainScreenNavigator({
    super.key,
    required this.navigateToTab,
    required super.child,
  });

  static MainScreenNavigator? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainScreenNavigator>();
  }

  @override
  bool updateShouldNotify(MainScreenNavigator oldWidget) => false;
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    ResidencesScreen(),
    const ReservationsScreen(),
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  void _navigateToTab(BuildContext context, int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() => _currentIndex = index);
      if (index == 2) {
        context.read<ReservationBloc>().add(LoadPartnerReservations());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScreenNavigator(
      navigateToTab: _navigateToTab,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildBottomNavigationBar(context),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                index: 0,
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Dashboard',
              ),
              _buildNavItem(
                context,
                index: 1,
                icon: Icons.apartment_outlined,
                activeIcon: Icons.apartment,
                label: 'Résidences',
              ),
              BlocBuilder<ReservationBloc, ReservationState>(
                builder: (context, state) {
                  var badge = 0;
                  if (state is ReservationLoaded) {
                    badge = partnerReservationAttentionCount(state.reservations);
                  }
                  return _buildNavItem(
                    context,
                    index: 2,
                    icon: Icons.calendar_today_outlined,
                    activeIcon: Icons.calendar_today,
                    label: 'Réservations',
                    badgeCount: badge,
                  );
                },
              ),
              // Messages avec badge
              BlocBuilder<MessageBloc, MessageState>(
                builder: (context, state) {
                  int unreadCount = 0;
                  if (state is ConversationsLoaded) {
                    unreadCount = state.conversations
                        .where((c) => c.unreadCount > 0)
                        .fold(0, (sum, c) => sum + c.unreadCount);
                  }
                  return _buildNavItem(
                    context,
                    index: 3,
                    icon: Icons.message_outlined,
                    activeIcon: Icons.message,
                    label: 'Messages',
                    badgeCount: unreadCount,
                  );
                },
              ),
              // Profil avec badge notifications
              BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  int unreadCount = 0;
                  if (state is NotificationLoaded) {
                    unreadCount = state.notifications
                        .where((n) => !n.isRead)
                        .length;
                  }
                  return _buildNavItem(
                    context,
                    index: 4,
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: 'Profil',
                    badgeCount: unreadCount,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    return Expanded(
      child: InkWell(
        onTap: () => _navigateToTab(context, index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected 
                ? primaryColor.withOpacity(0.1) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône avec badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      key: ValueKey(isSelected),
                      color: isSelected ? primaryColor : Colors.grey,
                      size: 24,
                    ),
                  ),
                  // Badge
                  if (badgeCount > 0)
                    Positioned(
                      right: -10,
                      top: -6,
                      child: PartnerCountBadge(
                        count: badgeCount,
                        compact: true,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              // Label : FittedBox pour éviter la troncature (ex. "Réservations" en entier)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: isSelected ? primaryColor : Colors.grey,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
