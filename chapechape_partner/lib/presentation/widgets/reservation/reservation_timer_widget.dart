import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/models/reservation/reservation.dart';

enum ReservationTimerDisplayMode {
  compact,  // Badge compact pour listes
  full,     // Widget complet pour détails
  banner    // Bannière d'alerte Partner
}

/// Widget Timer SLA pour Partner - Compte à rebours d'approbation hôte
class ReservationTimerWidget extends StatefulWidget {
  final Reservation reservation;
  final ReservationTimerDisplayMode displayMode;
  final VoidCallback? onExpired;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const ReservationTimerWidget({
    Key? key,
    required this.reservation,
    this.displayMode = ReservationTimerDisplayMode.full,
    this.onExpired,
    this.onApprove,
    this.onReject,
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
  bool _isExpired = false;

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
        setState(() {
          _isExpired = true;
        });
        widget.onExpired?.call();
      }
    });
  }

  void _updateTimerDisplay() {
    final now = DateTime.now();
    
    // Timer SLA d'approbation hôte (awaiting_approval) — deadline Backend
    if (widget.reservation.status == ReservationStatus.awaitingApproval) {
      final deadline = widget.reservation.hostApprovalDeadline ??
          widget.reservation.createdAt.add(const Duration(hours: 8));
      
      if (now.isBefore(deadline)) {
        setState(() {
          _remainingTime = deadline.difference(now);
          _timerType = 'Temps pour répondre';
          _timerColor = _getRemainingTimeColor(_remainingTime!);
          _timerIcon = Icons.schedule;
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

  Color _getRemainingTimeColor(Duration remaining) {
    final totalHours = remaining.inHours;
    if (totalHours > 12) return Colors.green;
    if (totalHours > 6) return Colors.orange;
    if (totalHours > 2) return Colors.deepOrange;
    return Colors.red;
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}j ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si aucun timer actif, ne rien afficher
    if (_remainingTime == null && !_isExpired) {
      return const SizedBox.shrink();
    }

    // Si expiré, afficher message d'expiration
    if (_isExpired) {
      return _buildExpiredWidget(context);
    }

    // Afficher le timer selon le mode
    switch (widget.displayMode) {
      case ReservationTimerDisplayMode.compact:
        return _buildCompactTimer(context);
      case ReservationTimerDisplayMode.banner:
        return _buildBannerTimer(context);
      case ReservationTimerDisplayMode.full:
      default:
        return _buildFullTimer(context);
    }
  }

  Widget _buildCompactTimer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            size: 14,
            color: _timerColor,
          ),
          const SizedBox(width: 4),
          Text(
            _formatDuration(_remainingTime!),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _timerColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerTimer(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _timerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _timerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _timerIcon,
            color: _timerColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _timerType,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _timerColor,
                  ),
                ),
                Text(
                  _formatDuration(_remainingTime!),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _timerColor,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onApprove != null || widget.onReject != null) ...[
            const SizedBox(width: 8),
            _buildQuickActions(context),
          ],
        ],
      ),
    );
  }

  Widget _buildFullTimer(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _timerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _timerIcon,
                    color: _timerColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _timerType,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _formatDuration(_remainingTime!),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _timerColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onApprove != null)
          IconButton(
            onPressed: widget.onApprove,
            icon: const Icon(Icons.check, color: Colors.green),
            tooltip: 'Approuver',
            iconSize: 20,
          ),
        if (widget.onReject != null)
          IconButton(
            onPressed: widget.onReject,
            icon: const Icon(Icons.close, color: Colors.red),
            tooltip: 'Rejeter',
            iconSize: 20,
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (widget.reservation.status != ReservationStatus.awaitingApproval) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isExpired ? null : widget.onReject,
            icon: const Icon(Icons.close, color: Colors.red),
            label: const Text(
              'Rejeter',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isExpired ? null : widget.onApprove,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Approuver'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpiredWidget(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.timer_off,
            color: Colors.red,
            size: 32,
          ),
          const SizedBox(height: 8),
          const Text(
            'Délai d\'approbation expiré',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Cette demande a expiré. Les dates ont été libérées.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Helper pour déterminer si une réservation a un timer actif
class ReservationTimerHelper {
  static bool hasActiveTimer(Reservation reservation) {
    final now = DateTime.now();
    
    // Timer SLA d'approbation hôte
    if (reservation.status == ReservationStatus.awaitingApproval) {
      final deadline = reservation.createdAt.add(const Duration(hours: 24));
      return now.isBefore(deadline);
    }
    
    return false;
  }
  
  static Duration? getRemainingTime(Reservation reservation) {
    if (!hasActiveTimer(reservation)) return null;
    
    final now = DateTime.now();
    final deadline = reservation.createdAt.add(const Duration(hours: 24));
    
    return deadline.difference(now);
  }
  
  static String getTimerType(Reservation reservation) {
    if (reservation.status == ReservationStatus.awaitingApproval) {
      return 'Temps pour répondre';
    }
    
    return '';
  }
}
