import 'package:flutter/material.dart';
import '../../core/models/amenity.dart';
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
      spacing: 8,
      runSpacing: 8,
      children: amenities.map((amenity) {
        return Tooltip(
          message: amenity.name,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgIcon(
                  assetName: amenity.icon,
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  amenity.name,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
