import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

import 'package:chapechape_maps/chapechape_maps.dart';
import '../../../core/services/api/maps_service.dart';
import '../../../core/config/app_config.dart';

class AddressSearchResult {
  final LatLng? coordinates;
  final String formattedAddress;
  final Map<String, dynamic>? components;

  AddressSearchResult({
    this.coordinates,
    required this.formattedAddress,
    this.components,
  });
  
  // Accesseurs explicites pour faciliter l'usage dans les formulaires
  double? get latitude => coordinates?.latitude;
  double? get longitude => coordinates?.longitude;
  
  // Convertir en Map pour l'API
  Map<String, dynamic> toJson() {
    return {
      'latitude': coordinates?.latitude,
      'longitude': coordinates?.longitude,
      'formattedAddress': formattedAddress,
      // Ne pas inclure components car il pourrait contenir des structures complexes
    };
  }
}

class AddressAutocompleteField extends StatefulWidget {
  final Function(AddressSearchResult) onAddressSelected;
  final String? initialAddress;
  final String label;
  final String? hintText;
  final bool showMap;
  
  const AddressAutocompleteField({
    Key? key,
    required this.onAddressSelected,
    this.initialAddress,
    this.label = 'Adresse',
    this.hintText = 'Rechercher une adresse',
    this.showMap = true,
  }) : super(key: key);
  
  @override
  _AddressAutocompleteFieldState createState() => _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final MapsService _mapsService = MapsService(baseUrl: AppConfig.apiUrl);
  final LocationService _locationService = LocationService();
  
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;
  Timer? _reverseGeocodeDebounce;
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  GoogleMapController? _mapController;
  bool _isMapReady = false;
  bool _isGettingLocation = false;
  
  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _controller.text = widget.initialAddress!;
      _selectedAddress = widget.initialAddress!;
    }
    
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _getSuggestions(_controller.text);
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _reverseGeocodeDebounce?.cancel();
    super.dispose();
  }
  
  /// Obtient la position actuelle de l'utilisateur et met à jour le champ d'adresse
  Future<void> _getCurrentLocation() async {
    if (_isGettingLocation) return;
    
    setState(() {
      _isGettingLocation = true;
    });
    
    try {
      // Vérifier si la localisation est disponible
      final isAvailable = await _locationService.isLocationAvailable();
      if (!isAvailable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La géolocalisation n\'est pas disponible ou autorisée')),
        );
        setState(() => _isGettingLocation = false);
        return;
      }
      
      // Obtenir la position actuelle
      final position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      
      setState(() {
        _selectedLocation = position;
        _isGettingLocation = false;
      });
      
      // Faire un reverse geocoding pour obtenir l'adresse
      _reverseGeocodeLocation(position);
      
      // Centrer la carte si elle est disponible
      if (_isMapReady && _mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(position, 15));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGettingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de géolocalisation: ${e.toString()}')),
      );
    }
  }
  
  /// Effectue un reverse geocoding pour une position avec un délai pour limiter les appels API
  Future<void> _reverseGeocodeLocation(LatLng position) async {
    // Mettre à jour immédiatement la position pour le marqueur
    setState(() {
      _selectedLocation = position;
      _isLoading = true;
    });
    
    // Annuler toute requête précédente en attente
    if (_reverseGeocodeDebounce?.isActive ?? false) {
      _reverseGeocodeDebounce!.cancel();
    }
    
    // Attendre 800ms avant d'envoyer la requête pour éviter les erreurs 429
    _reverseGeocodeDebounce = Timer(const Duration(milliseconds: 800), () async {
      try {
        if (!mounted) return;
        
        final result = await _mapsService.reverseGeocode(
          position.latitude, 
          position.longitude
        );
        
        if (!mounted) return;
        
        final formattedAddress = result['formattedAddress'] ?? 'Adresse inconnue';
        final components = result['components'];
        
        setState(() {
          _selectedAddress = formattedAddress;
          _controller.text = formattedAddress;
          _isLoading = false;
        });
        
        widget.onAddressSelected(AddressSearchResult(
          coordinates: position,
          formattedAddress: formattedAddress,
          components: components,
        ));
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de géocodage inverse: ${e.toString()}')),
        );
      }
    });
  }
  
  void _getSuggestions(String query) async {
    if (query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      
      setState(() => _isLoading = true);
      
      try {
        final suggestions = await _mapsService.autocompleteAddress(query);
        if (!mounted) return;
        
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    });
  }
  
  Future<void> _selectLocation(Map<String, dynamic> suggestion) async {
    final description = suggestion['description'];
    _controller.text = description;
    
    setState(() {
      _suggestions = [];
      _isLoading = true;
    });
    
    try {
      final geocodeResult = await _mapsService.geocodeAddress(description);
      if (!mounted) return;
      
      final latLng = MapsService.extractLatLng(geocodeResult);
      final formattedAddress = geocodeResult['formattedAddress'] ?? description;
      final components = geocodeResult['components'];
      
      setState(() {
        _selectedLocation = latLng;
        _selectedAddress = formattedAddress;
        _isLoading = false;
      });
      
      widget.onAddressSelected(AddressSearchResult(
        coordinates: latLng,
        formattedAddress: formattedAddress,
        components: components,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de géocodage: ${e.toString()}')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Champ de recherche
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _suggestions = []);
                    },
                  ),
                IconButton(
                  icon: _isGettingLocation
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.my_location),
                  onPressed: _isGettingLocation ? null : _getCurrentLocation,
                  tooltip: 'Utiliser ma position actuelle',
                ),
              ],
            ),
            border: const OutlineInputBorder(),
          ),
          onChanged: _getSuggestions,
        ),
        
        // Indicateur de chargement
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: LinearProgressIndicator(),
          ),
        
        // Liste de suggestions
        if (_suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  title: Text(suggestion['mainText'] ?? ''),
                  subtitle: Text(suggestion['secondaryText'] ?? ''),
                  onTap: () => _selectLocation(suggestion),
                );
              },
            ),
          ),
        
        // Carte (optionnelle)
        if (widget.showMap && _selectedLocation != null)
          Container(
            height: 200, // Hauteur augmentée pour une meilleure visibilité
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Stack(
              children: [
                // Indicateur de chargement
                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black26,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation!,
                      zoom: 16, // Zoom augmenté pour voir plus de détails
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('selected_location'),
                        position: _selectedLocation!,
                        infoWindow: InfoWindow(title: _selectedAddress),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                        draggable: true, // Permet de déplacer le marqueur
                        onDrag: (LatLng position) {
                          // Mise à jour en temps réel pendant le glissement (facultatif)
                          setState(() {
                            _selectedLocation = position;
                          });
                        },
                        onDragStart: (LatLng position) {
                          // Feedback visuel au début du glissement
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Déplacez le marqueur...'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        onDragEnd: (LatLng newPosition) {
                          // Géocodage inverse de la nouvelle position
                          _reverseGeocodeLocation(newPosition);
                          // Feedback visuel à la fin du glissement
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Position mise à jour!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    },
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,
                    zoomControlsEnabled: true,
                    zoomGesturesEnabled: true, // Activer le zoom par pincement
                    scrollGesturesEnabled: true, // Activer le défilement/panoramique
                    rotateGesturesEnabled: true, // Activer la rotation
                    compassEnabled: true, // Afficher la boussole
                    mapToolbarEnabled: true, // Activer la barre d'outils pour accéder à Google Maps, etc.
                    onTap: (LatLng position) {
                      // Permet de sélectionner un point directement sur la carte
                      // Pas besoin de mettre à jour _selectedLocation ici, car c'est fait dans _reverseGeocodeLocation
                      _reverseGeocodeLocation(position);
                    },
                    onMapCreated: (GoogleMapController controller) {
                      setState(() {
                        _mapController = controller;
                        _isMapReady = true;
                        
                        // Centrer la carte sur la position sélectionnée
                        controller.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 16));
                      });
                    },
                  ),
                ),
                // Overlay pour afficher clairement les coordonnées
                if (_selectedLocation != null)
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Coordonnées: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[800]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
