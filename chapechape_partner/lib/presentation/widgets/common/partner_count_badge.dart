import 'package:flutter/material.dart';

import '../../../core/models/reservation/reservation.dart';

/// Pastille type apps grand public : rouge vif, lisible, bord blanc pour contraste.
class PartnerCountBadge extends StatelessWidget {
  final int count;
  final bool compact;

  const PartnerCountBadge({
    super.key,
    required this.count,
    this.compact = false,
  });

  static const Color _bloodRed = Color(0xFFC62828);

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final text = count > 99 ? '99+' : '$count';
    final padH = compact ? 5.0 : 7.0;
    final padV = compact ? 2.0 : 3.0;
    final fontSize = compact ? 10.0 : 11.5;
    final minSide = compact ? 18.0 : 22.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: _bloodRed,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: _bloodRed.withOpacity(0.55),
            blurRadius: compact ? 4 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: BoxConstraints(minWidth: minSide, minHeight: minSide),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: -0.2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Réservations à signaler au partenaire (action hôte ou paiement client en attente).
int partnerReservationAttentionCount(List<Reservation> reservations) {
  return reservations
      .where(
        (r) =>
            r.status.requiresPartnerAction ||
            r.status == ReservationStatus.paymentPending,
      )
      .length;
}
