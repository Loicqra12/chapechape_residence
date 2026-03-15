import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/theme/spacing.dart';

/// Écran générique pour afficher les états de réservation (rejetée, expirée, approuvée)
class BookingStatusScreen extends StatelessWidget {
  final String title;
  final String message;
  final String status;
  final String? bookingId;
  final IconData icon;
  final Color backgroundColor;
  final List<Widget>? actions;

  const BookingStatusScreen({
    Key? key,
    required this.title,
    required this.message,
    required this.status,
    this.bookingId,
    required this.icon,
    required this.backgroundColor,
    this.actions,
  }) : super(key: key);

  /// Écran pour réservation rejetée par l'hôte
  factory BookingStatusScreen.rejected({
    String? bookingId,
    String? residenceId,
    VoidCallback? onNewBooking,
    VoidCallback? onBackToHome,
  }) {
    return BookingStatusScreen(
      title: 'Demande refusée',
      message: 'Votre demande de réservation a été refusée par l\'hôte. '
               'Vous pouvez créer une nouvelle réservation ou explorer d\'autres résidences.',
      status: 'rejected',
      bookingId: bookingId,
      icon: Icons.cancel_outlined,
      backgroundColor: AppTheme.errorColor,
      actions: [
        if (onNewBooking != null)
          _ActionButton(
            label: 'Nouvelle réservation',
            icon: Icons.add_home,
            onPressed: onNewBooking,
            isPrimary: true,
          ),
        _ActionButton(
          label: 'Explorer les résidences',
          icon: Icons.search,
          onPressed: onBackToHome ?? () {},
          isPrimary: false,
        ),
      ],
    );
  }

  /// Écran pour réservation expirée (timer SLA dépassé)
  factory BookingStatusScreen.expired({
    String? bookingId,
    String? residenceId,
    VoidCallback? onNewBooking,
    VoidCallback? onBackToHome,
  }) {
    return BookingStatusScreen(
      title: 'Demande expirée',
      message: 'Votre demande de réservation a expiré. L\'hôte n\'a pas répondu dans les délais. '
               'Vous pouvez créer une nouvelle réservation pour les mêmes dates.',
      status: 'expired',
      bookingId: bookingId,
      icon: Icons.schedule_outlined,
      backgroundColor: Colors.orange,
      actions: [
        if (onNewBooking != null)
          _ActionButton(
            label: 'Réessayer',
            icon: Icons.refresh,
            onPressed: onNewBooking,
            isPrimary: true,
          ),
        _ActionButton(
          label: 'Explorer les résidences',
          icon: Icons.search,
          onPressed: onBackToHome ?? () {},
          isPrimary: false,
        ),
      ],
    );
  }

  /// Écran pour réservation approuvée par l'hôte
  factory BookingStatusScreen.approved({
    String? bookingId,
    VoidCallback? onGoToPayment,
    VoidCallback? onViewDetails,
  }) {
    return BookingStatusScreen(
      title: 'Demande approuvée !',
      message: 'Félicitations ! L\'hôte a approuvé votre demande de réservation. '
               'Vous pouvez maintenant procéder au paiement pour confirmer votre séjour.',
      status: 'approved',
      bookingId: bookingId,
      icon: Icons.check_circle_outlined,
      backgroundColor: Colors.green,
      actions: [
        if (onGoToPayment != null)
          _ActionButton(
            label: 'Payer maintenant',
            icon: Icons.payment,
            onPressed: onGoToPayment,
            isPrimary: true,
          ),
        if (onViewDetails != null)
          _ActionButton(
            label: 'Voir les détails',
            icon: Icons.info_outline,
            onPressed: onViewDetails,
            isPrimary: false,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('État de la réservation'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône principale
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: backgroundColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: backgroundColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 60,
                  color: backgroundColor,
                ),
              ),
              
              AppSpacing.verticalXl,
              
              // Titre
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: backgroundColor,
                ),
                textAlign: TextAlign.center,
              ),
              
              AppSpacing.verticalMd,
              
              // Message explicatif
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              
              AppSpacing.verticalXl,
              
              // Actions
              if (actions != null && actions!.isNotEmpty) ...[
                ...actions!.map((action) => Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.smd),
                  child: action,
                )),
              ],
              
              AppSpacing.verticalLg,
              
              // Bouton retour à l'accueil (toujours présent)
              TextButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text('Retour à l\'accueil'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget pour les boutons d'action dans les écrans d'état
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            side: BorderSide(color: AppTheme.primaryColor),
          ),
        ),
      );
    }
  }
}
