import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/models/city.dart';
import '../../core/models/country.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import 'country_selector_widget.dart';

class LocationSelectorWidget extends StatefulWidget {
  final Function(City) onCitySelected;
  final Country? initialCountry;
  final City? initialCity;
  final String? label;
  final String? hintText;

  const LocationSelectorWidget({
    Key? key,
    required this.onCitySelected,
    this.initialCountry,
    this.initialCity,
    this.label,
    this.hintText,
  }) : super(key: key);

  @override
  State<LocationSelectorWidget> createState() => _LocationSelectorWidgetState();
}

class _LocationSelectorWidgetState extends State<LocationSelectorWidget> {
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  
  late Country _selectedCountry;
  City? _selectedCity;
  List<City> _suggestions = [];
  List<City> _popularCities = [];
  List<String> _regions = [];
  
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    
    // Initialiser le pays sélectionné (Côte d'Ivoire par défaut)
    _selectedCountry = widget.initialCountry ?? 
      Country(code: 'ci', name: 'Côte d\'Ivoire', phoneCode: '+225');
    
    // Initialiser la ville si fournie
    _selectedCity = widget.initialCity;
    if (_selectedCity != null) {
      _searchController.text = _selectedCity!.name;
    }
    
    // Charger les villes populaires et les régions pour le pays sélectionné
    _loadPopularCities();
    _loadRegions();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
  
  // Charger les villes populaires du pays sélectionné
  void _loadPopularCities() {
    _popularCities = _locationService.getPopularCitiesByCountry(_selectedCountry.code);
    setState(() {});
  }
  
  // Charger les régions du pays sélectionné
  void _loadRegions() {
    _regions = _locationService.getRegionNamesByCountry(_selectedCountry.code);
    setState(() {});
  }
  
  // Méthode appelée quand un pays est sélectionné
  void _onCountrySelected(Country country) {
    setState(() {
      _selectedCountry = country;
      // Réinitialiser la ville sélectionnée si le pays change
      if (_selectedCity != null && _selectedCity!.countryCode != country.code) {
      _selectedCity = null;
        _searchController.clear();
      }
    });
    
    // Recharger les données pour le nouveau pays
    _loadPopularCities();
    _loadRegions();
  }
  
  // Méthode de recherche de villes avec debounce
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        setState(() {
          _isSearching = true;
          _suggestions = _locationService.searchCities(
            query, 
            countryCode: _selectedCountry.code
          );
        });
      } else {
        setState(() {
          _isSearching = false;
          _suggestions = [];
        });
      }
    });
  }
  
  // Méthode appelée quand une ville est sélectionnée
  void _onCitySelected(City city) {
    setState(() {
      _selectedCity = city;
      _searchController.text = city.name;
      _isSearching = false;
      _suggestions = [];
    });
    widget.onCitySelected(city);
  }

  @override
  Widget build(BuildContext context) {
    // Version compacte pour utilisation dans le tiroir
    if (MediaQuery.of(context).size.width < 500) {
      return InkWell(
        onTap: () => _showLocationPicker(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
            Icon(Icons.location_on, size: 18, color: AppTheme.primaryColor),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _selectedCity?.name ?? 'Sélectionner',
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      );
    }
    
    // Version normale pour l'écran principal
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
        // Sélecteur de pays
        CountrySelectorWidget(
          onCountrySelected: _onCountrySelected,
          initialCountry: _selectedCountry,
          showLabel: true,
        ),
        
        const SizedBox(height: 16),
        
        // Champ de recherche de localisation
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  widget.label!,
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            
            // Champ de recherche
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Rechercher une ville ou une commune',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _isSearching = false;
                            _suggestions = [];
                            _selectedCity = null;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              ),
              onChanged: _onSearchChanged,
            ),
          ],
        ),
        
        // Affichage des suggestions de recherche
        if (_isSearching && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 200),
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
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final city = _suggestions[index];
                return ListTile(
                  title: Text(city.name),
                  subtitle: Text(_regions.contains(city.region) ? city.region : ''),
                  onTap: () {
                    _onCitySelected(city);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          )
        else if (!_isSearching && _selectedCity == null)
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Villes populaires
                if (_popularCities.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      'Villes populaires',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(14),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _popularCities.map((city) {
                      return InkWell(
                        onTap: () => _onCitySelected(city),
                        child: Chip(
                          label: Text(city.name),
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
                        ),
                      );
                    }).toList(),
                  ),
                ],
                
                // Régions
                if (_regions.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(
                      'Régions',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(14),
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _regions.map((region) {
                      return InkWell(
                        onTap: () {
                          // Afficher les villes de cette région dans un modal
                          _showCitiesInRegion(region);
                        },
                        child: Chip(
                          label: Text(region),
                          backgroundColor: Colors.blue[50],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
  
  // Afficher les villes d'une région dans un modal
  void _showCitiesInRegion(String region) {
    final cities = _locationService.getCitiesByRegion(_selectedCountry.code, region);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poignée de glissement
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 15),
                width: 60,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            
            // Titre avec région
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Villes en $region',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Liste des villes
            Expanded(
              child: ListView.builder(
                itemCount: cities.length,
                itemBuilder: (context, index) {
                  final city = cities[index];
                  return ListTile(
                    title: Text(city.name),
                    onTap: () {
                      _onCitySelected(city);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // Afficher un picker de localisation complet
  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poignée de glissement
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                Text(
                  'Sélectionner une localisation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Sélecteur de pays complet
                CountrySelectorWidget(
                  onCountrySelected: _onCountrySelected,
                  initialCountry: _selectedCountry,
                  showLabel: true,
                ),
                
                const SizedBox(height: 16),
                
                // Champ de recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher une ville ou une commune',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: _onSearchChanged,
                ),
                
                const SizedBox(height: 16),
                
                // Résultats ou options populaires
                Expanded(
                  child: _isSearching && _suggestions.isNotEmpty
                    ? ListView.builder(
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          final city = _suggestions[index];
                          return ListTile(
                            title: Text(city.name),
                            subtitle: Text(_regions.contains(city.region) ? city.region : ''),
                            onTap: () {
                              _onCitySelected(city);
                              Navigator.pop(context);
                            },
                          );
                        },
                      )
                    : ListView(
                        children: [
                          Text(
                            'Villes populaires',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _popularCities.map((city) {
                              return ActionChip(
                                label: Text(city.name),
                                onPressed: () {
                                  _onCitySelected(city);
                                  Navigator.pop(context);
                                },
                              );
                            }).toList(),
                          ),
                          if (_regions.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Régions',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _regions.map((region) {
                                return ActionChip(
                                  label: Text(region),
                                  onPressed: () {
                                    _showCitiesInRegion(region);
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
