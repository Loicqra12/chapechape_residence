import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class RatingLabelsWidget extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final List<String> labels;

  const RatingLabelsWidget({
    Key? key,
    required this.rating,
    required this.reviewCount,
    required this.labels,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                color: Colors.amber[600],
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                rating.toStringAsFixed(1),
                style: AppTheme.headingMedium,
              ),
              const SizedBox(width: 8),
              Text(
                '($reviewCount avis)',
                style: AppTheme.bodyMedium.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: labels.map((label) => _buildLabel(label)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue[100]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.blue[600],
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: Colors.blue[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Exemple d'utilisation :
class RatingLabelsExample extends StatelessWidget {
  const RatingLabelsExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rating = 4.5;
    final reviewCount = 123;
    final labels = [
      'Top Rated',
      'Super Host',
      'Vérifié',
      'Recommandé',
      'Nouveau',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Labels et Badges',
            style: AppTheme.headingMedium,
          ),
          const SizedBox(height: 16),
          RatingLabelsWidget(
            rating: rating,
            reviewCount: reviewCount,
            labels: labels,
          ),
        ],
      ),
    );
  }
}
