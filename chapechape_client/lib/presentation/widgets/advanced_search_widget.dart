import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/models/city.dart';
import '../../core/models/country.dart';
import 'search_bar_widget.dart';
import 'residence_type_selector_widget.dart';
import 'price_range_slider_widget.dart';
import 'multilevel_location_selector.dart';
import 'animated_search_field.dart';
import 'animated_filter_option.dart';

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
  LocationSelection? _selectedLocation;
  DateTimeRange? _selectedDateRange;
  String? _selectedCategoryId;
  ResidenceType? _selectedResidenceType;
  RangeValues _priceRange = const RangeValues(5000, 500000);
  
  // Utilisation des catégories définies dans le ResidenceTypeSelectorWidget
  final List<ResidenceCategory> _residenceCategories = availableResidenceCategories;
  
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
      'location': _selectedLocation?.toMap(),
      'dateRange': _selectedDateRange,
      'residenceType': _selectedResidenceType?.modelType != null ? _selectedResidenceType?.modelType.toString() : _selectedResidenceType?.id,
      'categoryId': _selectedCategoryId,
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
  
  // Sélection d'une plage de dates
  Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = _selectedDateRange ?? DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(days: 7)),
    );
    
    final newDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
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
    
    if (newDateRange != null) {
      setState(() {
        _selectedDateRange = newDateRange;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            const Icon(Icons.search, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Recherche avancée',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold,
                  fontSize: context.responsiveFontSize(18),
                ),
              ),
            ),
          ],
        ),
        initiallyExpanded: true,
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: [
          // Champ de recherche animé
          AnimatedSearchField(
            controller: _searchController,
            hint: 'Rechercher une résidence, un quartier, une ville...',
            prefixIcon: Icons.search,
            onSubmitted: (value) {
              // Déclencher la recherche lors de la soumission
              _executeSearch();
            },
            getSuggestions: (query) async {
              // Ici, normalement, vous feriez appel à un service pour obtenir des suggestions
              // Pour l'exemple, utilisons des suggestions statiques
              await Future.delayed(const Duration(milliseconds: 300)); // Simuler un délai réseau
              
              if (query.isEmpty) return [];
              
              final suggestions = [
                'Abidjan - Cocody',
                'Abidjan - Marcory',
                'Abidjan - Plateau',
                'Abidjan - Zone 4',
                'Abidjan - Angré',
                'Yamoussoukro - Centre',
                'Grand Bassam',
                'Assinie',
                'San Pedro',
              ];
              
              return suggestions.where((suggestion) => 
                suggestion.toLowerCase().contains(query.toLowerCase())
              ).toList();
            },
          ),
          
          const SizedBox(height: 24),
          
          // Section des filtres rapides
          _buildQuickFiltersSection(),
          
          const SizedBox(height: 24),
          
          // Localisation améliorée
          _buildLocationSection(),
          
          const SizedBox(height: 24),
          
          // Date et durée
          _buildDateRangeSection(),
          
          const SizedBox(height: 24),
          
          // Type de résidence et prix
          _buildTypeAndPriceSection(),
          
          const SizedBox(height: 16),
          
          // Bouton de recherche
          _buildSearchButton(),
        ],
      )
      .animate()
      .fade(duration: 400.ms, curve: Curves.easeOutQuad)
      .slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutQuad),
    );
  }
  
  // Section des filtres rapides avec options animées
  Widget _buildQuickFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filtres rapides',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
            fontSize: context.responsiveFontSize(16),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Liste horizontale de filtres basée sur les catégories
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Option "Toutes les résidences"
              AnimatedFilterOption(
                label: 'Toutes',
                icon: Icons.home,
                isActive: _selectedCategoryId == null && _selectedResidenceType == null,
                onTap: () {
                  setState(() {
                    _selectedCategoryId = null;
                    _selectedResidenceType = null;
                  });
                },
              ),
              
              const SizedBox(width: 8),
              
              // Options basées sur nos catégories
              ..._residenceCategories.map((category) {
                // Pour chaque catégorie, créer une option de filtre rapide
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AnimatedFilterOption(
                    label: category.name,
                    icon: category.icon,
                    isActive: _selectedCategoryId == category.id,
                    onTap: () {
                      setState(() {
                        _selectedCategoryId = category.id;
                        _selectedResidenceType = null; // Réinitialiser le type
                      });
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }
  
  // Section de localisation
  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Localisation',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
            fontSize: context.responsiveFontSize(16),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Widget de sélection de localisation multi-niveau
        MultilevelLocationSelector(
          onLocationSelected: (location) {
            setState(() {
              _selectedLocation = location;
              // Pour compatibilité avec le code existant
              if (location.country != null) {
                _selectedCountry = location.country!;
              }
              if (location.city != null) {
                _selectedCity = location.city;
              }
            });
          },
          initialSelection: _selectedLocation,
          hint: 'Sélectionner un lieu',
        ),
      ],
    )
    .animate()
    .fadeIn(delay: 100.ms, duration: 300.ms)
    .slideX(begin: -0.1, end: 0, delay: 100.ms, duration: 300.ms);
  }
  
  // Section de sélection de dates
  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dates de séjour',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
            fontSize: context.responsiveFontSize(16),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Widget de sélection de dates
        GestureDetector(
          onTap: () => _selectDateRange(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Text(
                    _selectedDateRange != null
                        ? '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}'
                        : 'Sélectionner les dates',
                    style: TextStyle(
                      color: _selectedDateRange != null
                          ? Colors.grey[800]
                          : Colors.grey[500],
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
    )
    .animate()
    .fadeIn(delay: 200.ms, duration: 300.ms)
    .slideX(begin: 0.1, end: 0, delay: 200.ms, duration: 300.ms);
  }
  
  // Section type de résidence et prix
  Widget _buildTypeAndPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intégration de notre widget de sélection à deux niveaux
        Text(
          'Type de résidence',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
            fontSize: context.responsiveFontSize(16),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Utiliser directement notre widget ResidenceTypeSelectorWidget
        ResidenceTypeSelectorWidget(
          categories: _residenceCategories,
          initialCategoryId: _selectedCategoryId,
          initialType: _selectedResidenceType,
          onTypeSelected: (type) {
            setState(() {
              _selectedResidenceType = type;
              // Trouver la catégorie correspondante
              for (var category in _residenceCategories) {
                if (category.types.contains(type)) {
                  _selectedCategoryId = category.id;
                  break;
                }
              }
            });
          },
        ),
        
        const SizedBox(height: 24),
        
        // Curseur de prix
        Text(
          'Fourchette de prix (FCFA)',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
            fontSize: context.responsiveFontSize(16),
          ),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          '${_formatPrice(_priceRange.start)} - ${_formatPrice(_priceRange.end)}',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 8),
        
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: AppTheme.primaryColor,
            overlayColor: AppTheme.primaryColor.withOpacity(0.2),
            valueIndicatorColor: AppTheme.primaryColor,
            showValueIndicator: ShowValueIndicator.always,
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: RangeSlider(
            min: _minPrice,
            max: _maxPrice,
            divisions: 100,
            values: _priceRange,
            labels: RangeLabels(
              _formatPrice(_priceRange.start),
              _formatPrice(_priceRange.end),
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _priceRange = values;
              });
            },
          ),
        ),
      ],
    )
    .animate()
    .fadeIn(delay: 300.ms, duration: 300.ms)
    .slideY(begin: 0.1, end: 0, delay: 300.ms, duration: 300.ms);
  }
  
  // Bouton de recherche
  Widget _buildSearchButton() {
    return Container(
      width: double.infinity,
      height: 50,
      margin: const EdgeInsets.only(top: 8),
      child: ElevatedButton(
        onPressed: _executeSearch,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search),
            SizedBox(width: 8),
            Text(
              'Rechercher',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    )
    .animate()
    .fadeIn(delay: 400.ms, duration: 300.ms)
    .scale(delay: 400.ms, duration: 300.ms);
  }
}
