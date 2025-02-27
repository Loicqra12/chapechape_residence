import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class NewListingsBadge extends StatelessWidget {
  final DateTime listingDate;
  final bool showBackground;
  final double? fontSize;

  const NewListingsBadge({
    Key? key,
    required this.listingDate,
    this.showBackground = true,
    this.fontSize,
  }) : super(key: key);

  bool get isNew {
    final now = DateTime.now();
    final difference = now.difference(listingDate);
    return difference.inDays <= 7; // Considéré comme nouveau pendant 7 jours
  }

  @override
  Widget build(BuildContext context) {
    if (!isNew) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: showBackground
          ? BoxDecoration(
              color: Colors.green[500],
              borderRadius: BorderRadius.circular(4),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fiber_new,
            size: (fontSize ?? 12) + 2,
            color: showBackground ? Colors.white : Colors.green[500],
          ),
          const SizedBox(width: 4),
          Text(
            'Nouveau',
            style: TextStyle(
              color: showBackground ? Colors.white : Colors.green[500],
              fontSize: fontSize ?? 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
