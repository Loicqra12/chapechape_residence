import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chapechape_client/core/models/booking_model.dart';
import 'package:chapechape_client/core/utils/booking_helpers.dart';

/// Widget de timer de paiement avec countdown circulaire
/// Affiche le temps restant pour effectuer le paiement d'une réservation
class PaymentTimerWidget extends StatefulWidget {
  final Booking booking;
  final VoidCallback? onTimerExpired;
  final VoidCallback? onExtendDeadline;
  final bool showExtendOption;
  final double size;
  final Color? primaryColor;
  final Color? backgroundColor;

  const PaymentTimerWidget({
    super.key,
    required this.booking,
    this.onTimerExpired,
    this.onExtendDeadline,
    this.showExtendOption = true,
    this.size = 120.0,
    this.primaryColor,
    this.backgroundColor,
  });

  @override
  State<PaymentTimerWidget> createState() => _PaymentTimerWidgetState();
}

class _PaymentTimerWidgetState extends State<PaymentTimerWidget>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _timeRemaining = 0;
  int _totalTime = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    
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

  @override
  void didUpdateWidget(PaymentTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.booking.paymentDeadline != widget.booking.paymentDeadline) {
      _initializeTimer();
    }
  }

  void _initializeTimer() {
    // Calculer le temps restant
    _timeRemaining = BookingHelpers.getPaymentTimeRemaining(widget.booking);
    _totalTime = widget.booking.paymentTimerDuration;
    
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
        _timeRemaining = BookingHelpers.getPaymentTimeRemaining(widget.booking);
        
        if (_timeRemaining <= 0) {
          _isExpired = true;
          timer.cancel();
          widget.onTimerExpired?.call();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Color get _primaryColor {
    if (widget.primaryColor != null) return widget.primaryColor!;
    
    // Couleur dynamique selon le temps restant
    if (_isExpired) return Colors.red;
    if (_timeRemaining <= 5) return Colors.red[600]!;
    if (_timeRemaining <= 15) return Colors.orange[600]!;
    return Theme.of(context).primaryColor;
  }

  Color get _backgroundColor {
    return widget.backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  double get _progress {
    if (_totalTime <= 0) return 0.0;
    return (_timeRemaining / _totalTime).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (!BookingHelpers.hasPaymentTimer(widget.booking)) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Timer circulaire
              SizedBox(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  children: [
                    // Background circle
                    SizedBox(
                      width: widget.size,
                      height: widget.size,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 8,
                        backgroundColor: _backgroundColor,
                        valueColor: AlwaysStoppedAnimation(_backgroundColor),
                      ),
                    ),
                    
                    // Progress circle
                    SizedBox(
                      width: widget.size,
                      height: widget.size,
                      child: CircularProgressIndicator(
                        value: _progress,
                        strokeWidth: 8,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(_primaryColor),
                      ),
                    ),
                    
                    // Timer text au centre
                    SizedBox(
                      width: widget.size,
                      height: widget.size,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isExpired)
                              Icon(
                                Icons.timer_off,
                                color: Colors.red,
                                size: widget.size * 0.25,
                              )
                            else
                              Icon(
                                Icons.timer,
                                color: _primaryColor,
                                size: widget.size * 0.2,
                              ),
                            
                            const SizedBox(height: 4),
                            
                            Text(
                              _isExpired 
                                  ? 'Expiré' 
                                  : BookingHelpers.formatTimeRemaining(_timeRemaining),
                              style: TextStyle(
                                fontSize: widget.size * 0.12,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Instructions et actions
              _buildInstructions(),
              
              if (widget.showExtendOption && !_isExpired)
                const SizedBox(height: 12),
              
              if (widget.showExtendOption && !_isExpired)
                _buildExtendButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstructions() {
    if (_isExpired) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[600], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Délai de paiement expiré. Votre réservation a été annulée.',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.payment,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Effectuez votre paiement avant l\'expiration du délai.',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtendButton() {
    return OutlinedButton(
      onPressed: widget.onExtendDeadline,
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).primaryColor,
        side: BorderSide(color: Theme.of(context).primaryColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 16),
          const SizedBox(width: 4),
          Text('Prolonger le délai'),
        ],
      ),
    );
  }
}

/// Widget simplifié pour affichage compact
class CompactPaymentTimer extends StatelessWidget {
  final Booking booking;
  final double size;

  const CompactPaymentTimer({
    super.key,
    required this.booking,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!BookingHelpers.hasPaymentTimer(booking)) {
      return const SizedBox.shrink();
    }

    final timeRemaining = BookingHelpers.getPaymentTimeRemaining(booking);
    final isExpired = timeRemaining <= 0;
    
    Color color = Theme.of(context).primaryColor;
    if (isExpired) color = Colors.red;
    else if (timeRemaining <= 5) color = Colors.red[600]!;
    else if (timeRemaining <= 15) color = Colors.orange[600]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired ? Icons.timer_off : Icons.timer,
            color: color,
            size: size * 0.6,
          ),
          const SizedBox(width: 4),
          Text(
            isExpired 
                ? 'Expiré' 
                : BookingHelpers.formatTimeRemaining(timeRemaining),
            style: TextStyle(
              color: color,
              fontSize: size * 0.35,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
