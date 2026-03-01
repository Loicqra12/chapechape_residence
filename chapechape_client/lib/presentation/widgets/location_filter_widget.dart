import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/country.dart';
import '../../core/models/region.dart';
import '../../core/models/city.dart';
import '../../core/models/neighborhood.dart';
import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/spacing.dart';
import 'multi_level_location_selector.dart';

/// Widget de filtre de localisation pour l'écran de recherche
/// Permet de sélectionner un lieu à différents niveaux (pays, région, ville, quartier)
class LocationFilterWidget extends StatefulWidget {
  /// Callback appelé lorsque les filtres de localisation sont appliqués
  final Function(Map<String, dynamic>) onApplyFilters;
  
  /// Filtres de localisation actuels
  final Map<String, dynamic>? currentFilters;
  
  const LocationFilterWidget({
    Key? key,
    required this.onApplyFilters,
    this.currentFilters,
  }) : super(key: key);

  @override
  State<LocationFilterWidget> createState() => _LocationFilterWidgetState();
}

class _LocationFilterWidgetState extends State<LocationFilterWidget> {
  // Sélections par niveau
  Country? _selectedCountry;
  Region? _selectedRegion;
  City? _selectedCity;
  Neighborhood? _selectedNeighborhood;
  
  // Options d'affichage
  bool _showSelector = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialiser avec les filtres actuels si disponibles
    if (widget.currentFilters != null) {
      _initializeFromFilters();
    }
  }
  
  void _initializeFromFilters() {
    final filters = widget.currentFilters!;
    
    // Charger le pays sélectionné
    if (filters.containsKey('countryCode')) {
      final countryCode = filters['countryCode'] as String?;
      if (countryCode != null) {
        _selectedCountry = context.read<ResidenceBloc>().getCountryByCode(countryCode);
      }
    }
    
    // Charger la région sélectionnée (uniquement si le pays est résolu)
    if (filters.containsKey('regionId')) {
      final regionId = filters['regionId'] as String?;
      final country = _selectedCountry;
      if (regionId != null && country != null && country.code.isNotEmpty) {
        _selectedRegion = context.read<ResidenceBloc>().getRegionById(regionId, country.code);
      }
    }
    
    // Charger la ville sélectionnée
    if (filters.containsKey('cityId')) {
      final cityId = filters['cityId'] as String?;
      if (cityId != null) {
        _selectedCity = context.read<ResidenceBloc>().getCityById(cityId);
      }
    }
    
    // Charger le quartier sélectionné
    if (filters.containsKey('neighborhoodId')) {
      final neighborhoodId = filters['neighborhoodId'] as String?;
      if (neighborhoodId != null) {
        _selectedNeighborhood = context.read<ResidenceBloc>().getNeighborhoodById(neighborhoodId);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Titre et indication de la localisation sélectionnée
            Row(
              children: [
                const Icon(Icons.location_on, color: AppTheme.primaryColor),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Localisation',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (_selectedCountry != null || _selectedRegion != null || 
                    _selectedCity != null || _selectedNeighborhood != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: _clearSelection,
                    tooltip: 'Effacer la sélection',
                  ),
              ],
            ),
            
            SizedBox(height: AppSpacing.sm),
            
            // Afficher la sélection actuelle ou un message par défaut
            _buildSelectionSummary(),
            
            SizedBox(height: AppSpacing.smd),
            
            // Bouton pour afficher/masquer le sélecteur de localisation
            Center(
              child: TextButton.icon(
                icon: Icon(_showSelector ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                label: Text(_showSelector ? 'Masquer les options' : 'Choisir une localisation'),
                onPressed: () {
                  setState(() {
                    _showSelector = !_showSelector;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
            ),
            
            // Sélecteur de localisation multiniveau
            if (_showSelector)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: _showSelector ? null : 0,
                child: MultiLevelLocationSelector(
                  onLocationSelected: _onLocationSelected,
                  maxLevel: LocationLevel.neighborhood,
                  initialCountry: _selectedCountry,
                  initialRegion: _selectedRegion,
                  initialCity: _selectedCity,
                  initialNeighborhood: _selectedNeighborhood,
                  showBorder: false,
                  showBreadcrumb: true,
                ),
              ).animate().fadeIn(duration: 300.ms),
            
            SizedBox(height: AppSpacing.md),
            
            // Bouton pour appliquer les filtres
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Appliquer les filtres'),
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.textLight,
                  padding: AppSpacing.buttonPadding,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Afficher un résumé de la sélection de localisation
  Widget _buildSelectionSummary() {
    if (_selectedNeighborhood != null) {
      return _buildSelectionChip(
        '${_selectedNeighborhood!.name}, ${_selectedCity!.name}, ${_selectedCountry!.name}',
        LocationLevel.neighborhood,
      );
    } else if (_selectedCity != null) {
      return _buildSelectionChip(
        '${_selectedCity!.name}, ${_selectedCountry!.name}',
        LocationLevel.city,
      );
    } else if (_selectedRegion != null) {
      return _buildSelectionChip(
        '${_selectedRegion!.name}, ${_selectedCountry!.name}',
        LocationLevel.region,
      );
    } else if (_selectedCountry != null) {
      return _buildSelectionChip(
        _selectedCountry!.name,
        LocationLevel.country,
      );
    } else {
      return Text(
        'Aucune localisation sélectionnée',
        style: AppTextStyles.body.copyWith(
          color: AppTheme.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      );
    }
  }
  
  // Construire une puce pour afficher la sélection
  Widget _buildSelectionChip(String label, LocationLevel level) {
    return Chip(
      label: Text(label),
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      labelStyle: AppTextStyles.tag.copyWith(
        color: AppTheme.primaryColor,
      ),
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
    );
  }
  
  // Gérer la sélection d'une localisation
  void _onLocationSelected(dynamic location, LocationLevel level) {
    setState(() {
      switch (level) {
        case LocationLevel.country:
          _selectedCountry = location as Country;
          _selectedRegion = null;
          _selectedCity = null;
          _selectedNeighborhood = null;
          break;
        case LocationLevel.region:
          _selectedRegion = location as Region;
          _selectedCity = null;
          _selectedNeighborhood = null;
          break;
        case LocationLevel.city:
          _selectedCity = location as City;
          _selectedNeighborhood = null;
          break;
        case LocationLevel.neighborhood:
          _selectedNeighborhood = location as Neighborhood;
          break;
      }
    });
    
    // Masquer le sélecteur une fois la sélection terminée au niveau le plus bas
    if (level == LocationLevel.neighborhood) {
      setState(() {
        _showSelector = false;
      });
    }
  }
  
  // Effacer la sélection actuelle
  void _clearSelection() {
    setState(() {
      _selectedCountry = null;
      _selectedRegion = null;
      _selectedCity = null;
      _selectedNeighborhood = null;
    });
  }
  
  // Appliquer les filtres de localisation
  void _applyFilters() {
    final Map<String, dynamic> filters = {};
    
    if (_selectedCountry != null) {
      filters['countryCode'] = _selectedCountry!.code;
    }
    
    if (_selectedRegion != null) {
      filters['regionId'] = _selectedRegion!.id;
    }
    
    if (_selectedCity != null) {
      filters['cityId'] = _selectedCity!.id;
    }
    
    if (_selectedNeighborhood != null) {
      filters['neighborhoodId'] = _selectedNeighborhood!.id;
    }
    
    widget.onApplyFilters(filters);
    
    // Masquer le sélecteur après avoir appliqué les filtres
    setState(() {
      _showSelector = false;
    });
  }
}
