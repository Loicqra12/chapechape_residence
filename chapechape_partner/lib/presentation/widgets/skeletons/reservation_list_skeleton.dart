import 'package:flutter/material.dart';
import 'reservation_card_skeleton.dart';

/// Skeleton loader pour une liste de réservations
class ReservationListSkeleton extends StatelessWidget {
  final int itemCount;

  const ReservationListSkeleton({
    super.key,
    this.itemCount = 4,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ReservationCardSkeleton(),
    );
  }
}

