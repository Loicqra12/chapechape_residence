import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';

import '../../core/models/city.dart';
import '../../core/models/country.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import 'country_flag_widget.dart';

/// Un sélecteur de localisation multiniveau qui permet aux utilisateurs
/// de choisir un lieu à travers plusieurs niveaux:
/// pays → région → ville → quartier
class MultilevelLocationSelector extends StatefulWidget {
  /// Callback appelé lorsqu'une localisation est sélectionnée
  final Function(LocationSelection) onLocationSelected;
  
  /// Localisation initiale (si disponible)
  final LocationSelection? initialSelection;
  
  /// Texte d'aide
  final String? hint;
  
  /// Libellé du champ
  final String? label;
  
  /// Si true, affiche une version compacte du sélecteur
  final bool compact;
  
  /// Si true, marque le champ comme obligatoire
  final bool required;

  const MultilevelLocationSelector({
    Key? key, 
    required this.onLocationSelected,
    this.initialSelection,
    this.hint,
    this.label,
    this.compact = false,
    this.required = false,
  }) : super(key: key);

  @override
  State<MultilevelLocationSelector> createState() => _MultilevelLocationSelectorState();
}

class _MultilevelLocationSelectorState extends State<MultilevelLocationSelector> {
  final LocationService _locationService = LocationService();
  
  // État de la sélection
  Country? _selectedCountry;
  String? _selectedRegion;
  City? _selectedCity;
  String? _selectedNeighborhood;
  
  // État de l'interface
  int _currentLevel = 0;
  bool _isExpanded = false;
  
  // Données disponibles
  List<Country> _availableCountries = [];
  List<String> _availableRegions = [];
  List<City> _availableCities = [];
  List<String> _availableNeighborhoods = [];
  
  // Filtrage
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    
    // Initialiser avec les valeurs fournies si disponibles
    if (widget.initialSelection != null) {
      _selectedCountry = widget.initialSelection!.country;
      _selectedRegion = widget.initialSelection!.region;
      _selectedCity = widget.initialSelection!.city;
      _selectedNeighborhood = widget.initialSelection!.neighborhood;
      
      // Déterminer le niveau initial
      if (_selectedNeighborhood != null) {
        _currentLevel = 3;
      } else if (_selectedCity != null) {
        _currentLevel = 2;
      } else if (_selectedRegion != null) {
        _currentLevel = 1;
      } else if (_selectedCountry != null) {
        _currentLevel = 0;
      }
    }
    
    // Charger les pays
    _loadCountries();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
  
  // Chargement des données
  void _loadCountries() {
    _availableCountries = _locationService.getCountries();
    setState(() {});
    
    // Si un pays est déjà sélectionné, charger ses régions
    if (_selectedCountry != null) {
      _loadRegions();
    }
  }
  
  void _loadRegions() {
    if (_selectedCountry == null) return;
    
    _availableRegions = _locationService.getRegionsByCountry(_selectedCountry!.code);
    setState(() {});
    
    // Si une région est déjà sélectionnée, charger ses villes
    if (_selectedRegion != null) {
      _loadCities();
    }
  }
  
  void _loadCities() {
    if (_selectedCountry == null || _selectedRegion == null) return;
    
    _availableCities = _locationService.getCitiesByRegion(
      _selectedCountry!.code, 
      _selectedRegion!
    );
    setState(() {});
    
    // Si une ville est déjà sélectionnée, charger ses quartiers
    if (_selectedCity != null) {
      _loadNeighborhoods();
    }
  }
  
  void _loadNeighborhoods() {
    if (_selectedCity == null) return;
    
    _availableNeighborhoods = _locationService.getNeighborhoodsByCity(_selectedCity!.id);
    setState(() {});
  }
  
  // Gestion de la recherche
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query.toLowerCase();
      });
    });
  }
  
  // Sélections à chaque niveau
  void _selectCountry(Country country) {
    setState(() {
      _selectedCountry = country;
      _selectedRegion = null;
      _selectedCity = null;
      _selectedNeighborhood = null;
      _currentLevel = 1;
      _searchController.clear();
      _searchQuery = '';
    });
    
    _loadRegions();
    _notifySelection();
  }
  
  void _selectRegion(String region) {
    setState(() {
      _selectedRegion = region;
      _selectedCity = null;
      _selectedNeighborhood = null;
      _currentLevel = 2;
      _searchController.clear();
      _searchQuery = '';
    });
    
    _loadCities();
    _notifySelection();
  }
  
  void _selectCity(City city) {
    setState(() {
      _selectedCity = city;
      _selectedNeighborhood = null;
      _currentLevel = 3;
      _searchController.clear();
      _searchQuery = '';
    });
    
    _loadNeighborhoods();
    _notifySelection();
  }
  
  void _selectNeighborhood(String neighborhood) {
    setState(() {
      _selectedNeighborhood = neighborhood;
      _searchController.clear();
      _searchQuery = '';
      _isExpanded = false;
    });
    
    _notifySelection();
  }
  
  // Notification des changements
  void _notifySelection() {
    final selection = LocationSelection(
      country: _selectedCountry,
      region: _selectedRegion,
      city: _selectedCity,
      neighborhood: _selectedNeighborhood,
    );
    
    widget.onLocationSelected(selection);
  }
  
  // Navigation entre niveaux
  void _goToLevel(int level) {
    if (level < 0 || level > 3) return;
    
    // Vérifier que les prérequis sont remplis
    if (level > 0 && _selectedCountry == null) return;
    if (level > 1 && _selectedRegion == null) return;
    if (level > 2 && _selectedCity == null) return;
    
    setState(() {
      _currentLevel = level;
      _searchController.clear();
      _searchQuery = '';
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Version compacte pour affichage dans les barres de recherche
    if (widget.compact) {
      return _buildCompactSelector();
    }
    
    // Version complète
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Étiquette si fournie
        if (widget.label != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Text(
                  widget.label!,
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.required)
                  Text(
                    ' *',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: context.responsiveFontSize(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ],
        
        // Champ d'entrée principal
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getDisplayText(),
                    style: TextStyle(
                      color: _hasSelection() ? Colors.black : Colors.grey[600],
                      fontSize: context.responsiveFontSize(14),
                    ),
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
        
        // Contenu expansible
        if (_isExpanded)
          _buildExpandedContent().animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),
      ],
    );
  }
  
  Widget _buildCompactSelector() {
    return InkWell(
      onTap: () {
        _showFullScreenSelector(context);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _getShortDisplayText(),
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
    );
  }
  
  Widget _buildExpandedContent() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fil d'Ariane
          _buildBreadcrumbs(),
          
          const SizedBox(height: 16),
          
          // Champ de recherche
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: _getSearchHint(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            ),
            onChanged: _onSearchChanged,
          ),
          
          const SizedBox(height: 16),
          
          // Contenu du niveau actuel
          Expanded(
            child: _buildLevelContent(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBreadcrumbs() {
    return Wrap(
      spacing: 4,
      children: [
        // Pays
        InkWell(
          onTap: () => _goToLevel(0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _currentLevel == 0 ? AppTheme.primaryColor : Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _selectedCountry?.name ?? 'Pays',
              style: TextStyle(
                fontSize: 12,
                color: _currentLevel == 0 ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        
        // Flèche
        if (_selectedCountry != null)
          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        
        // Région
        if (_selectedCountry != null)
          InkWell(
            onTap: () => _goToLevel(1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _currentLevel == 1 ? AppTheme.primaryColor : Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _selectedRegion ?? 'Région',
                style: TextStyle(
                  fontSize: 12,
                  color: _currentLevel == 1 ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        
        // Flèche
        if (_selectedRegion != null)
          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        
        // Ville
        if (_selectedRegion != null)
          InkWell(
            onTap: () => _goToLevel(2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _currentLevel == 2 ? AppTheme.primaryColor : Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _selectedCity?.name ?? 'Ville',
                style: TextStyle(
                  fontSize: 12,
                  color: _currentLevel == 2 ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        
        // Flèche
        if (_selectedCity != null)
          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        
        // Quartier
        if (_selectedCity != null)
          InkWell(
            onTap: () => _goToLevel(3),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _currentLevel == 3 ? AppTheme.primaryColor : Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _selectedNeighborhood ?? 'Quartier',
                style: TextStyle(
                  fontSize: 12,
                  color: _currentLevel == 3 ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildLevelContent() {
    switch (_currentLevel) {
      case 0:
        return _buildCountrySelector();
      case 1:
        return _buildRegionSelector();
      case 2:
        return _buildCitySelector();
      case 3:
        return _buildNeighborhoodSelector();
      default:
        return const SizedBox.shrink();
    }
  }
  
  Widget _buildCountrySelector() {
    // Filtrer les pays si nécessaire
    final countries = _searchQuery.isEmpty
        ? _availableCountries
        : _availableCountries.where((country) => 
            country.name.toLowerCase().contains(_searchQuery)).toList();
    
    // Aucun pays trouvé
    if (countries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 32, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Aucun pays trouvé',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    // Liste des pays
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: countries.length,
      itemBuilder: (context, index) {
        final country = countries[index];
        final isSelected = _selectedCountry?.code == country.code;
        
        return InkWell(
          onTap: () => _selectCountry(country),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: isSelected 
                  ? Border.all(color: AppTheme.primaryColor) 
                  : Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CountryFlagWidget(
                  countryCode: country.code,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  country.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.primaryColor : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildRegionSelector() {
    // Filtrer les régions si nécessaire
    final regions = _searchQuery.isEmpty
        ? _availableRegions
        : _availableRegions.where((region) => 
            region.toLowerCase().contains(_searchQuery)).toList();
    
    // Aucune région trouvée
    if (regions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 32, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Aucune région trouvée',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    // Liste des régions
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2,
      ),
      itemCount: regions.length,
      itemBuilder: (context, index) {
        final region = regions[index];
        final isSelected = _selectedRegion == region;
        
        return InkWell(
          onTap: () => _selectRegion(region),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: isSelected 
                  ? Border.all(color: AppTheme.primaryColor) 
                  : Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_city,
                  size: 20,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                ),
                const SizedBox(height: 8),
                Text(
                  region,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.primaryColor : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCitySelector() {
    // Filtrer les villes si nécessaire
    final cities = _searchQuery.isEmpty
        ? _availableCities
        : _availableCities.where((city) => 
            city.name.toLowerCase().contains(_searchQuery)).toList();
    
    // Aucune ville trouvée
    if (cities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 32, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Aucune ville trouvée',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    // Liste des villes
    return ListView.builder(
      itemCount: cities.length,
      itemBuilder: (context, index) {
        final city = cities[index];
        final isSelected = _selectedCity?.id == city.id;
        
        return ListTile(
          title: Text(
            city.name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppTheme.primaryColor : Colors.black,
            ),
          ),
          subtitle: Text(city.region),
          leading: Icon(
            Icons.location_city,
            color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
          ),
          selected: isSelected,
          selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          onTap: () => _selectCity(city),
        );
      },
    );
  }
  
  Widget _buildNeighborhoodSelector() {
    // Filtrer les quartiers si nécessaire
    final neighborhoods = _searchQuery.isEmpty
        ? _availableNeighborhoods
        : _availableNeighborhoods.where((neighborhood) => 
            neighborhood.toLowerCase().contains(_searchQuery)).toList();
    
    // Aucun quartier trouvé
    if (neighborhoods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 32, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              _availableNeighborhoods.isEmpty 
                  ? 'Aucun quartier disponible pour cette ville'
                  : 'Aucun quartier ne correspond à votre recherche',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // Liste des quartiers
    return ListView.builder(
      itemCount: neighborhoods.length,
      itemBuilder: (context, index) {
        final neighborhood = neighborhoods[index];
        final isSelected = _selectedNeighborhood == neighborhood;
        
        return ListTile(
          title: Text(
            neighborhood,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppTheme.primaryColor : Colors.black,
            ),
          ),
          leading: Icon(
            Icons.location_on,
            color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
          ),
          selected: isSelected,
          selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          onTap: () => _selectNeighborhood(neighborhood),
        );
      },
    );
  }
  
  // Afficher un sélecteur plein écran (pour la version compacte)
  void _showFullScreenSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: MultilevelLocationSelector(
            onLocationSelected: (selection) {
              Navigator.pop(context);
              widget.onLocationSelected(selection);
              
              // Mettre à jour notre propre état
              setState(() {
                _selectedCountry = selection.country;
                _selectedRegion = selection.region;
                _selectedCity = selection.city;
                _selectedNeighborhood = selection.neighborhood;
              });
            },
            initialSelection: LocationSelection(
              country: _selectedCountry,
              region: _selectedRegion,
              city: _selectedCity,
              neighborhood: _selectedNeighborhood,
            ),
            label: 'Sélectionner un lieu',
          ),
        );
      },
    );
  }
  
  // Textes d'affichage
  String _getDisplayText() {
    if (_selectedNeighborhood != null) {
      return '$_selectedNeighborhood, ${_selectedCity?.name}';
    } else if (_selectedCity != null) {
      return '${_selectedCity?.name}, $_selectedRegion';
    } else if (_selectedRegion != null) {
      return '$_selectedRegion, ${_selectedCountry?.name}';
    } else if (_selectedCountry != null) {
      return _selectedCountry!.name;
    } else {
      return widget.hint ?? 'Sélectionner un lieu';
    }
  }
  
  String _getShortDisplayText() {
    if (_selectedNeighborhood != null) {
      return _selectedNeighborhood!;
    } else if (_selectedCity != null) {
      return _selectedCity!.name;
    } else if (_selectedRegion != null) {
      return _selectedRegion!;
    } else if (_selectedCountry != null) {
      return _selectedCountry!.name;
    } else {
      return widget.hint ?? 'Lieu';
    }
  }
  
  String _getSearchHint() {
    switch (_currentLevel) {
      case 0:
        return 'Rechercher un pays...';
      case 1:
        return 'Rechercher une région...';
      case 2:
        return 'Rechercher une ville...';
      case 3:
        return 'Rechercher un quartier...';
      default:
        return 'Rechercher...';
    }
  }
  
  bool _hasSelection() {
    return _selectedCountry != null;
  }
}

/// Classe représentant une sélection de localisation complète
class LocationSelection {
  final Country? country;
  final String? region;
  final City? city;
  final String? neighborhood;
  
  LocationSelection({
    this.country,
    this.region,
    this.city,
    this.neighborhood,
  });
  
  @override
  String toString() {
    final parts = <String>[];
    
    if (neighborhood != null) parts.add(neighborhood!);
    if (city != null) parts.add(city!.name);
    if (region != null) parts.add(region!);
    if (country != null) parts.add(country!.name);
    
    return parts.join(', ');
  }
  
  bool get isEmpty => country == null && region == null && city == null && neighborhood == null;
  bool get isNotEmpty => !isEmpty;
  
  /// Convertit la sélection en Map pour l'API
  Map<String, dynamic> toMap() {
    return {
      'countryCode': country?.code,
      'countryName': country?.name,
      'region': region,
      'cityId': city?.id,
      'cityName': city?.name,
      'neighborhood': neighborhood,
      'latitude': city?.latitude,
      'longitude': city?.longitude,
    };
  }
  
  /// Crée une sélection à partir d'une Map
  factory LocationSelection.fromMap(Map<String, dynamic> map) {
    return LocationSelection(
      country: map['countryCode'] != null 
          ? Country(
              code: map['countryCode'], 
              name: map['countryName'] ?? '', 
              phoneCode: '',
            )
          : null,
      region: map['region'],
      city: map['cityId'] != null 
          ? City(
              id: map['cityId'], 
              name: map['cityName'] ?? '', 
              region: map['region'] ?? '', 
              countryCode: map['countryCode'] ?? '',
              latitude: map['latitude'],
              longitude: map['longitude'],
            )
          : null,
      neighborhood: map['neighborhood'],
    );
  }
}
