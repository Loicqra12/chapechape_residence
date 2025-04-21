// lib/presentation/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Liste des icônes correspondant aux différentes destinations
    final iconList = <IconData>[
      Icons.home,
      Icons.search,
      Icons.favorite,
      Icons.person,
    ];

    // Liste des labels correspondant aux icônes
    final labelList = [
      'Accueil',
      'Recherche',
      'Favoris',
      'Profil',
    ];

    return AnimatedBottomNavigationBar.builder(
      itemCount: iconList.length,
      tabBuilder: (int index, bool isActive) {
        // Couleurs personnalisées basées sur l'état actif/inactif
        final color = isActive 
            ? const Color(0xFFFFD700) // Gold pour actif
            : Colors.black.withOpacity(0.5); // Gris pour inactif
            
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconList[index],
              size: 24,
              color: color,
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                labelList[index],
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      activeIndex: currentIndex,
      splashColor: const Color(0xFFFFD700),
      notchSmoothness: NotchSmoothness.softEdge,
      gapLocation: GapLocation.none,
      leftCornerRadius: 12,
      rightCornerRadius: 12,
      elevation: 8,
      onTap: onTap,
      shadow: const BoxShadow(
        offset: Offset(0, 1),
        blurRadius: 8,
        spreadRadius: 1,
        color: Colors.black12,
      ),
    );
  }
}