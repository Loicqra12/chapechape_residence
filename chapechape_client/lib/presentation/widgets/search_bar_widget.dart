import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_theme.dart';
import 'svg_icon.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({Key? key}) : super(key: key);

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _suggestions = [
    'Cocody, Abidjan',
    'Plateau, Abidjan',
    'Marcory, Abidjan',
    'Riviera, Abidjan',
    'Angré, Abidjan',
  ];
  final List<String> _residenceTypes = [
    'Tous les types',
    'Appartement',
    'Studio',
    'Villa',
    'Chambre',
    'Bungalow',
    'Penthouse',
  ];

  String? _selectedResidenceType;
  DateTimeRange? _selectedDateRange;
  RangeValues _priceRange = const RangeValues(50000, 500000);
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _selectedResidenceType = _residenceTypes[0];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppTheme.mediumShadow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.lightGold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.cream,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppTheme.lightGold),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: AppTheme.primaryGold),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Où souhaitez-vous loger ?',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _showSuggestions = value.isNotEmpty;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_showSuggestions)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.softShadow,
                border: Border.all(color: AppTheme.lightGold),
              ),
              child: Column(
                children: _suggestions
                    .map((suggestion) => ListTile(
                          leading: Icon(Icons.location_on,
                              color: AppTheme.primaryGold),
                          title: Text(suggestion),
                          onTap: () {
                            setState(() {
                              _searchController.text = suggestion;
                              _showSuggestions = false;
                            });
                          },
                        ))
                    .toList(),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date d\'arrivée',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: AppTheme.primaryGold,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDateRange = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.lightGold),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDateRange != null
                                  ? DateFormat('dd/MM/yyyy')
                                      .format(_selectedDateRange!.start)
                                  : 'Sélectionner',
                              style: AppTheme.bodyMedium,
                            ),
                            Icon(Icons.calendar_today,
                                size: 20, color: AppTheme.primaryGold),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date de départ',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.lightGold),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDateRange != null
                                ? DateFormat('dd/MM/yyyy')
                                    .format(_selectedDateRange!.end)
                                : 'Sélectionner',
                            style: AppTheme.bodyMedium,
                          ),
                          Icon(Icons.calendar_today,
                              size: 20, color: AppTheme.primaryGold),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _selectedResidenceType,
            decoration: AppTheme.inputDecoration.copyWith(
              labelText: 'Type de résidence',
              labelStyle: const TextStyle(color: AppTheme.charcoal),
            ),
            items: _residenceTypes
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedResidenceType = value;
              });
            },
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Budget: ${NumberFormat.currency(
                  symbol: 'FCFA',
                  decimalDigits: 0,
                ).format(_priceRange.start)} - ${NumberFormat.currency(
                  symbol: 'FCFA',
                  decimalDigits: 0,
                ).format(_priceRange.end)}',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              RangeSlider(
                values: _priceRange,
                min: 50000,
                max: 1000000,
                divisions: 19,
                activeColor: AppTheme.primaryGold,
                inactiveColor: AppTheme.lightGold,
                labels: RangeLabels(
                  NumberFormat.compact().format(_priceRange.start),
                  NumberFormat.compact().format(_priceRange.end),
                ),
                onChanged: (values) {
                  setState(() {
                    _priceRange = values;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implémenter la recherche
              },
              style: AppTheme.primaryButton,
              child: const Text(
                'Rechercher',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}