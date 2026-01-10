import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Représente un élément de breadcrumb
class BreadcrumbItem {
  final String label;
  final String? route;
  final IconData? icon;

  const BreadcrumbItem({
    required this.label,
    this.route,
    this.icon,
  });
}

/// Widget de breadcrumb pour améliorer la navigation
class BreadcrumbWidget extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final Color? textColor;
  final Color? activeColor;
  final double fontSize;

  const BreadcrumbWidget({
    super.key,
    required this.items,
    this.textColor,
    this.activeColor,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTextColor = textColor ?? theme.colorScheme.onSurface.withOpacity(0.6);
    final defaultActiveColor = activeColor ?? theme.primaryColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              _buildBreadcrumbItem(
                context,
                items[i],
                isLast: i == items.length - 1,
                textColor: defaultTextColor,
                activeColor: defaultActiveColor,
              ),
              if (i < items.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: defaultTextColor,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbItem(
    BuildContext context,
    BreadcrumbItem item, {
    required bool isLast,
    required Color textColor,
    required Color activeColor,
  }) {
    final isClickable = !isLast && item.route != null;
    final effectiveColor = isLast ? activeColor : textColor;

    return GestureDetector(
      onTap: isClickable
          ? () {
              context.go(item.route!);
            }
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.icon != null) ...[
            Icon(
              item.icon,
              size: fontSize + 2,
              color: effectiveColor,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            item.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
              color: effectiveColor,
              decoration: isClickable ? TextDecoration.underline : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de breadcrumb avec fond coloré (pour les headers)
class ElevatedBreadcrumbWidget extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final Color? backgroundColor;

  const ElevatedBreadcrumbWidget({
    super.key,
    required this.items,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBgColor = backgroundColor ?? theme.colorScheme.surface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: effectiveBgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BreadcrumbWidget(items: items),
    );
  }
}

/// Helper class pour créer facilement des breadcrumbs communs
class CommonBreadcrumbs {
  /// Breadcrumbs pour l'écran de création de résidence
  static List<BreadcrumbItem> residenceCreate() {
    return [
      const BreadcrumbItem(
        label: 'Accueil',
        route: '/home',
        icon: Icons.home,
      ),
      const BreadcrumbItem(
        label: 'Mes Résidences',
        route: '/residences',
        icon: Icons.apartment,
      ),
      const BreadcrumbItem(
        label: 'Nouvelle Résidence',
      ),
    ];
  }

  /// Breadcrumbs pour l'écran d'édition de résidence
  static List<BreadcrumbItem> residenceEdit(String residenceName) {
    return [
      const BreadcrumbItem(
        label: 'Accueil',
        route: '/home',
        icon: Icons.home,
      ),
      const BreadcrumbItem(
        label: 'Mes Résidences',
        route: '/residences',
        icon: Icons.apartment,
      ),
      BreadcrumbItem(
        label: residenceName,
      ),
    ];
  }

  /// Breadcrumbs pour les détails d'une résidence
  static List<BreadcrumbItem> residenceDetails(String residenceName) {
    return [
      const BreadcrumbItem(
        label: 'Accueil',
        route: '/home',
        icon: Icons.home,
      ),
      const BreadcrumbItem(
        label: 'Mes Résidences',
        route: '/residences',
        icon: Icons.apartment,
      ),
      BreadcrumbItem(
        label: residenceName,
      ),
    ];
  }

  /// Breadcrumbs pour les détails d'une réservation
  static List<BreadcrumbItem> reservationDetails(String reservationRef) {
    return [
      const BreadcrumbItem(
        label: 'Accueil',
        route: '/home',
        icon: Icons.home,
      ),
      const BreadcrumbItem(
        label: 'Réservations',
        route: '/reservations',
        icon: Icons.calendar_month,
      ),
      BreadcrumbItem(
        label: 'Réservation #$reservationRef',
      ),
    ];
  }

  /// Breadcrumbs pour l'écran de paiement
  static List<BreadcrumbItem> payments() {
    return [
      const BreadcrumbItem(
        label: 'Accueil',
        route: '/home',
        icon: Icons.home,
      ),
      const BreadcrumbItem(
        label: 'Paiements & Reversements',
        icon: Icons.account_balance_wallet,
      ),
    ];
  }

  /// Breadcrumbs pour les paramètres
  static List<BreadcrumbItem> settings(String? subsection) {
    return [
      const BreadcrumbItem(
        label: 'Accueil',
        route: '/home',
        icon: Icons.home,
      ),
      const BreadcrumbItem(
        label: 'Paramètres',
        route: '/settings',
        icon: Icons.settings,
      ),
      if (subsection != null)
        BreadcrumbItem(
          label: subsection,
        ),
    ];
  }

  /// Breadcrumbs pour l'écran de profil
  static List<BreadcrumbItem> profile() {
    return [
      const BreadcrumbItem(
        label: 'Accueil',
        route: '/home',
        icon: Icons.home,
      ),
      const BreadcrumbItem(
        label: 'Mon Profil',
        icon: Icons.person,
      ),
    ];
  }

  /// Breadcrumbs pour les messages/chat
  static List<BreadcrumbItem> messages(String? conversationName) {
    return [
      const BreadcrumbItem(
        label: 'Accueil',
        route: '/home',
        icon: Icons.home,
      ),
      const BreadcrumbItem(
        label: 'Messages',
        route: '/messages',
        icon: Icons.message,
      ),
      if (conversationName != null)
        BreadcrumbItem(
          label: conversationName,
        ),
    ];
  }

  /// Breadcrumbs pour les notifications
  static List<BreadcrumbItem> notifications() {
    return [
      const BreadcrumbItem(
        label: 'Accueil',
        route: '/home',
        icon: Icons.home,
      ),
      const BreadcrumbItem(
        label: 'Notifications',
        icon: Icons.notifications,
      ),
    ];
  }

  /// Breadcrumbs pour les avis
  static List<BreadcrumbItem> reviews() {
    return [
      const BreadcrumbItem(
        label: 'Accueil',
        route: '/home',
        icon: Icons.home,
      ),
      const BreadcrumbItem(
        label: 'Avis Clients',
        icon: Icons.star,
      ),
    ];
  }

  /// Breadcrumbs pour l'aide
  static List<BreadcrumbItem> help(String? topic) {
    return [
      const BreadcrumbItem(
        label: 'Accueil',
        route: '/home',
        icon: Icons.home,
      ),
      const BreadcrumbItem(
        label: 'Aide & Support',
        route: '/help',
        icon: Icons.help_outline,
      ),
      if (topic != null)
        BreadcrumbItem(
          label: topic,
        ),
    ];
  }
}

