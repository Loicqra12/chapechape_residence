import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loader pour un élément de notification
class NotificationItemSkeleton extends StatelessWidget {
  const NotificationItemSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseColor = scheme.surfaceContainerHighest;
    final highlightColor = scheme.surface;
    final containerColor = scheme.surface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: containerColor,
          radius: 24,
        ),
        title: Container(
          height: 16,
          width: double.infinity,
          decoration: BoxDecoration(
            color: containerColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 14,
                width: 100,
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}








