import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import 'search_bar_widget.dart';
import 'date_range_picker_widget.dart';
import 'residence_type_selector_widget.dart';
import 'price_range_slider_widget.dart';

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
  final TextEditingController _searchController = TextEditingController();
  DateTimeRange? _selectedDateRange;
  ResidenceType? _selectedResidenceType; // Cette classe est définie dans residence_type_selector_widget.dart
  RangeValues _priceRange = const RangeValues(50000, 500000);
  bool _showAdvancedOptions = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    if (widget.onSearch != null) {
      widget.onSearch!({
        'location': _searchController.text,
        'dateRange': _selectedDateRange,
        'residenceType': _selectedResidenceType,
        'priceRange': _priceRange,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 100,
        maxHeight: 400,
      ),
      margin: context.responsiveMargin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Trouvez votre résidence idéale',
                style: TextStyle(
                  fontSize: context.responsiveFontSize(20),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              _buildSearchLayout(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchLayout(BuildContext context) {
    // Utiliser une mise en page différente selon la taille de l'écran
    if (context.screenWidth < 600) {
      return _buildMobileLayout(context);
    } else {
      return _buildTabletDesktopLayout(context);
    }
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Champ de recherche
        _buildSearchField(context),
        const SizedBox(height: 16),
        
        // Sélecteur de dates
        _buildDateRangePicker(context),
        const SizedBox(height: 16),
        
        // Sélecteur de type de résidence
        Text(
          'Type de résidence',
          style: TextStyle(
            fontSize: context.responsiveFontSize(16),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 100,
          ),
          child: ResidenceTypeSelectorWidget(
            types: availableResidenceTypes,
            onTypeSelected: (type) {
              setState(() {
                _selectedResidenceType = type;
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        
        // Slider de prix
        Text(
          'Plage de prix (FCFA)',
          style: TextStyle(
            fontSize: context.responsiveFontSize(16),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildPriceRangeSlider(context),
        const SizedBox(height: 16),
        
        // Bouton de recherche
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Rechercher',
              style: TextStyle(
                fontSize: context.responsiveFontSize(16),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletDesktopLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Première ligne: Recherche et dates
        Row(
          children: [
            // Champ de recherche
            Expanded(
              flex: 3,
              child: _buildSearchField(context),
            ),
            const SizedBox(width: 16),
            // Sélecteur de dates
            Expanded(
              flex: 2,
              child: _buildDateRangePicker(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Deuxième ligne: Type de résidence, prix et bouton
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Type de résidence
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Type de résidence',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 100,
                    ),
                    child: ResidenceTypeSelectorWidget(
                      types: availableResidenceTypes,
                      onTypeSelected: (type) {
                        setState(() {
                          _selectedResidenceType = type;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Plage de prix
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plage de prix (FCFA)',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPriceRangeSlider(context),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Bouton de recherche
            SizedBox(
              width: context.responsiveWidth(150),
              child: ElevatedButton(
                onPressed: _handleSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Rechercher',
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return SearchBarWidget(
      controller: _searchController,
      onSubmitted: (value) => _handleSearch(),
      suggestions: const [
        'Abidjan, Cocody',
        'Abidjan, Plateau',
        'Yamoussoukro, Centre',
        'San Pedro, Port',
        'Bouaké, Centre',
      ],
    );
  }

  Widget _buildDateRangePicker(BuildContext context) {
    return DateRangePickerWidget(
      onDateRangeSelected: (dateRange) {
        setState(() {
          _selectedDateRange = dateRange;
        });
      },
    );
  }

  Widget _buildPriceRangeSlider(BuildContext context) {
    return PriceRangeSliderWidget(
      min: 50000,
      max: 1000000,
      initialRange: _priceRange,
      onChanged: (range) {
        setState(() {
          _priceRange = range;
        });
      },
    );
  }
}
