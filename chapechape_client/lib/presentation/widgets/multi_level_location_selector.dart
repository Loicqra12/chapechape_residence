import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/country.dart';
import '../../core/models/region.dart';
import '../../core/models/city.dart';
import '../../core/models/neighborhood.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import 'country_selector_widget.dart';
import 'location_selector_widget.dart';

enum LocationLevel {
  country,
  region,
  city,
  neighborhood
}

/// Widget qui permet la sélection hiérarchique de localisation à plusieurs niveaux
/// (pays → région → ville → quartier)
class MultiLevelLocationSelector extends StatefulWidget {
  /// Callback appelé quand une localisation est sélectionnée à n'importe quel niveau
  final Function(dynamic location, LocationLevel level) onLocationSelected;
  
  /// Niveau de profondeur maximum à afficher
  final LocationLevel maxLevel;
  
  /// Pays initial sélectionné (optionnel)
  final Country? initialCountry;
  
  /// Région initiale sélectionnée (optionnel)
  final Region? initialRegion;
  
  /// Ville initiale sélectionnée (optionnel)
  final City? initialCity;
  
  /// Quartier initial sélectionné (optionnel)
  final Neighborhood? initialNeighborhood;
  
  /// Titre du sélecteur
  final String? title;
  
  /// Si true, ajoute une bordure autour du widget
  final bool showBorder;
  
  /// Si true, affiche un fil d'Ariane (breadcrumb) pour montrer le chemin de sélection
  final bool showBreadcrumb;
  
  const MultiLevelLocationSelector({
    Key? key,
    required this.onLocationSelected,
    this.maxLevel = LocationLevel.neighborhood,
    this.initialCountry,
    this.initialRegion,
    this.initialCity,
    this.initialNeighborhood,
    this.title,
    this.showBorder = true,
    this.showBreadcrumb = true,
  }) : super(key: key);

  @override
  _MultiLevelLocationSelectorState createState() => _MultiLevelLocationSelectorState();
}

class _MultiLevelLocationSelectorState extends State<MultiLevelLocationSelector> with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  
  // État de sélection par niveau
  Country? _selectedCountry;
  Region? _selectedRegion;
  City? _selectedCity;
  Neighborhood? _selectedNeighborhood;
  
  // Niveau actuellement affiché
  LocationLevel _currentLevel = LocationLevel.country;
  
  // Contrôleur pour les animations
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // Direction de l'animation (true = vers la droite, false = vers la gauche)
  bool _animateForward = true;
  
  @override
  void initState() {
    super.initState();
    
    // Initialiser le contrôleur d'animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut)
    );
    
    // Initialiser avec les valeurs initiales fournies
    _initializeSelections();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _initializeSelections() {
    setState(() {
      _selectedCountry = widget.initialCountry;
      _selectedRegion = widget.initialRegion;
      _selectedCity = widget.initialCity;
      _selectedNeighborhood = widget.initialNeighborhood;
    });
    
    // Déterminer le niveau initial à afficher en fonction des sélections initiales
    if (_selectedNeighborhood != null && widget.maxLevel == LocationLevel.neighborhood) {
      _currentLevel = LocationLevel.neighborhood;
    } else if (_selectedCity != null) {
      _currentLevel = _getNextLevel(LocationLevel.city);
    } else if (_selectedRegion != null) {
      _currentLevel = _getNextLevel(LocationLevel.region);
    } else if (_selectedCountry != null) {
      _currentLevel = _getNextLevel(LocationLevel.country);
    }
  }
  
  // Obtenir le prochain niveau dans la hiérarchie
  LocationLevel _getNextLevel(LocationLevel current) {
    switch (current) {
      case LocationLevel.country:
        return LocationLevel.region;
      case LocationLevel.region:
        return LocationLevel.city;
      case LocationLevel.city:
        return widget.maxLevel == LocationLevel.neighborhood 
          ? LocationLevel.neighborhood 
          : LocationLevel.city;
      case LocationLevel.neighborhood:
        return LocationLevel.neighborhood;
    }
  }
  
  // Obtenir le niveau précédent dans la hiérarchie
  LocationLevel _getPreviousLevel(LocationLevel current) {
    switch (current) {
      case LocationLevel.country:
        return LocationLevel.country;
      case LocationLevel.region:
        return LocationLevel.country;
      case LocationLevel.city:
        return LocationLevel.region;
      case LocationLevel.neighborhood:
        return LocationLevel.city;
    }
  }
  
  // Changer de niveau avec animation
  void _changeLevel(LocationLevel newLevel, {bool forward = true}) {
    _animateForward = forward;
    
    // Lancer l'animation de sortie
    _animationController.forward().then((_) {
      setState(() {
        _currentLevel = newLevel;
      });
      
      // Réinitialiser et lancer l'animation d'entrée
      _animationController.reset();
      _animationController.forward();
    });
  }
  
  // Gérer la sélection d'un pays
  void _onCountrySelected(Country country) {
    setState(() {
      _selectedCountry = country;
      
      // Réinitialiser les niveaux inférieurs si le pays change
      if (widget.initialCountry != country) {
        _selectedRegion = null;
        _selectedCity = null;
        _selectedNeighborhood = null;
      }
    });
    
    // Notifier le parent
    widget.onLocationSelected(country, LocationLevel.country);
    
    // Passer au niveau des régions
    _changeLevel(LocationLevel.region);
  }
  
  // Gérer la sélection d'une région
  void _onRegionSelected(Region region) {
    setState(() {
      _selectedRegion = region;
      
      // Réinitialiser les niveaux inférieurs si la région change
      if (widget.initialRegion != region) {
        _selectedCity = null;
        _selectedNeighborhood = null;
      }
    });
    
    // Notifier le parent
    widget.onLocationSelected(region, LocationLevel.region);
    
    // Passer au niveau des villes
    _changeLevel(LocationLevel.city);
  }
  
  // Gérer la sélection d'une ville
  void _onCitySelected(City city) {
    setState(() {
      _selectedCity = city;
      
      // Réinitialiser le quartier si la ville change
      if (widget.initialCity != city) {
        _selectedNeighborhood = null;
      }
    });
    
    // Notifier le parent
    widget.onLocationSelected(city, LocationLevel.city);
    
    // Passer au niveau des quartiers si activé
    if (widget.maxLevel == LocationLevel.neighborhood) {
      _changeLevel(LocationLevel.neighborhood);
    }
  }
  
  // Gérer la sélection d'un quartier
  void _onNeighborhoodSelected(Neighborhood neighborhood) {
    setState(() {
      _selectedNeighborhood = neighborhood;
    });
    
    // Notifier le parent
    widget.onLocationSelected(neighborhood, LocationLevel.neighborhood);
  }
  
  // Revenir au niveau précédent
  void _goBack() {
    final previousLevel = _getPreviousLevel(_currentLevel);
    _changeLevel(previousLevel, forward: false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: widget.showBorder ? BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ) : null,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Titre du sélecteur
          if (widget.title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                widget.title!,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          
          // Fil d'Ariane (Breadcrumb)
          if (widget.showBreadcrumb)
            _buildBreadcrumb(),
            
          const SizedBox(height: 16),
          
          // Contenu du niveau actuel avec animation
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              // Animation de slide horizontale
              final slideValue = _animateForward 
                ? Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).evaluate(_animation)
                : Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).evaluate(_animation);
              
              // Animation d'opacité
              final opacityValue = Tween<double>(begin: 0.0, end: 1.0).evaluate(_animation);
              
              return FractionalTranslation(
                translation: slideValue,
                child: Opacity(
                  opacity: opacityValue,
                  child: _buildCurrentLevelContent(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  // Construire le fil d'Ariane
  Widget _buildBreadcrumb() {
    final List<Widget> items = [];
    
    // Pays
    if (_selectedCountry != null) {
      items.add(
        InkWell(
          onTap: () => _changeLevel(LocationLevel.country, forward: false),
          child: Text(
            _selectedCountry!.name,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    
    // Séparateur
    if (items.isNotEmpty && _selectedRegion != null) {
      items.add(const Text(' > '));
    }
    
    // Région
    if (_selectedRegion != null) {
      items.add(
        InkWell(
          onTap: () => _changeLevel(LocationLevel.region, forward: false),
          child: Text(
            _selectedRegion!.name,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    
    // Séparateur
    if (items.isNotEmpty && _selectedCity != null) {
      items.add(const Text(' > '));
    }
    
    // Ville
    if (_selectedCity != null) {
      items.add(
        InkWell(
          onTap: () => _changeLevel(LocationLevel.city, forward: false),
          child: Text(
            _selectedCity!.name,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    
    // Séparateur
    if (items.isNotEmpty && _selectedNeighborhood != null) {
      items.add(const Text(' > '));
    }
    
    // Quartier
    if (_selectedNeighborhood != null) {
      items.add(
        Text(
          _selectedNeighborhood!.name,
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items,
      ),
    );
  }
  
  // Construire le contenu du niveau actuel
  Widget _buildCurrentLevelContent() {
    switch (_currentLevel) {
      case LocationLevel.country:
        return _buildCountrySelector();
      case LocationLevel.region:
        return _buildRegionSelector();
      case LocationLevel.city:
        return _buildCitySelector();
      case LocationLevel.neighborhood:
        return _buildNeighborhoodSelector();
    }
  }
  
  // Sélecteur de pays
  Widget _buildCountrySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sélectionnez un pays',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        CountrySelectorWidget(
          onCountrySelected: _onCountrySelected,
          initialCountry: _selectedCountry,
          showBorder: false,
        ),
      ],
    );
  }
  
  // Sélecteur de région
  Widget _buildRegionSelector() {
    if (_selectedCountry == null) {
      _changeLevel(LocationLevel.country, forward: false);
      return const SizedBox();
    }
    
    final regions = _locationService.getRegionsByCountry(_selectedCountry!.code);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goBack,
              tooltip: 'Retour',
            ),
            Text(
              'Régions ${_selectedCountry!.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (regions.isEmpty)
          const Center(
            child: Text('Aucune région disponible pour ce pays'),
          )
        else
          _buildRegionGrid(regions),
      ],
    );
  }
  
  // Grille de régions
  Widget _buildRegionGrid(List<Region> regions) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: regions.length,
      itemBuilder: (context, index) {
        final region = regions[index];
        final isSelected = _selectedRegion?.id == region.id;
        
        return InkWell(
          onTap: () => _onRegionSelected(region),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                region.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryColor : Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    ).animate().fadeIn(duration: 300.ms);
  }
  
  // Sélecteur de ville
  Widget _buildCitySelector() {
    if (_selectedCountry == null) {
      _changeLevel(LocationLevel.country, forward: false);
      return const SizedBox();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goBack,
              tooltip: 'Retour',
            ),
            Expanded(
              child: Text(
                _selectedRegion != null 
                  ? 'Villes de ${_selectedRegion!.name}' 
                  : 'Villes ${_selectedCountry!.name}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LocationSelectorWidget(
          onCitySelected: _onCitySelected,
          initialCountry: _selectedCountry,
          initialCity: _selectedCity,
        ),
      ],
    );
  }
  
  // Sélecteur de quartier
  Widget _buildNeighborhoodSelector() {
    if (_selectedCity == null) {
      _changeLevel(LocationLevel.city, forward: false);
      return const SizedBox();
    }
    
    final neighborhoods = _locationService.getNeighborhoodsByCity(_selectedCity!.id);
    final popularNeighborhoods = _locationService.getPopularNeighborhoodsByCity(_selectedCity!.id);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goBack,
              tooltip: 'Retour',
            ),
            Expanded(
              child: Text(
                'Quartiers de ${_selectedCity!.name}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Champ de recherche de quartier
        _buildNeighborhoodSearchField(),
        const SizedBox(height: 16),
        
        // Quartiers populaires
        if (popularNeighborhoods.isNotEmpty) ...[
          Text(
            'Quartiers populaires',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: popularNeighborhoods.map((neighborhood) {
              final isSelected = _selectedNeighborhood?.id == neighborhood.id;
              
              return ChoiceChip(
                label: Text(neighborhood.name),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    _onNeighborhoodSelected(neighborhood);
                  }
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                backgroundColor: Colors.grey.shade100,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        
        // Tous les quartiers
        if (neighborhoods.isNotEmpty) ...[
          Text(
            'Tous les quartiers',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          _buildNeighborhoodGrid(neighborhoods),
        ] else
          const Center(
            child: Text('Aucun quartier disponible pour cette ville'),
          ),
      ],
    );
  }
  
  // Champ de recherche de quartier
  Widget _buildNeighborhoodSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Rechercher un quartier',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      onChanged: (value) {
        // Implement search
      },
    );
  }
  
  // Grille de quartiers
  Widget _buildNeighborhoodGrid(List<Neighborhood> neighborhoods) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: neighborhoods.length,
      itemBuilder: (context, index) {
        final neighborhood = neighborhoods[index];
        final isSelected = _selectedNeighborhood?.id == neighborhood.id;
        
        return InkWell(
          onTap: () => _onNeighborhoodSelected(neighborhood),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                neighborhood.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryColor : Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    ).animate().fadeIn(duration: 300.ms);
  }
}
