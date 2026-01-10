import 'package:flutter/material.dart';
import 'residence_card_skeleton.dart';

/// Skeleton loader pour une liste de résidences
class ResidenceListSkeleton extends StatelessWidget {
  final int itemCount;

  const ResidenceListSkeleton({
    super.key,
    this.itemCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ResidenceCardSkeleton(),
    );
  }
}

