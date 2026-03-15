import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/responsive_utils.dart';
import '../screens/search_destination_screen.dart';
import 'residence_type_selector_widget.dart';
import 'animated_search_field.dart';
import 'duration_selector.dart';

class AdvancedSearchWidget extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSearch;

  /// Active un layout plus proche d'Airbnb (utilisé par la barre d'accueil).
  /// Pour l'instant ce flag est surtout là pour la compatibilité, le contenu reste identique.
  final bool useAirbnbLayout;

  const AdvancedSearchWidget({
    Key? key,
    this.onSearch,
    this.useAirbnbLayout = false,
  }) : super(key: key);

  @override
  State<AdvancedSearchWidget> createState() => _AdvancedSearchWidgetState();
}

class _AdvancedSearchWidgetState extends State<AdvancedSearchWidget> {
  // Destination sélectionnée via SearchDestinationScreen
  DestinationResult? _selectedDestination;
  DurationOption? _selectedDuration;
  ResidenceType? _selectedResidenceType;
  RangeValues _priceRange = const RangeValues(5000, 500000);
  
  // Utilisation des catégories définies dans le ResidenceTypeSelectorWidget
  final List<ResidenceCategory> _residenceCategories = availableResidenceCategories;
  
  // Types filtrés selon la durée
  List<ResidenceType> _filteredTypes = [];
  
  // Contrôleur pour le champ de recherche
  final TextEditingController _searchController = TextEditingController();
  
  // Prix minimum et maximum (en FCFA)
  static const double _minPrice = 5000;  // 5,000 FCFA
  static const double _maxPrice = 50000000;  // 50,000,000 FCFA
  
  @override
  void initState() {
    super.initState();
    _filteredTypes = _getAllTypes(); // Initialement tous les types
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  /// Récupère tous les types de toutes les catégories
  List<ResidenceType> _getAllTypes() {
    return _residenceCategories.expand((cat) => cat.types).toList();
  }
  
  /// Filtre les types selon la durée sélectionnée et reconstruit les catégories
  void _filterTypesByDuration(DurationOption? duration) {
    if (duration == null) {
      setState(() {
        _filteredTypes = _getAllTypes();
        // Si le type sélectionné reste valide, on le garde
      });
      return;
    }

    final allowedPeriods = duration.periods;
    final filtered = _getAllTypes().where((type) {
      final typePeriod = _getExpectedPricePeriodForType(type.id);
      return allowedPeriods.contains(typePeriod);
    }).toList();

    setState(() {
      _filteredTypes = filtered;
      // Réinitialiser le type sélectionné s'il n'est plus compatible
      if (_selectedResidenceType != null &&
          !filtered.any((t) => t.id == _selectedResidenceType!.id)) {
        _selectedResidenceType = null;
      }
    });
  }

  /// Construit les catégories filtrées depuis _filteredTypes
  List<ResidenceCategory> _buildFilteredCategories() {
    if (_filteredTypes.isEmpty || _selectedDuration == null) {
      return _residenceCategories;
    }
    final filteredIds = _filteredTypes.map((t) => t.id).toSet();
    return _residenceCategories
        .map((cat) => ResidenceCategory(
              id: cat.id,
              name: cat.name,
              icon: cat.icon,
              types: cat.types.where((t) => filteredIds.contains(t.id)).toList(),
            ))
        .where((cat) => cat.types.isNotEmpty)
        .toList();
  }
  
  /// Reproduit la logique Partner App côté Client
  String _getExpectedPricePeriodForType(String type) {
    // HOUR
    if (['hotel_passage', 'motel', 'chambres_passage'].contains(type)) {
      return 'hour';
    }
    
    // DAY
    if ([
      'studio_meuble',
      'guest_house',
      'boutique_hotel',
      'hotel_luxe',
      'lodge',
      'bungalow',
      'case_traditionnelle',
      'campement_touristique',
      'maison_flottante',
      'maison_hotes',
    ].contains(type)) {
      return 'day';
    }
    
    // WEEK
    if ([
      'maison_hotes_economique',
      'residence_familiale',
      'residence_hoteliere',
    ].contains(type)) {
      return 'week';
    }
    
    // MONTH (par défaut)
    return 'month';
  }

  void _executeSearch() {
    final searchParams = <String, dynamic>{
      if (_searchController.text.isNotEmpty) 'query': _searchController.text,
      if (_selectedDestination != null) 'city': _selectedDestination!.city,
      'countryCode': 'ci',
      'minPrice': _priceRange.start,
      'maxPrice': _priceRange.end,
      if (_selectedResidenceType != null)
        'residenceType': _selectedResidenceType!.id,
      if (_selectedDuration != null)
        'period': _selectedDuration!.periods.first,
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
  
  // La sélection de dates est maintenant gérée par le widget DateRangePickerWidget

  // Champ de recherche animé (réutilisé dans les deux layouts)
  Widget _buildSearchField() {
    return AnimatedSearchField(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Localisation
            _buildLocationSection(),

            const SizedBox(height: 24),

            // Durée
            _buildDateRangeSection(),

            const SizedBox(height: 24),

            // Type de résidence et prix
            _buildTypeAndPriceSection(),

            const SizedBox(height: 16),

            // Bouton de recherche
            _buildSearchButton(),
          ],
        ),
      )
      .animate()
      .fade(duration: 400.ms, curve: Curves.easeOutQuad)
      .slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutQuad),
    );
  }
  
  // Section de localisation — ouvre SearchDestinationScreen
  Widget _buildLocationSection() {
    final hasDestination = _selectedDestination != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Où ?',
          style: AppTextStyles.title.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final result = await Navigator.of(context, rootNavigator: true)
                .push<DestinationResult>(
              MaterialPageRoute(
                builder: (_) => const SearchDestinationScreen(),
                fullscreenDialog: true,
              ),
            );
            if (result != null) {
              setState(() => _selectedDestination = result);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: hasDestination
                  ? AppTheme.primaryColor.withOpacity(0.06)
                  : Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasDestination
                    ? AppTheme.primaryColor
                    : Theme.of(context).colorScheme.outline,
                width: hasDestination ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasDestination
                      ? Icons.location_on
                      : Icons.location_on_outlined,
                  size: 20,
                  color: hasDestination
                      ? AppTheme.primaryColor
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasDestination
                        ? _selectedDestination!.displayName
                        : 'Choisir un quartier ou une ville',
                    style: TextStyle(
                      fontSize: 14,
                      color: hasDestination
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      fontWeight: hasDestination
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasDestination)
                  GestureDetector(
                    onTap: () =>
                        setState(() => _selectedDestination = null),
                    child: Icon(Icons.close, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                  )
                else
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ],
            ),
          ),
        ),
      ],
    )
    .animate()
    .fadeIn(delay: 100.ms, duration: 300.ms)
    .slideX(begin: -0.1, end: 0, delay: 100.ms, duration: 300.ms);
  }
  
  // Section de sélection de durée (remplace dates)
  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sélecteur de durée multi-période
        DurationSelector(
          initialDuration: _selectedDuration,
          onDurationChanged: (duration) {
            setState(() {
              _selectedDuration = duration;
            });
            // Filtrer automatiquement les types selon la durée
            _filterTypesByDuration(duration);
          },
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
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: context.responsiveFontSize(16),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Message contextuel si durée sélectionnée
        if (_selectedDuration != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Affichage des types compatibles avec "${_selectedDuration!.label}"',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Types filtrés selon la durée sélectionnée
        ResidenceTypeSelectorWidget(
          categories: _buildFilteredCategories(),
          initialType: _selectedResidenceType,
          onTypeSelected: (type) {
            setState(() => _selectedResidenceType = type);
          },
        ),
        
        const SizedBox(height: 24),
        
        // Curseur de prix
        Text(
          'Fourchette de prix (FCFA)',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
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
            inactiveTrackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            thumbColor: AppTheme.primaryColor,
            overlayColor: AppTheme.primaryColor.withOpacity(0.2),
            valueIndicatorColor: AppTheme.primaryColor,
            showValueIndicator: ShowValueIndicator.always,
            valueIndicatorTextStyle: TextStyle(
              color: AppTheme.textLight,
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
          foregroundColor: AppTheme.textLight,
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
