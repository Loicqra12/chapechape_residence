import 'package:flutter/material.dart';
import 'package:chapechape_client/core/models/booking_model.dart';
import 'package:chapechape_client/core/utils/booking_helpers.dart';

/// Widget badge pour afficher le statut d'une réservation
/// Supporte tous les statuts avancés du système de paiement
class ReservationStatusBadge extends StatelessWidget {
  final String status;
  final Booking? booking;
  final BadgeSize size;
  final bool showIcon;
  final bool showAnimation;

  const ReservationStatusBadge({
    super.key,
    required this.status,
    this.booking,
    this.size = BadgeSize.medium,
    this.showIcon = true,
    this.showAnimation = false,
  });

  /// Constructor à partir d'un booking
  factory ReservationStatusBadge.fromBooking(
    Booking booking, {
    BadgeSize size = BadgeSize.medium,
    bool showIcon = true,
    bool showAnimation = false,
  }) {
    return ReservationStatusBadge(
      status: booking.status,
      booking: booking,
      size: size,
      showIcon: showIcon,
      showAnimation: showAnimation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = BookingHelpers.getStatusColor(status);
    final label = BookingHelpers.getStatusLabel(status);
    final icon = _getStatusIcon();

    Widget badge = Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_getBorderRadius()),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon && icon != null) ...[
            Icon(
              icon,
              color: color,
              size: _getIconSize(),
            ),
            SizedBox(width: _getSpacing()),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: _getFontSize(),
              fontWeight: _getFontWeight(),
            ),
          ),
          
          // Indicateur spécial pour timer actif
          if (booking != null && BookingHelpers.hasPaymentTimer(booking!))
            _buildTimerIndicator(color),
        ],
      ),
    );

    // Animation pulsante pour statuts critiques
    if (showAnimation && _shouldAnimate()) {
      return _buildAnimatedBadge(badge, color);
    }

    return badge;
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case BadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
      case BadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case BadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case BadgeSize.small:
        return 8;
      case BadgeSize.medium:
        return 10;
      case BadgeSize.large:
        return 12;
    }
  }

  double _getIconSize() {
    switch (size) {
      case BadgeSize.small:
        return 12;
      case BadgeSize.medium:
        return 16;
      case BadgeSize.large:
        return 20;
    }
  }

  double _getFontSize() {
    switch (size) {
      case BadgeSize.small:
        return 11;
      case BadgeSize.medium:
        return 13;
      case BadgeSize.large:
        return 15;
    }
  }

  FontWeight _getFontWeight() {
    switch (size) {
      case BadgeSize.small:
        return FontWeight.w500;
      case BadgeSize.medium:
        return FontWeight.w600;
      case BadgeSize.large:
        return FontWeight.w700;
    }
  }

  double _getSpacing() {
    switch (size) {
      case BadgeSize.small:
        return 3;
      case BadgeSize.medium:
        return 4;
      case BadgeSize.large:
        return 6;
    }
  }

  IconData? _getStatusIcon() {
    switch (status.toLowerCase()) {
      // Statuts existants
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.play_circle;
      case 'completed':
        return Icons.task_alt;
      case 'cancelled':
        return Icons.cancel;
      case 'expired':
        return Icons.timer_off;
      
      // Nouveaux statuts - Système de Paiement Avancé
      case 'awaiting_approval':
        return Icons.pending_actions;
      case 'payment_pending':
        return Icons.payment;
      case 'rejected':
        return Icons.block;
      case 'payment_expired':
        return Icons.timer_off;
      case 'payment_processing':
        return Icons.sync;
      case 'payment_failed':
        return Icons.error;
      case 'partially_paid':
        return Icons.payments;
      case 'checked_in':
        return Icons.login;
      case 'checked_out':
        return Icons.logout;
      
      default:
        return Icons.info;
    }
  }

  Widget _buildTimerIndicator(Color color) {
    return Container(
      margin: EdgeInsets.only(left: _getSpacing()),
      child: Icon(
        Icons.timer,
        color: color,
        size: _getIconSize() * 0.8,
      ),
    );
  }

  bool _shouldAnimate() {
    const animatedStatuses = [
      'payment_pending',
      'payment_processing', 
      'awaiting_approval',
      'payment_expired',
    ];
    return animatedStatuses.contains(status.toLowerCase());
  }

  Widget _buildAnimatedBadge(Widget badge, Color color) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.8, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: badge,
        );
      },
      onEnd: () {
        // Recommencer l'animation
        if (_shouldAnimate()) {
          Future.delayed(const Duration(milliseconds: 500), () {
            // L'animation se répète automatiquement
          });
        }
      },
    );
  }
}

/// Enum pour les tailles de badge
enum BadgeSize {
  small,
  medium,
  large,
}

/// Widget spécialisé pour les badges avec timer
class PaymentStatusBadge extends StatelessWidget {
  final Booking booking;
  final BadgeSize size;

  const PaymentStatusBadge({
    super.key,
    required this.booking,
    this.size = BadgeSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    // Si le booking a un timer actif, afficher avec animation
    final hasTimer = BookingHelpers.hasPaymentTimer(booking);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ReservationStatusBadge.fromBooking(
          booking,
          size: size,
          showAnimation: hasTimer,
        ),
        
        if (hasTimer) ...[
          const SizedBox(width: 8),
          _buildTimeRemaining(),
        ],
      ],
    );
  }

  Widget _buildTimeRemaining() {
    final timeRemaining = BookingHelpers.getPaymentTimeRemaining(booking);
    final color = BookingHelpers.getStatusColor(booking.status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        BookingHelpers.formatTimeRemaining(timeRemaining),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Extension pour utilisation facile
extension BookingStatusBadgeExtension on Booking {
  Widget statusBadge({
    BadgeSize size = BadgeSize.medium,
    bool showIcon = true,
    bool showAnimation = false,
  }) {
    return ReservationStatusBadge.fromBooking(
      this,
      size: size,
      showIcon: showIcon,
      showAnimation: showAnimation,
    );
  }

  Widget paymentStatusBadge({
    BadgeSize size = BadgeSize.medium,
  }) {
    return PaymentStatusBadge(
      booking: this,
      size: size,
    );
  }
}
