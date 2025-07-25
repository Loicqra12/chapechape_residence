import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import 'map_widget.dart';

/// Widget permettant de sélectionner une position sur une carte
class LocationPicker extends StatefulWidget {
  /// Position initiale (optionnelle)
  final LatLng? initialPosition;
  
  /// Callback appelé quand une position est sélectionnée
  final Function(LatLng position, String? address) onPositionSelected;
  
  /// Hauteur du widget
  final double height;
  
  /// Afficher le champ de recherche
  final bool showSearchField;
  
  /// Texte d'indication du champ de recherche
  final String searchHint;
  
  /// Constructeur
  const LocationPicker({
    super.key,
    this.initialPosition,
    required this.onPositionSelected,
    this.height = 300,
    this.showSearchField = true,
    this.searchHint = 'Rechercher une adresse',
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  /// Contrôleur de la carte
  GoogleMapController? _mapController;
  
  /// Service de géocodage
  final GeocodingService _geocodingService = GeocodingService();
  
  /// Service de localisation
  final LocationService _locationService = LocationService();
  
  /// Position sélectionnée actuellement
  LatLng? _selectedPosition;
  
  /// Marqueur pour la position sélectionnée
  Set<Marker> _markers = {};
  
  /// Contrôleur pour le champ de recherche
  final TextEditingController _searchController = TextEditingController();
  
  /// Indique si une recherche est en cours
  bool _isSearching = false;
  
  /// Liste de suggestions de lieu
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    
    // Initialiser la position sélectionnée
    _selectedPosition = widget.initialPosition;
    
    // Si une position initiale est fournie, créer un marqueur
    if (_selectedPosition != null) {
      _updateMarker(_selectedPosition!);
      _updateAddressFromPosition(_selectedPosition!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Champ de recherche
        if (widget.showSearchField) _buildSearchField(),
        
        // Carte
        SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              // Widget de carte
              MapWidget(
                initialPosition: _selectedPosition ?? 
                    _locationService.currentPosition,
                initialZoom: 15,
                markers: _markers,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                onTap: (position) {
                  _updateMarker(position);
                  _updateAddressFromPosition(position);
                },
              ),
              
              // Indicateur de position centrale
              Center(
                child: _selectedPosition == null
                    ? Icon(
                        Icons.location_pin,
                        color: Theme.of(context).primaryColor,
                        size: 36,
                      )
                    : const SizedBox.shrink(),
              ),
              
              // Indicateur de chargement
              if (_isSearching)
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Construit le champ de recherche avec autocomplétion
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: widget.searchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: _goToCurrentLocation,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 16,
              ),
            ),
            onChanged: _onSearchChanged,
          ),
          
          // Liste de suggestions
          if (_suggestions.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  return ListTile(
                    title: Text(_suggestions[index]),
                    onTap: () => _onSuggestionSelected(_suggestions[index]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
  
  /// Met à jour le marqueur sur la carte
  void _updateMarker(LatLng position) {
    setState(() {
      _selectedPosition = position;
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          draggable: true,
          onDragEnd: (newPosition) {
            _updateMarker(newPosition);
            _updateAddressFromPosition(newPosition);
          },
        ),
      };
    });
  }
  
  /// Met à jour l'adresse à partir d'une position
  Future<void> _updateAddressFromPosition(LatLng position) async {
    final address = await _geocodingService.getAddressFromCoordinates(position);
    widget.onPositionSelected(position, address);
    
    if (address != null && mounted) {
      _searchController.text = address;
    }
  }
  
  /// Gère le changement de texte dans le champ de recherche
  Future<void> _onSearchChanged(String value) async {
    if (value.length < 3) {
      setState(() {
        _suggestions = [];
      });
      return;
    }
    
    // Implémenter une recherche de lieux ici
    // Pour l'instant, c'est une implémentation simplifiée
    setState(() {
      _isSearching = true;
      _suggestions = ['Chargement des suggestions...'];
    });
    
    // TODO: Implémenter une vraie recherche d'adresses avec l'API Places
    // Pour l'instant, on simule une recherche
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() {
        _isSearching = false;
        _suggestions = [
          '$value - Option 1',
          '$value - Option 2',
          '$value - Option 3',
        ];
      });
    }
  }
  
  /// Gère la sélection d'une suggestion
  Future<void> _onSuggestionSelected(String address) async {
    setState(() {
      _suggestions = [];
      _isSearching = true;
      _searchController.text = address;
    });
    
    // Obtenir les coordonnées de l'adresse
    final coordinates = await _geocodingService.getCoordinatesFromAddress(address);
    
    if (coordinates != null && mounted) {
      _updateMarker(coordinates);
      
      // Animer la caméra vers la position
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(coordinates, 15),
      );
      
      widget.onPositionSelected(coordinates, address);
    }
    
    if (mounted) {
      setState(() {
        _isSearching = false;
      });
    }
  }
  
  /// Va à la position actuelle de l'utilisateur
  Future<void> _goToCurrentLocation() async {
    setState(() {
      _isSearching = true;
    });
    
    try {
      final position = await _locationService.getCurrentPosition();
      
      if (mounted) {
        _updateMarker(position);
        _updateAddressFromPosition(position);
        
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(position, 15),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }
}
