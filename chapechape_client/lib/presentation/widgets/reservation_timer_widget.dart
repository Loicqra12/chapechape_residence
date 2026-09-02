import 'package:flutter/material.dart';
import 'dart:async';
import 'package:chapechape_client/core/models/booking_model.dart';
import 'package:chapechape_client/core/utils/booking_helpers.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';

enum ReservationTimerDisplayMode {
  compact,  // Badge compact pour listes
  full,     // Widget complet pour détails
  banner    // Bannière d'alerte
}

/// Widget générique pour afficher les timers de réservation (SLA hôte et paiement)
class ReservationTimerWidget extends StatefulWidget {
  final Booking booking;
  final ReservationTimerDisplayMode displayMode;
  final VoidCallback? onExpired;
  final VoidCallback? onRetry;

  const ReservationTimerWidget({
    Key? key,
    required this.booking,
    this.displayMode = ReservationTimerDisplayMode.full,
    this.onExpired,
    this.onRetry,
  }) : super(key: key);

  @override
  State<ReservationTimerWidget> createState() => _ReservationTimerWidgetState();
}

class _ReservationTimerWidgetState extends State<ReservationTimerWidget> {
  Timer? _timer;
  Duration? _remainingTime;
  String _timerType = '';
  Color _timerColor = Colors.orange;
  IconData _timerIcon = Icons.schedule;

  @override
  void initState() {
    super.initState();
    _updateTimerDisplay();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimerDisplay();
      
      if (_remainingTime != null && _remainingTime!.inSeconds <= 0) {
        timer.cancel();
        widget.onExpired?.call();
      }
    });
  }

  void _updateTimerDisplay() {
    final now = DateTime.now();
    
    // Vérifier d'abord le timer SLA hôte (awaiting_approval)
    if (widget.booking.status == 'awaiting_approval' && 
        widget.booking.hostApprovalDeadline != null) {
      final deadline = widget.booking.hostApprovalDeadline!;
      if (now.isBefore(deadline)) {
        setState(() {
          _remainingTime = deadline.difference(now);
          _timerType = 'Approbation hôte';
          _timerColor = Colors.orange;
          _timerIcon = Icons.schedule;
        });
        return;
      }
    }
    
    if (widget.booking.status == 'payment_pending' &&
        widget.booking.paymentDeadline != null) {
      final deadline = widget.booking.paymentDeadline!;
      if (now.isBefore(deadline)) {
        setState(() {
          _remainingTime = deadline.difference(now);
          _timerType = 'Paiement requis';
          _timerColor = Colors.red;
          _timerIcon = Icons.payment;
        });
        return;
      }
    }

    // Aucun timer actif
    setState(() {
      _remainingTime = null;
      _timerType = '';
    });
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}min';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}min ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si aucun timer actif, ne rien afficher
    if (_remainingTime == null || _remainingTime!.inSeconds <= 0) {
      return const SizedBox.shrink();
    }

    switch (widget.displayMode) {
      case ReservationTimerDisplayMode.compact:
        return _buildCompactTimer();
      case ReservationTimerDisplayMode.full:
        return _buildFullTimer();
      case ReservationTimerDisplayMode.banner:
        return _buildBannerTimer();
    }
  }

  Widget _buildCompactTimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _timerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _timerColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _timerIcon,
            size: 12,
            color: _timerColor,
          ),
          const SizedBox(width: 4),
          Text(
            _formatDuration(_remainingTime!),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _timerColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullTimer() {
    final isUrgent = _remainingTime!.inMinutes < 30;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUrgent 
            ? Colors.red.withOpacity(0.1)
            : _timerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent 
              ? Colors.red.withOpacity(0.3)
              : _timerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _timerIcon,
                color: isUrgent ? Colors.red : _timerColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _timerType,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isUrgent ? Colors.red : _timerColor,
                      ),
                    ),
                    Text(
                      _getTimerDescription(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isUrgent ? Colors.red : _timerColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatDuration(_remainingTime!),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (isUrgent && widget.onRetry != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(_getRetryButtonText()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBannerTimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _timerColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _timerIcon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _timerType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Temps restant: ${_formatDuration(_remainingTime!)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onRetry != null)
            TextButton(
              onPressed: widget.onRetry,
              child: Text(
                _getRetryButtonText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getTimerDescription() {
    if (_timerType == 'Approbation hôte') {
      return 'En attente de confirmation par l\'hôte';
    } else if (_timerType == 'Paiement requis') {
      return 'Votre réservation sera annulée sans paiement';
    }
    return '';
  }

  String _getRetryButtonText() {
    if (_timerType == 'Approbation hôte') {
      return 'Nouvelle recherche';
    } else if (_timerType == 'Paiement requis') {
      return 'Payer maintenant';
    }
    return 'Action';
  }
}
