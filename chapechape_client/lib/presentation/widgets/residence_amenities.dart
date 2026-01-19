import 'package:flutter/material.dart';
import '../../core/models/amenity.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/spacing.dart';
import 'svg_icon.dart';

class ResidenceAmenities extends StatelessWidget {
  final List<Amenity> amenities;

  const ResidenceAmenities({
    Key? key,
    required this.amenities,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: amenities.map((amenity) {
        return Tooltip(
          message: amenity.name,
          child: Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgIcon(
                  assetName: amenity.icon,
                  width: 20,
                  height: 20,
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  amenity.name,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
