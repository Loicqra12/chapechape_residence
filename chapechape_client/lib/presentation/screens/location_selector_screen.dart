import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/blocs/residence/residence_bloc.dart';
import '../../core/models/city.dart';
import '../../core/models/location_suggestion_model.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../widgets/multilevel_location_selector.dart';

class LocationSelectorScreen extends StatefulWidget {
  static const String routeName = '/location-selector';
  
  const LocationSelectorScreen({Key? key}) : super(key: key);

  @override
  State<LocationSelectorScreen> createState() => _LocationSelectorScreenState();
}

class _LocationSelectorScreenState extends State<LocationSelectorScreen> {
  LocationSelection? _selectedLocation;
  final LocationService _locationService = LocationService();
  List<LocationSuggestionModel> _popularLocations = [];
  bool _isLoading = true;
  
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
      });
      print('Erreur lors du chargement des localisations populaires: $e');
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
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir une localisation'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
                style: TextStyle(
                  fontSize: context.responsiveFontSize(18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Affichage des localisations populaires
              Expanded(
                child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _popularLocations.isEmpty
                    ? Center(
                        child: Text(
                          'Aucune localisation populaire disponible',
                          style: TextStyle(color: Colors.grey[600]),
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
  
  Widget _buildPopularLocationTile(LocationSuggestionModel location) {
    final bool isSelected = _selectedLocation?.city?.name == location.city && 
                           _selectedLocation?.neighborhood == location.district;
    
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
                        color: isSelected ? AppTheme.primaryColor : Colors.black,
                      ),
                    ),
                    Text(
                      location.fullAddress,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(14),
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${location.searchCount}+',
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(12),
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 300.ms, delay: 50.ms * _popularLocations.indexOf(location))
      .slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
  }
}
