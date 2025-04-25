import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/promotion_model.dart';
import '../../core/utils/responsive_utils.dart';

/// Widget affichant un compte à rebours animé pour les promotions à durée limitée
class PromotionCountdownWidget extends StatefulWidget {
  /// La promotion pour laquelle afficher le compte à rebours
  final Promotion promotion;
  
  /// Affiche une version compacte du widget
  final bool isCompact;
  
  /// Si non-null, sera appelé lorsque le compte à rebours atteint zéro
  final VoidCallback? onExpired;
  
  const PromotionCountdownWidget({
    Key? key,
    required this.promotion,
    this.isCompact = false,
    this.onExpired,
  }) : super(key: key);

  @override
  State<PromotionCountdownWidget> createState() => _PromotionCountdownWidgetState();
}

class _PromotionCountdownWidgetState extends State<PromotionCountdownWidget> with SingleTickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _pulseController;
  
  // Valeurs calculées pour le compte à rebours
  int _days = 0;
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;
  bool _isUrgent = false; // Moins d'une heure restante
  bool _isExpired = false;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseController.repeat(reverse: true);
    
    // Calcul initial des valeurs
    _calculateRemainingTime();
    
    // Mise à jour toutes les secondes
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateRemainingTime();
    });
  }
  
  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }
  
  void _calculateRemainingTime() {
    final now = DateTime.now();
    final difference = widget.promotion.endDate.difference(now);
    
    // Si la promotion est expirée
    if (difference.isNegative) {
      if (!_isExpired) {
        setState(() {
          _days = 0;
          _hours = 0;
          _minutes = 0;
          _seconds = 0;
          _isExpired = true;
          _isUrgent = false;
        });
        
        if (widget.onExpired != null) {
          widget.onExpired!();
        }
      }
      return;
    }
    
    // Mettre à jour les valeurs
    setState(() {
      _days = difference.inDays;
      _hours = difference.inHours % 24;
      _minutes = difference.inMinutes % 60;
      _seconds = difference.inSeconds % 60;
      _isUrgent = difference.inHours < 1;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isExpired) {
      return _buildExpiredBadge();
    }
    
    return widget.isCompact ? _buildCompactCountdown() : _buildFullCountdown();
  }
  
  Widget _buildFullCountdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isUrgent ? Colors.red : Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: (_isUrgent ? Colors.red : Colors.black).withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                color: Colors.white,
                size: 16,
              )
              .animate(controller: _pulseController, target: _isUrgent ? 1 : 0)
              .scale(begin: const Offset(1, 1), end: const Offset(1.3, 1.3)),
              
              const SizedBox(width: 6),
              
              Text(
                'Expire dans',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.responsiveFontSize(12),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_days > 0) ...[
                _buildTimeDigit(_days.toString()),
                _buildTimeSeparator('j'),
              ],
              
              _buildTimeDigit(_hours.toString().padLeft(2, '0')),
              _buildTimeSeparator('h'),
              
              _buildTimeDigit(_minutes.toString().padLeft(2, '0')),
              _buildTimeSeparator('m'),
              
              _buildTimeDigit(_seconds.toString().padLeft(2, '0')),
              _buildTimeSeparator('s'),
            ],
          ),
        ],
      )
      .animate(target: _isUrgent ? 1 : 0)
      .shimmer(duration: 1500.ms, color: Colors.white30, delay: 200.ms, stops: [0, 0.5, 1]),
    );
  }
  
  Widget _buildCompactCountdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isUrgent ? Colors.red.withOpacity(0.9) : Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: Colors.white,
            size: 12,
          )
          .animate(controller: _pulseController, target: _isUrgent ? 1 : 0)
          .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
          
          const SizedBox(width: 4),
          
          Text(
            _days > 0 
                ? '${_days}j ${_hours}h'
                : _hours > 0 
                    ? '${_hours}h ${_minutes}m'
                    : '${_minutes}m ${_seconds}s',
            style: TextStyle(
              color: Colors.white,
              fontSize: context.responsiveFontSize(10),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    )
    .animate(target: _isUrgent ? 1 : 0)
    .shimmer(duration: 1200.ms, color: Colors.white24, delay: 300.ms, stops: [0, 0.5, 1]);
  }
  
  Widget _buildExpiredBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer_off,
            color: Colors.white,
            size: 12,
          ),
          
          const SizedBox(width: 4),
          
          Text(
            'Expirée',
            style: TextStyle(
              color: Colors.white,
              fontSize: context.responsiveFontSize(10),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeDigit(String digit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        digit,
        style: TextStyle(
          color: Colors.white,
          fontSize: context.responsiveFontSize(11),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildTimeSeparator(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: context.responsiveFontSize(9),
        ),
      ),
    );
  }
}
