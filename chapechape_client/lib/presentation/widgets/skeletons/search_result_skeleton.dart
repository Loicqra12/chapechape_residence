import 'package:flutter/material.dart';
import 'residence_card_skeleton.dart';

/// Skeleton loader pour les résultats de recherche
class SearchResultSkeleton extends StatelessWidget {
  final int itemCount;
  
  const SearchResultSkeleton({
    Key? key,
    this.itemCount = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const ResidenceCardSkeleton();
      },
    );
  }
}



