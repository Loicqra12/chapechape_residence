import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class QualityLabelsWidget extends StatelessWidget {
  final List<String> labels;
  final bool showTitle;

  const QualityLabelsWidget({
    Key? key,
    required this.labels,
    this.showTitle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Labels de qualité',
              style: AppTheme.headingSmall,
            ),
          ),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: labels.map((label) => _buildLabel(label)).toList(),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            size: 16,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
