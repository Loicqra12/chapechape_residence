import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/location_suggestion_model.dart';
import '../../core/services/location_service.dart';

class AdvancedSearchFilters extends StatefulWidget {
  final Function(Map<String, dynamic>) onSearch;

  const AdvancedSearchFilters({
    Key? key,
    required this.onSearch,
  }) : super(key: key);

  @override
  State<AdvancedSearchFilters> createState() => _AdvancedSearchFiltersState();
}

class _AdvancedSearchFiltersState extends State<AdvancedSearchFilters> {
  final _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  String? _selectedType;
  RangeValues _priceRange = const RangeValues(0, 1000000);
  List<LocationSuggestionModel> _suggestions = [];

  // Types de résidences disponibles
  final List<Map<String, String>> _residenceTypes = [
    {'id': 'apartment', 'name': 'Appartement'},
    {'id': 'studio', 'name': 'Studio'},
    {'id': 'villa', 'name': 'Villa'},
    {'id': 'room', 'name': 'Chambre'},
    {'id': 'bungalow', 'name': 'Bungalow'},
    {'id': 'penthouse', 'name': 'Penthouse'},
    {'id': 'hostel', 'name': 'Auberge'},
    {'id': 'hotel', 'name': 'Hôtel'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _handleSearch() {
    widget.onSearch({
      'location': _searchController.text,
      'startDate': _selectedDateRange?.start,
      'endDate': _selectedDateRange?.end,
      'type': _selectedType,
      'minPrice': _priceRange.start,
      'maxPrice': _priceRange.end,
    });
  }

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Champ de recherche principal
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Où souhaitez-vous loger ?',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sélection des dates
          InkWell(
            onTap: _selectDateRange,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDateRange != null
                        ? '${_selectedDateRange!.start.toString().split(' ')[0]} - ${_selectedDateRange!.end.toString().split(' ')[0]}'
                        : 'Sélectionner les dates',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Type de résidence
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: InputDecoration(
              labelText: 'Type de résidence',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: _residenceTypes.map((type) {
              return DropdownMenuItem(
                value: type['id'],
                child: Text(type['name']!),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedType = value),
          ),
          const SizedBox(height: 16),

          // Plage de prix
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Budget: ${_priceRange.start.round()} - ${_priceRange.end.round()} FCFA',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 1000000,
                divisions: 100,
                labels: RangeLabels(
                  _priceRange.start.round().toString(),
                  _priceRange.end.round().toString(),
                ),
                onChanged: (values) => setState(() => _priceRange = values),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bouton de recherche
          ElevatedButton(
            onPressed: _handleSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Rechercher',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
