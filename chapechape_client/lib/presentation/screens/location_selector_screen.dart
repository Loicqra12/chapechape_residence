import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/models/city.dart';
import '../../core/models/location_suggestion_model.dart';
import '../../core/services/location_service.dart';
import '../../core/services/logger_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/text_styles.dart';
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
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir une localisation', 
          semanticsLabel: 'Écran de sélection de localisation'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          if (_selectedLocation != null && _selectedLocation!.isNotEmpty)
            TextButton(
              onPressed: () {
                _applyLocationFilter(_selectedLocation!);
              },
              child: Text(
                'Appliquer',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pagePadding,
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
              
              AppSpacing.verticalLg,
              
              // Localisations populaires
              Text(
                'Localisations populaires',
                semanticsLabel: 'Section des localisations les plus recherchées',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              
              AppSpacing.verticalSmd,
              
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
                                padding: EdgeInsets.all(AppSpacing.lg),
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
          AppSpacing.verticalMd,
          Text(
            'Impossible de charger les localisations',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.verticalSm,
          Text(
            'Vérifiez votre connexion et réessayez',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.verticalMd,
          ElevatedButton(
            onPressed: () {
              _logger.debug('Tentative de rechargement des localisations populaires');
              _loadPopularLocations();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.textLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
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
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.smd),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: () => _selectPopularLocation(location),
        borderRadius: BorderRadius.circular(AppSpacing.smd),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.smd),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                color: isSelected ? AppTheme.primaryColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                size: 24,
              ),
              SizedBox(width: AppSpacing.smd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppTheme.primaryColor : Theme.of(context).colorScheme.onSurface,
                      ),
                      semanticsLabel: 'Localisation: ${location.name}',
                    ),
                    Text(
                      location.fullAddress,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      semanticsLabel: 'Adresse: ${location.fullAddress}',
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppSpacing.smd),
                ),
                child: Text(
                  '${location.searchCount}+',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
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
