import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/nearby_residences_service.dart';
import '../../../core/models/residence_model.dart';
import '../../../core/services/map_provider/google_maps_service.dart';
import '../../../core/extensions/residence_marker_extension.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../widgets/common/empty_state_widget.dart';

class NearbyResidencesScreen extends StatefulWidget {
  const NearbyResidencesScreen({Key? key}) : super(key: key);

  @override
  State<NearbyResidencesScreen> createState() => _NearbyResidencesScreenState();
}

class _NearbyResidencesScreenState extends State<NearbyResidencesScreen> {
  // Services
  final NearbyResidencesService _nearbyService = NearbyResidencesService();
  final GoogleMapsService _mapService = GoogleMapsService();
  
  // Contrôleur de carte Google Maps
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  
  // État de l'écran
  bool _isLoading = false;
  bool _isLocationEnabled = false;
  List<Residence> _residences = [];
  double _currentRadius = 2.0; // Rayon par défaut en km
  String? _selectedCategoryId;
  String? _selectedTypeId;
  
  // Position actuelle de l'utilisateur
  double? _currentLat;
  double? _currentLng;
  
  // Marqueurs pour la carte
  final Set<Marker> _markers = {};
  
  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }
  
  // Initialiser la localisation et charger les résidences à proximité
  Future<void> _initializeLocation() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Demander la permission de localisation
      final hasPermission = await _mapService.requestLocationPermission();
      
      if (!hasPermission) {
        setState(() {
          _isLoading = false;
          _isLocationEnabled = false;
        });
        _showPermissionError();
        return;
      }
      
      // Obtenir la position actuelle
      final locationData = await _mapService.getCurrentLocation();
      
      if (locationData != null) {
        setState(() {
          _currentLat = locationData['latitude'];
          _currentLng = locationData['longitude'];
          _isLocationEnabled = true;
        });
        
        // Charger les résidences à proximité
        await _loadNearbyResidences();
      } else {
        setState(() {
          _isLoading = false;
          _isLocationEnabled = false;
        });
        _showLocationError();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLocationEnabled = false;
      });
      _showLocationError();
      print('Erreur de localisation: $e');
    }
  }
  
  // Charger les résidences à proximité
  Future<void> _loadNearbyResidences() async {
    if (_currentLat == null || _currentLng == null) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Appeler le service pour obtenir les résidences à proximité
      final residences = await _nearbyService.getNearbyResidences(
        latitude: _currentLat!,
        longitude: _currentLng!,
        radius: _currentRadius,
        categoryId: _selectedCategoryId,
        typeId: _selectedTypeId,
      );
      
      setState(() {
        _residences = residences;
        _isLoading = false;
      });
      
      // Mettre à jour les marqueurs sur la carte
      _updateMapMarkers();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Erreur lors du chargement des résidences: $e');
    }
  }
  
  // Mettre à jour les marqueurs sur la carte - MARQUEURS BLEU FONCÉ UNIFORMES
  Future<void> _updateMapMarkers() async {
    setState(() {
      _markers.clear();
    });
    
    // Ajouter un marqueur pour la position actuelle
    if (_currentLat != null && _currentLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(_currentLat!, _currentLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Ma position'),
        ),
      );
    }
    
    // Ajouter des marqueurs pour chaque résidence avec le nouveau système unifié
    for (final residence in _residences) {
      if (residence.location.containsKey('coordinates')) {
        // Utiliser le nouveau système de marqueurs unifié avec icônes et prix
        final BitmapDescriptor markerIcon = await ResidenceMarkerExtension.generateMarkerForResidence(residence);
        
        _markers.add(
          Marker(
            markerId: MarkerId(residence.id ?? 'residence_${_residences.indexOf(residence)}'),
            position: LatLng(_getLatitude(residence.location), _getLongitude(residence.location)),
            icon: markerIcon,
            infoWindow: InfoWindow(
              title: residence.name,
              snippet: residence.formattedAddress,
              onTap: () => _onMarkerTap(residence),
            ),
          ),
        );
      }
    }
    
    setState(() {});
  }
  
  // Afficher une erreur d'autorisation
  void _showPermissionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Veuillez autoriser l\'accès à votre localisation pour utiliser cette fonctionnalité'),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  // Afficher une erreur de localisation
  void _showLocationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impossible d\'obtenir votre position actuelle'),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  // Gérer le tap sur un marqueur
  void _onMarkerTap(Residence residence) {
    // Naviguer vers la page de détails de la résidence
    Navigator.of(context).pushNamed(
      '/residence-details',
      arguments: residence,
    );
  }
  
  // Helper pour extraire la latitude d'une location
  double _getLatitude(Map<String, dynamic>? location) {
    if (location == null) return 0.0;
    
    // Essayer d'abord avec coordinates[1] (format GeoJSON)
    if (location['coordinates'] is List && (location['coordinates'] as List).length > 1) {
      final lat = location['coordinates'][1];
      if (lat is num) return lat.toDouble();
    }
    
    // Sinon essayer avec le champ latitude directement
    if (location['latitude'] != null) {
      final lat = location['latitude'];
      if (lat is num) return lat.toDouble();
      if (lat is String) return double.tryParse(lat) ?? 0.0;
    }
    
    return 0.0;
  }
  
  // Helper pour extraire la longitude d'une location
  double _getLongitude(Map<String, dynamic>? location) {
    if (location == null) return 0.0;
    
    // Essayer d'abord avec coordinates[0] (format GeoJSON)
    if (location['coordinates'] is List && (location['coordinates'] as List).length > 0) {
      final lng = location['coordinates'][0];
      if (lng is num) return lng.toDouble();
    }
    
    // Sinon essayer avec le champ longitude directement
    if (location['longitude'] != null) {
      final lng = location['longitude'];
      if (lng is num) return lng.toDouble();
      if (lng is String) return double.tryParse(lng) ?? 0.0;
    }
    
    return 0.0;
  }
  
  // Construire l'interface utilisateur
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autour de moi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNearbyResidences,
          ),
        ],
      ),
      body: _isLocationEnabled
          ? _buildContent()
          : _buildLocationDisabledContent(),
    );
  }
  
  // Construire le contenu avec la permission de localisation
  Widget _buildContent() {
    return Column(
      children: [
        // Filtres et contrôles
        _buildFilterBar(),
        
        // Carte et liste
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildMapAndList(),
        ),
      ],
    );
  }
  
  // Construire la barre de filtre
  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rayon de recherche
          Row(
            children: [
              const Icon(Icons.social_distance, size: 20),
              SizedBox(width: AppSpacing.sm),
              const Text('Rayon:'),
              Expanded(
                child: Slider(
                  value: _currentRadius,
                  min: 0.5,
                  max: 10.0,
                  divisions: 19,
                  label: '${_currentRadius.toStringAsFixed(1)} km',
                  onChanged: (value) {
                    setState(() {
                      _currentRadius = value;
                    });
                  },
                  onChangeEnd: (value) {
                    _loadNearbyResidences();
                  },
                ),
              ),
              Text('${_currentRadius.toStringAsFixed(1)} km'),
            ],
          ),
          
          // TODO: Ajouter des filtres pour les catégories et types de résidences
        ],
      ),
    );
  }
  
  // Construire la carte et la liste
  Widget _buildMapAndList() {
    return Column(
      children: [
        // Carte Google Maps
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(_currentLat ?? 5.3599517, _currentLng ?? -4.0082563),
                zoom: 14.0,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
          ),
        ),
        
        // Liste des résidences
        Expanded(
          flex: 2,
          child: _residences.isEmpty
              ? SingleChildScrollView(
                  child: EmptyStateWidget(
                    imagePath: 'assets/images/empty_states/empty_nearby_illustration.png',
                    title: 'Aucune résidence à proximité',
                    subtitle: 'Élargissez votre rayon de recherche ou explorez une nouvelle zone',
                    fallbackIcon: Icons.location_off_outlined,
                    action: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _currentRadius = 10.0;
                        });
                        _loadNearbyResidences();
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Élargir la zone (10 km)'),
                      style: ElevatedButton.styleFrom(
                        padding: AppSpacing.buttonPadding,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: _residences.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final residence = _residences[index];
                    return _buildResidenceListItem(residence);
                  },
                ),
        ),
      ],
    );
  }
  
  // Construire un élément de la liste des résidences
  Widget _buildResidenceListItem(Residence residence) {
    // Calculer la distance entre la résidence et la position actuelle
    String distanceText = '';
    if (_currentLat != null && _currentLng != null) {
      final distance = _mapService.calculateDistance(
        _currentLat!,
        _currentLng!,
        _getLatitude(residence.location),
        _getLongitude(residence.location),
      );
      distanceText = '${distance.toStringAsFixed(1)} km';
    }
    
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: residence.imageUrl != null && residence.imageUrl!.isNotEmpty
            ? NetworkImage(residence.imageUrl!)
            : null,
        child: residence.imageUrl == null || residence.imageUrl!.isEmpty
            ? Icon(Icons.home, color: Theme.of(context).primaryColor)
            : null,
      ),
      title: Text(
        residence.name ?? 'Sans nom',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(residence.formattedAddress ?? 'Adresse inconnue'),
          if (distanceText.isNotEmpty)
            Text(
              'Distance: $distanceText',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _onMarkerTap(residence),
    );
  }
  
  // Construire le contenu quand la localisation est désactivée
  Widget _buildLocationDisabledContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_disabled, size: 64, color: Colors.grey),
          AppSpacing.verticalMd,
          Text(
            'Localisation désactivée',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.verticalSm,
          Text(
            'Veuillez autoriser l\'accès à votre localisation pour voir les résidences à proximité',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          AppSpacing.verticalLg,
          ElevatedButton.icon(
            icon: const Icon(Icons.location_on),
            label: const Text('Activer la localisation'),
            onPressed: _initializeLocation,
          ),
        ],
      ),
    );
  }
}
