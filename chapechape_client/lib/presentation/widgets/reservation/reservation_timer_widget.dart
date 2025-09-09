import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chapechape_client/core/models/booking_model.dart';
import 'package:chapechape_client/core/utils/booking_helpers.dart';

/// Types de timers supportés par le widget
enum TimerType {
  payment,        // Timer de paiement
  hostApproval,   // Timer SLA d'approbation hôte
  custom          // Timer personnalisé
}

/// Configuration d'affichage pour chaque type de timer
class TimerConfig {
  final String title;
  final String message;
  final IconData icon;
  final Color primaryColor;
  final Color backgroundColor;
  final String actionButtonText;
  final String? secondaryActionText;

  const TimerConfig({
    required this.title,
    required this.message,
    required this.icon,
    required this.primaryColor,
    required this.backgroundColor,
    required this.actionButtonText,
    this.secondaryActionText,
  });

  static const payment = TimerConfig(
    title: "Temps restant pour payer",
    message: "Votre réservation sera annulée si le paiement n'est pas effectué à temps.",
    icon: Icons.payment,
    primaryColor: Color(0xFFE53E3E), // Rouge
    backgroundColor: Color(0xFFFED7D7),
    actionButtonText: "Payer maintenant",
    secondaryActionText: "Étendre la deadline",
  );

  static const hostApproval = TimerConfig(
    title: "En attente d'approbation",
    message: "L'hôte examine votre demande de réservation. Vous serez notifié de sa décision.",
    icon: Icons.hourglass_top,
    primaryColor: Color(0xFFD69E2E), // Orange/Ambre
    backgroundColor: Color(0xFFFAF089),
    actionButtonText: "Annuler la demande",
    secondaryActionText: "Modifier les dates",
  );
}

/// Widget de timer générique pour différents types de réservation
/// Supporte le timer de paiement et le timer SLA d'approbation hôte
class ReservationTimerWidget extends StatefulWidget {
  final Booking booking;
  final TimerType type;
  final VoidCallback? onTimerExpired;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onSecondaryAction;
  final bool showActions;
  final double size;
  final TimerConfig? customConfig;

  const ReservationTimerWidget({
    super.key,
    required this.booking,
    required this.type,
    this.onTimerExpired,
    this.onPrimaryAction,
    this.onSecondaryAction,
    this.showActions = true,
    this.size = 120.0,
    this.customConfig,
  });

  @override
  State<ReservationTimerWidget> createState() => _ReservationTimerWidgetState();
}

class _ReservationTimerWidgetState extends State<ReservationTimerWidget>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _timeRemaining = 0;
  int _totalTime = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpired = false;
  late TimerConfig _config;

  @override
  void initState() {
    super.initState();
    
    // Configurer selon le type
    _setupConfig();
    
    // Initialiser l'animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _initializeTimer();
    _animationController.forward();
  }

  void _setupConfig() {
    switch (widget.type) {
      case TimerType.payment:
        _config = TimerConfig.payment;
        break;
      case TimerType.hostApproval:
        _config = TimerConfig.hostApproval;
        break;
      case TimerType.custom:
        _config = widget.customConfig ?? TimerConfig.payment;
        break;
    }
  }

  @override
  void didUpdateWidget(ReservationTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.booking != widget.booking || oldWidget.type != widget.type) {
      _setupConfig();
      _initializeTimer();
    }
  }

  void _initializeTimer() {
    // Calculer le temps selon le type
    switch (widget.type) {
      case TimerType.payment:
        _timeRemaining = BookingHelpers.getPaymentTimeRemaining(widget.booking) * 60; // Convertir minutes en secondes
        _totalTime = widget.booking.paymentTimerDuration * 60;
        break;
      case TimerType.hostApproval:
        _timeRemaining = BookingHelpers.getHostApprovalTimeRemaining(widget.booking);
        _totalTime = widget.booking.hostApprovalTimerDuration * 60;
        break;
      case TimerType.custom:
        // Pour les timers personnalisés, utiliser la logique par défaut
        _timeRemaining = 0;
        _totalTime = 0;
        break;
    }

    // Vérifier si déjà expiré
    if (_timeRemaining <= 0) {
      _isExpired = true;
      widget.onTimerExpired?.call();
      return;
    }

    // Démarrer le timer
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining = _getUpdatedTimeRemaining();
        
        if (_timeRemaining <= 0) {
          _isExpired = true;
          timer.cancel();
          widget.onTimerExpired?.call();
        }
      });
    });
  }

  int _getUpdatedTimeRemaining() {
    switch (widget.type) {
      case TimerType.payment:
        return BookingHelpers.getPaymentTimeRemaining(widget.booking) * 60;
      case TimerType.hostApproval:
        return BookingHelpers.getHostApprovalTimeRemaining(widget.booking);
      case TimerType.custom:
        return 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  double get _progress {
    if (_totalTime <= 0) return 0.0;
    return (_totalTime - _timeRemaining) / _totalTime;
  }

  String get _formattedTime {
    switch (widget.type) {
      case TimerType.payment:
        return BookingHelpers.formatTimeRemaining(_timeRemaining ~/ 60); // Convertir secondes en minutes
      case TimerType.hostApproval:
        return BookingHelpers.formatHostApprovalTimeRemaining(_timeRemaining);
      case TimerType.custom:
        return "00:00";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isExpired) {
      return _buildExpiredState(context);
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Transform.scale(
              scale: _animation.value,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: _config.backgroundColor,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: _config.primaryColor.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: _config.primaryColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTimerCircle(context),
                      const SizedBox(height: 16),
                      _buildTimerInfo(context),
                      if (widget.showActions) ...[
                        const SizedBox(height: 16),
                        _buildActionButtons(context),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimerCircle(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cercle de progression
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(
              value: _progress,
              strokeWidth: 8.0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_config.primaryColor),
            ),
          ),
          // Icône et temps
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _config.icon,
                color: _config.primaryColor,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                _formattedTime,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _config.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerInfo(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _config.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _config.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 50),
          child: Text(
            _config.message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onPrimaryAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: _config.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(_config.actionButtonText),
            ),
          ),
        ),
        if (_config.secondaryActionText != null) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.onSecondaryAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _config.primaryColor,
                  side: BorderSide(color: _config.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(_config.secondaryActionText!),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExpiredState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_off,
            size: widget.size * 0.4,
            color: Colors.grey[500],
          ),
          const SizedBox(height: 16),
          Text(
            "Temps écoulé",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.type == TimerType.hostApproval 
                ? "La demande d'approbation a expiré"
                : "Le délai de paiement est dépassé",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Widget compact pour affichage en ligne
class CompactReservationTimer extends StatelessWidget {
  final Booking booking;
  final TimerType type;
  final VoidCallback? onTap;

  const CompactReservationTimer({
    super.key,
    required this.booking,
    required this.type,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final config = type == TimerType.hostApproval 
        ? TimerConfig.hostApproval 
        : TimerConfig.payment;
    
    final timeRemaining = type == TimerType.hostApproval
        ? BookingHelpers.getHostApprovalTimeRemaining(booking)
        : BookingHelpers.getPaymentTimeRemaining(booking) * 60;

    final formattedTime = type == TimerType.hostApproval
        ? BookingHelpers.formatHostApprovalTimeRemaining(timeRemaining)
        : BookingHelpers.formatTimeRemaining(timeRemaining ~/ 60);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: config.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: config.primaryColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              config.icon,
              size: 16,
              color: config.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              formattedTime,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: config.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
