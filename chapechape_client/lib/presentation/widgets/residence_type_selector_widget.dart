import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ResidenceType {
  final String id;
  final String name;
  final IconData icon;

  const ResidenceType({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class ResidenceTypeSelectorWidget extends StatefulWidget {
  final List<ResidenceType> types;
  final Function(ResidenceType)? onTypeSelected;
  final ResidenceType? initialType;

  const ResidenceTypeSelectorWidget({
    Key? key,
    required this.types,
    this.onTypeSelected,
    this.initialType,
  }) : super(key: key);

  @override
  State<ResidenceTypeSelectorWidget> createState() =>
      _ResidenceTypeSelectorWidgetState();
}

class _ResidenceTypeSelectorWidgetState extends State<ResidenceTypeSelectorWidget> {
  ResidenceType? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
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
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.types.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          final type = widget.types[index];
          final isSelected = type.id == _selectedType?.id;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedType = type;
                });
                if (widget.onTypeSelected != null) {
                  widget.onTypeSelected!(type);
                }
              },
              child: Container(
                width: 100,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type.icon,
                      size: 32,
                      color: isSelected ? Colors.white : AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      type.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Liste des types de résidences disponibles
final List<ResidenceType> availableResidenceTypes = [
  const ResidenceType(
    id: 'apartment',
    name: 'Appartement',
    icon: Icons.apartment,
  ),
  const ResidenceType(
    id: 'studio',
    name: 'Studio',
    icon: Icons.single_bed,
  ),
  const ResidenceType(
    id: 'villa',
    name: 'Villa',
    icon: Icons.home,
  ),
  const ResidenceType(
    id: 'room',
    name: 'Chambre',
    icon: Icons.hotel,
  ),
  const ResidenceType(
    id: 'bungalow',
    name: 'Bungalow',
    icon: Icons.holiday_village,
  ),
  const ResidenceType(
    id: 'penthouse',
    name: 'Penthouse',
    icon: Icons.location_city,
  ),
  const ResidenceType(
    id: 'hostel',
    name: 'Auberge',
    icon: Icons.house_siding,
  ),
  const ResidenceType(
    id: 'hotel',
    name: 'Hôtel',
    icon: Icons.business,
  ),
];
