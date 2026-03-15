import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loader pour l'écran de détails d'une résidence
class ResidenceDetailsSkeleton extends StatelessWidget {
  const ResidenceDetailsSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final baseColor = scheme.surfaceContainerHighest;
    final highlightColor = scheme.surface;
    final containerColor = scheme.surface;
    final bgColor = scheme.surfaceContainerLow;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar skeleton avec image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: Container(
              color: bgColor,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre skeleton
                  Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: Container(
                      height: 28,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: containerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Prix skeleton
                  Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: Container(
                      height: 24,
                      width: 150,
                      decoration: BoxDecoration(
                        color: containerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Description skeleton
                  ...List.generate(3, (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Shimmer.fromColors(
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      child: Container(
                        height: 16,
                        width: index == 2 ? 200 : double.infinity,
                        decoration: BoxDecoration(
                          color: containerColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  )),
                  const SizedBox(height: 24),
                  // Caractéristiques skeleton
                  Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: containerColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}








