import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Bannière de statistiques animée à afficher sur la page d'accueil
class StatsBar extends StatelessWidget {
  const StatsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD93D),
            Color(0xFFFF8C42),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF8C42).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(
            icon: Icons.home,
            value: '243',
            label: 'Résidences',
            context: context,
          ),
          _buildDivider(),
          _buildStat(
            icon: Icons.location_city,
            value: '15',
            label: 'Villes',
            context: context,
          ),
          _buildDivider(),
          _buildStat(
            icon: Icons.star,
            value: '4.8★',
            label: 'Note',
            context: context,
          ),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 600.ms, delay: 300.ms)
    .slideY(begin: 0.1, end: 0, duration: 600.ms, delay: 300.ms);
  }

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
    required BuildContext context,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.5))
        .shake(hz: 0.5, duration: 2000.ms),
        
        const SizedBox(height: 8),
        
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .scaleXY(
          begin: 1.0,
          end: 1.1,
          duration: 1500.ms,
          curve: Curves.easeInOut,
        )
        .then()
        .scaleXY(
          begin: 1.1,
          end: 1.0,
          duration: 1500.ms,
          curve: Curves.easeInOut,
        ),
        
        const SizedBox(height: 4),
        
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 60,
      width: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(0.4),
            Colors.white.withOpacity(0.0),
          ],
        ),
      ),
    );
  }
}
