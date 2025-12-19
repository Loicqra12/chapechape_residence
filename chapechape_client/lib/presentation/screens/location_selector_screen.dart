import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/models/city.dart';
import '../../core/models/location_suggestion_model.dart';
import '../../core/services/location_service.dart';
import '../../core/services/logger_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../widgets/multilevel_location_selector.dart';
import '../widgets/common/empty_state_widget.dart';

class LocationSelectorScreen extends StatefulWidget {
  static const String routeName = '/location-selector';
  
  const LocationSelectorScreen({Key? key}) : super(key: key);

  @override
  State<LocationSelectorScreen> createState() => _LocationSelectorScreenState();
}

class _LocationSelectorScreenState extends State<LocationSelectorScreen> {
  LocationSelection? _selectedLocation;
  final LocationService _locationService = LocationService();
  final LoggerService _logger = LoggerService();
  List<LocationSuggestionModel> _popularLocations = [];
  bool _isLoading = true;
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    _loadPopularLocations();
  }
  
  Future<void> _loadPopularLocations() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final locations = await _locationService.getPopularLocations();
      setState(() {
        _popularLocations = locations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      _logger.error('Erreur lors du chargement des localisations populaires: $e');
    }
  }
  
  void _onLocationSelected(LocationSelection selection) {
    setState(() {
      _selectedLocation = selection;
    });
    
    // Si une localisation complète est sélectionnée, mettre à jour le filtre et retourner
    if (selection.city != null) {
      _applyLocationFilter(selection);
    }
  }
  
  void _applyLocationFilter(LocationSelection selection) {
    // Mettre à jour le filtre de résidences via le bloc
    final residenceBloc = BlocProvider.of<ResidenceBloc>(context, listen: false);
    residenceBloc.add(FilterResidencesByLocation(
      cityId: selection.city?.id,
      region: selection.region,
      countryCode: selection.country?.code,
      neighborhood: selection.neighborhood,
    ));
    
    // Retourner à l'écran précédent
    Navigator.pop(context, selection);
  }
  
  void _selectPopularLocation(LocationSuggestionModel suggestion) {
    _logger.debug('Sélection de localisation populaire: ${suggestion.name}');
    
    try {
      // Convertir le modèle de suggestion en sélection de localisation
      final city = _locationService.getCitiesByCountry('ci').firstWhere(
        (city) => city.name.toLowerCase() == (suggestion.city ?? '').toLowerCase(),
        orElse: () => City(
          id: 'unknown',
          name: suggestion.city ?? 'Inconnu',
          region: '',
          countryCode: 'ci',
          latitude: suggestion.latitude ?? 0,
          longitude: suggestion.longitude ?? 0,
        ),
      );
      
      final country = _locationService.getCountryByCode('ci');
      
      final selection = LocationSelection(
        country: country,
        region: city.region,
        city: city,
        neighborhood: suggestion.district,
      );
      
      _onLocationSelected(selection);
    } catch (e) {
      _logger.error('Erreur lors de la sélection de localisation populaire: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur lors de la sélection de cette localisation'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir une localisation', 
          semanticsLabel: 'Écran de sélection de localisation'),
        elevation: 0,
        backgroundColor: isDarkMode ? Colors.black12 : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        actions: [
          if (_selectedLocation != null && _selectedLocation!.isNotEmpty)
            TextButton(
              onPressed: () {
                _applyLocationFilter(_selectedLocation!);
              },
              child: Text(
                'Appliquer',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sélecteur de localisation principal
              MultilevelLocationSelector(
                onLocationSelected: _onLocationSelected,
                initialSelection: _selectedLocation,
                label: 'Où cherchez-vous une résidence ?',
                hint: 'Sélectionnez un lieu',
                required: true,
              ),
              
              const SizedBox(height: 24),
              
              // Localisations populaires
              Text(
                'Localisations populaires',
                semanticsLabel: 'Section des localisations les plus recherchées',
                style: TextStyle(
                  fontSize: context.responsiveFontSize(18),
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Affichage des localisations populaires
              Expanded(
                child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _popularLocations.isEmpty
                     ? _hasError 
                        ? _buildErrorState()
                        : Center(
                            child: SingleChildScrollView(
                              child: EmptyStateWidget(
                                imagePath: 'assets/images/empty_states/empty_location_illustration.png',
                                title: 'Aucune localisation trouvée',
                                subtitle: 'Vérifiez votre connexion ou utilisez la recherche ci-dessus',
                                fallbackIcon: Icons.location_off_outlined,
                                padding: const EdgeInsets.all(24.0),
                                imageHeight: 150,
                              ),
                            ),
                          )
                    : ListView.builder(
                        itemCount: _popularLocations.length,
                        itemBuilder: (context, index) {
                          final location = _popularLocations[index];
                          return _buildPopularLocationTile(location);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Affichage de l'état d'erreur avec possibilité de réessayer
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Impossible de charger les localisations',
            style: TextStyle(
              fontSize: context.responsiveFontSize(16),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Vérifiez votre connexion et réessayez',
            style: TextStyle(
              fontSize: context.responsiveFontSize(14),
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _logger.debug('Tentative de rechargement des localisations populaires');
              _loadPopularLocations();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPopularLocationTile(LocationSuggestionModel location) {
    final bool isSelected = _selectedLocation?.city?.name == location.city && 
                           _selectedLocation?.neighborhood == location.district;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      color: isDarkMode ? Colors.grey[850] : Colors.white,
      child: InkWell(
        onTap: () => _selectPopularLocation(location),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(16),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppTheme.primaryColor : isDarkMode ? Colors.white : Colors.black,
                      ),
                      semanticsLabel: 'Localisation: ${location.name}',
                    ),
                    Text(
                      location.fullAddress,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(14),
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      semanticsLabel: 'Adresse: ${location.fullAddress}',
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${location.searchCount}+',
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(12),
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.grey[700],
                  ),
                  semanticsLabel: '${location.searchCount} recherches',
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 300.ms, delay: _calculateDelay(location))
      .slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
  }
  
  // Calcule un délai adapté pour l'animation des éléments de liste
  Duration _calculateDelay(LocationSuggestionModel location) {
    // Limiter le délai maximum à 1000ms pour ne pas trop retarder l'animation des derniers éléments
    final index = _popularLocations.indexOf(location);
    final delay = 50 * index;
    return delay > 1000 ? 1000.ms : delay.ms;
  }

  @override
  void dispose() {
    // Nettoyer les ressources pour éviter les fuites de mémoire
    _logger.debug('Nettoyage des ressources LocationSelectorScreen');
    super.dispose();
  }
}
