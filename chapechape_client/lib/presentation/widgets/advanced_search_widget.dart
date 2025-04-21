import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/models/city.dart';
import '../../core/models/country.dart';
import 'search_bar_widget.dart';
import 'date_range_picker_widget.dart';
import 'residence_type_selector_widget.dart';
import 'price_range_slider_widget.dart';
import 'location_selector_widget.dart';
import 'country_selector_widget.dart';

class AdvancedSearchWidget extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSearch;
  
  const AdvancedSearchWidget({
    Key? key,
    this.onSearch,
  }) : super(key: key);

  @override
  State<AdvancedSearchWidget> createState() => _AdvancedSearchWidgetState();
}

class _AdvancedSearchWidgetState extends State<AdvancedSearchWidget> {
  // État de la recherche
  Country _selectedCountry = Country(
    code: 'ci', 
    name: 'Côte d\'Ivoire', 
    phoneCode: '+225'
  );
  City? _selectedCity;
  DateTimeRange? _selectedDateRange;
  String _selectedResidenceType = 'Tous';
  RangeValues _priceRange = const RangeValues(5000, 500000);
  
  // Options pour les types de résidences
  final List<String> _residenceTypes = [
    'Tous', 
    'Appartement', 
    'Maison', 
    'Villa', 
    'Studio', 
    'Hôtel', 
    'Hôtel de passe/Court séjour'
  ];
  
  // Contrôleur pour le champ de recherche
  final TextEditingController _searchController = TextEditingController();
  
  // Prix minimum et maximum (en FCFA)
  static const double _minPrice = 5000;  // 5,000 FCFA
  static const double _maxPrice = 50000000;  // 50,000,000 FCFA
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _executeSearch() {
    final searchParams = {
      'country': _selectedCountry,
      'city': _selectedCity,
      'dateRange': _selectedDateRange,
      'residenceType': _selectedResidenceType,
      'priceRange': _priceRange,
      'searchTerm': _searchController.text,
    };
    
    if (widget.onSearch != null) {
      widget.onSearch!(searchParams);
    }
  }
  
  // Formatage du prix pour l'affichage
  String _formatPrice(double price) {
    return NumberFormat.currency(
      symbol: '', 
      decimalDigits: 0,
      locale: 'fr_FR',
    ).format(price) + ' FCFA';
  }
  
  // Construction de l'interface pour mobile
  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barre de recherche
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Rechercher',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Sélecteur de pays en version compacte
        Row(
          children: [
            CountrySelectorWidget(
              onCountrySelected: (country) {
                setState(() {
                  _selectedCountry = country;
                  _selectedCity = null; // Réinitialiser la ville quand le pays change
                });
              },
              showLabel: false,
              showBorder: false,
              showCompact: true,
              initialCountry: _selectedCountry,
            ),
            
            const SizedBox(width: 8),
            
            // Sélecteur de localisation
            Expanded(
              child: SizedBox(
                height: 48,
                child: LocationSelectorWidget(
                  onCitySelected: (city) {
                    setState(() {
                      _selectedCity = city;
                    });
                  },
                  initialCountry: _selectedCountry,
                  initialCity: _selectedCity,
                  hintText: 'Où allez-vous?',
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Sélecteur de dates
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: DateRangePickerWidget(
                  initialDateRange: _selectedDateRange,
                  onDateRangeSelected: (dateRange) {
                    setState(() {
                      _selectedDateRange = dateRange;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDateRange != null
                        ? '${DateFormat('dd MMM', 'fr_FR').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM', 'fr_FR').format(_selectedDateRange!.end)}'
                        : 'Sélectionner des dates',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(14),
                      color: _selectedDateRange != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Type de résidence
        DropdownButtonFormField<String>(
          value: _selectedResidenceType,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.home),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          items: _residenceTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                _selectedResidenceType = newValue;
              });
            }
          },
        ),
        
        const SizedBox(height: 16),
        
        // Fourchette de prix
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
              child: Text(
                'Prix : ${_formatPrice(_priceRange.start)} - ${_formatPrice(_priceRange.end)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            RangeSlider(
              values: _priceRange,
              min: _minPrice,
              max: _maxPrice,
              divisions: 100,
              activeColor: AppTheme.primaryColor,
              inactiveColor: Colors.grey[300],
              labels: RangeLabels(
                _formatPrice(_priceRange.start),
                _formatPrice(_priceRange.end),
              ),
              onChanged: (values) {
                setState(() {
                  _priceRange = values;
                });
              },
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Bouton de recherche
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _executeSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Rechercher',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Construction de l'interface pour tablette/bureau
  Widget _buildTabletLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Première ligne: Pays, Localisation, Dates
        Row(
          children: [
            // Pays
            Expanded(
              flex: 1,
              child: CountrySelectorWidget(
                onCountrySelected: (country) {
                  setState(() {
                    _selectedCountry = country;
                    _selectedCity = null;
                  });
                },
                initialCountry: _selectedCountry,
                showLabel: true,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Localisation
            Expanded(
              flex: 2,
              child: LocationSelectorWidget(
                onCitySelected: (city) {
                  setState(() {
                    _selectedCity = city;
                  });
                },
                initialCountry: _selectedCountry,
                initialCity: _selectedCity,
                label: 'Destination',
                hintText: 'Rechercher une ville ou une commune',
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Dates
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'Dates',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          contentPadding: EdgeInsets.zero,
                          content: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: DateRangePickerWidget(
                              initialDateRange: _selectedDateRange,
                              onDateRangeSelected: (dateRange) {
                                setState(() {
                                  _selectedDateRange = dateRange;
                                });
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDateRange != null
                                  ? '${DateFormat('dd MMM', 'fr_FR').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM', 'fr_FR').format(_selectedDateRange!.end)}'
                                  : 'Sélectionner des dates',
                              style: TextStyle(
                                fontSize: context.responsiveFontSize(14),
                                color: _selectedDateRange != null ? Colors.black : Colors.grey[600],
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Deuxième ligne: Type, Prix, Bouton Recherche
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Type de résidence
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                    child: Text(
                      'Type de résidence',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedResidenceType,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.home),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    items: _residenceTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedResidenceType = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Fourchette de prix
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
                    child: Text(
                      'Prix (FCFA)',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatPrice(_priceRange.start),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _formatPrice(_priceRange.end),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        RangeSlider(
                          values: _priceRange,
                          min: _minPrice,
                          max: _maxPrice,
                          divisions: 100,
                          activeColor: AppTheme.primaryColor,
                          inactiveColor: Colors.grey[300],
                          onChanged: (values) {
                            setState(() {
                              _priceRange = values;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Bouton de recherche
            SizedBox(
              height: 56,
              width: 120,
              child: ElevatedButton(
                onPressed: _executeSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.search),
                    SizedBox(width: 8),
                    Text('Rechercher', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Utiliser un LayoutBuilder pour s'adapter à la taille de l'écran
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: constraints.maxWidth > 800
                ? _buildTabletLayout()
                : _buildMobileLayout(),
          ),
        );
      },
    );
  }
}
