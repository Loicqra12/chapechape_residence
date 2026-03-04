import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/text_styles.dart';
import '../../core/extensions/residence_marker_extension.dart';
import '../../core/models/residence_type_enum.dart';
import '../../core/utils/map_cluster_manager.dart';

import '../../core/models/residence_model.dart';
import '../../core/services/location_service.dart';
import '../../core/services/residence_service.dart';

/// Écran affichant une carte en plein écran avec les résidences à proximité
class FullMapScreen extends StatefulWidget {
  /// Coordonnées du centre de la carte
  final double centerLat;
  final double centerLng;
  
  /// Titre optionnel pour la résidence principale
  final String? title;
  
  /// Identifiant de la résidence principale (optionnel)
  final String? residenceId;

  /// Rayon de recherche en kilomètres (par défaut = 5km)
  final double searchRadius;

  const FullMapScreen({
    required this.centerLat,
    required this.centerLng,
    this.title,
    this.residenceId,
    this.searchRadius = 5.0,
    Key? key,
  }) : super(key: key);

  @override
  State<FullMapScreen> createState() => _FullMapScreenState();
}

class _FullMapScreenState extends State<FullMapScreen> {
  final LocationService _locationService = LocationService();
  late final ResidenceService _residenceService;
  
  // Contrôleurs
  GoogleMapController? _mapController;
  
  // Variables pour le clustering
  double _currentZoom = 15.0; // Niveau de zoom initial
  
  // Données
  List<Residence> _nearbyResidences = [];
  Set<Marker> _markers = {};
  LatLng? _userLocation;
  
  // États
  bool _isLoading = true;
  Residence? _selectedResidence;
  
  // Filtres
  final Set<String> _activeFilters = <String>{}; // Catégories actives
  List<Residence> _filteredResidences = [];
  MapType _mapType = MapType.normal;
  
  // Désactivé - nous utilisons maintenant des marqueurs avec prix intégré style Booking.com
  bool _showPricesAboveMarkers = false;
  
  // Map pour stocker les coordonnées d'écran calculées de façon synchrone
  final Map<String, Offset> _screenCoordinates = {};
  
  @override
  void initState() {
    super.initState();
    
    // Désactiver les overlays de prix pour utiliser les marqueurs avec prix intégrés
    _showPricesAboveMarkers = false;
    
    // Vider le cache des marqueurs pour voir les changements de design immédiatement
    ResidenceMarkerExtension.clearMarkerCache();
    
    _initialize();
  }
  
  Future<void> _initServices() async {
    // Initialiser le service de résidence
    _residenceService = await ResidenceService.initialize();
  }
  
  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
  
  Future<void> _initialize() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // AJOUT CRITIQUE: Initialiser les services d'abord
      await _initServices();
      debugPrint('DEBUG: Services initialisés avec succès');
      
      // Nous allons générer les marqueurs de prix au moment de l'affichage
      // plutôt qu'ici pour avoir les prix exacts de chaque résidence
      debugPrint('DEBUG: Les marqueurs de prix seront générés dynamiquement');
      
      // Récupérer la position de l'utilisateur
      await _getCurrentLocation();
      
      // Récupérer les résidences à proximité
      await _fetchNearbyResidences();
      
      // NE PAS mettre à jour les marqueurs ici - attendre onMapCreated()
      // _updateMarkersOnMap(); // Supprimé car le controller n'est pas encore prêt
      
      // Indiquer que le chargement est terminé
      setState(() {
        _isLoading = false;
      });
      
      // IMPORTANT: Calculer les coordonnées d'écran APRÈS que tout soit chargé
      // et seulement si le mode overlay est activé et que le map controller existe
      if (_showPricesAboveMarkers && _nearbyResidences.isNotEmpty && _mapController != null) {
        debugPrint('DEBUG: Calcul initial des coordonnées d\'écran depuis _initialize()');
        await _calculateScreenCoordinates();
      }
      
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _getCurrentLocation() async {
    try {
      final hasPermission = await _locationService.requestLocationPermission();
      
      if (!hasPermission) {
        // Utiliser uniquement les coordonnées centrales fournies
        return;
      }
      
      final position = await _locationService.getCurrentUserLocation();
      if (position != null) {
        setState(() {
          _userLocation = position;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la position: $e');
    }
  }
  
  Future<void> _fetchNearbyResidences() async {
    try {
      debugPrint('DEBUG: Début du chargement des résidences...');
      final center = LatLng(widget.centerLat, widget.centerLng);
      
      debugPrint('DEBUG: Appel de getAllResidences avec center=$center, rayon=${widget.searchRadius}');
      // Récupérer les résidences à proximité du centre en utilisant getAllResidences avec filtres
      // Puisque ResidenceService n'a pas de méthode getNearbyResidences spécifique
      final residences = await _residenceService.getAllResidences(
        filters: {
          'latitude': center.latitude,
          'longitude': center.longitude,
          'distance': widget.searchRadius, // Utilisation du rayon passé en paramètre
        },
        limit: 20, // Limite à 20 résidences pour des performances optimales
        forceRefresh: true, // Pour obtenir les données les plus récentes
      );
      
      debugPrint('DEBUG: ${residences.length} résidences récupérées');
      
      // Vérifier que les résidences ont des coordonnées valides
      for (final r in residences) {
        debugPrint('DEBUG: Résidence ${r.id} - lat: ${r.latitude}, lng: ${r.longitude}');
      }
      
      setState(() {
        _nearbyResidences = residences;
      });
    } catch (e) {
      debugPrint('Erreur lors de la récupération des résidences à proximité: $e');
    }
  }
  
  /// Met à jour les marqueurs en générant d'abord les icônes avec prix exacts
  void _updateMarkers() {
    // Générer les marqueurs de prix personnalisés avant d'afficher les pins
    _preGenerateMarkers();
  }
  
  /// Pré-génère les marqueurs prix (avec état sélectionné si besoin)
  Future<void> _preGenerateMarkers() async {
    final residencesToShow = _activeFilters.isEmpty ? _nearbyResidences : _filteredResidences;
    if (residencesToShow.isEmpty) return;

    final Set<Marker> markers = await SimpleClusterUtility.createClusteredMarkers(
      residences: residencesToShow,
      zoom: _currentZoom,
      selectedResidenceId: _selectedResidence?.id,
      onMarkerTap: (residence) {
        setState(() => _selectedResidence = residence);
        // Regénère pour mettre à jour l'état visuel du marqueur sélectionné
        Future.microtask(_preGenerateMarkers);
      },
    );

    setState(() => _markers = markers);
  }

  /// Met à jour les marqueurs sur la carte
  void _updateMarkersOnMap() {
    if (_mapController == null || _nearbyResidences.isEmpty) return;
    
    final Set<Marker> markers = <Marker>{};
    
    // Mode d'affichage selon infoWindow ou overlays
    // ============= MODE INFO WINDOWS (SANS OVERLAYS) =============
    if (!_showPricesAboveMarkers) {
      // Résidence principale
      if (widget.residenceId != null && _nearbyResidences.isNotEmpty) {
        final mainResidence = _nearbyResidences.firstWhere(
          (r) => r.id == widget.residenceId,
          orElse: () => _nearbyResidences.first,
        );
        
        markers.add(
          Marker(
            markerId: const MarkerId('main_residence'),
            position: LatLng(widget.centerLat, widget.centerLng),
            infoWindow: InfoWindow(
              title: widget.title ?? 'Résidence principale',
              snippet: 'XOF ${mainResidence.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match match) => ' ')}',
              onTap: () {
                // Navigation vers la résidence principale si nécessaire
              },
            ),
            icon: mainResidence.getMarkerIcon(),
            consumeTapEvents: true,
          ),
        );
      }
      
      // Sélectionner la liste à utiliser selon les filtres actifs
      final residencesToShow = _activeFilters.isEmpty ? _nearbyResidences : _filteredResidences;
      
      // Marqueurs des résidences avec InfoWindow prix
      for (final residence in residencesToShow) {
        if (widget.residenceId != null && residence.id == widget.residenceId) {
          continue; // Éviter duplication
        }
        
        double? lat = residence.latitude;
        double? lng = residence.longitude;
        
        if (lat != null && lng != null) {
          final markerId = MarkerId('residence_${residence.id}');
          markers.add(
            Marker(
              markerId: markerId,
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: residence.title,
                snippet: 'XOF ${residence.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (Match match) => ' ')}',
                onTap: () {
                  context.push('/residence/${residence.id}');
                },
              ),
              icon: residence.getMarkerIcon(), // Couleur par catégorie
              consumeTapEvents: true,
              onTap: () {
                setState(() {
                  _selectedResidence = residence;
                });
                
                // Afficher InfoWindow automatiquement
                if (_mapController != null) {
                  _mapController!.showMarkerInfoWindow(markerId);
                }
              },
            ),
          );
        }
      }
    } 
    // ============= MODE OVERLAYS DE PRIX (SANS INFOWINDOWS) =============
    else {
      // Marqueurs MINIMALISTES sans InfoWindow
      // Résidence principale
      if (widget.residenceId != null && _nearbyResidences.isNotEmpty) {
        final mainResidence = _nearbyResidences.firstWhere(
          (r) => r.id == widget.residenceId,
          orElse: () => _nearbyResidences.first,
        );
        
        markers.add(
          Marker(
            markerId: const MarkerId('main_residence'),
            position: LatLng(widget.centerLat, widget.centerLng),
            icon: mainResidence.getMarkerIcon(),
            consumeTapEvents: false, // Laisser les overlays gérer les taps
          ),
        );
      }
      
      // Sélectionner la liste à utiliser selon les filtres actifs
      final residencesToShow = _activeFilters.isEmpty ? _nearbyResidences : _filteredResidences;
      
      // Marqueurs simples SANS InfoWindow pour ne pas interférer avec overlays
      for (final residence in residencesToShow) {
        if (widget.residenceId != null && residence.id == widget.residenceId) {
          continue;
        }
        
        double? lat = residence.latitude;
        double? lng = residence.longitude;
        
        if (lat != null && lng != null) {
          markers.add(
            Marker(
              markerId: MarkerId('residence_${residence.id}'),
              position: LatLng(lat, lng),
              icon: residence.getMarkerIcon(),
              // Activer consumeTapEvents pour gérer manuellement les taps
              consumeTapEvents: true, 
              onTap: () {
                debugPrint('DEBUG: Marker tapped for residence ${residence.id}');
                setState(() {
                  _selectedResidence = residence;
                });
              },
            ),
          );
        }
      }
    }
    
    // Marqueur position utilisateur (toujours présent)
    if (_userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLocation!,
          infoWindow: const InfoWindow(
            title: 'Ma position',
            snippet: 'Votre position actuelle',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }
    
    setState(() {
      _markers = markers;
    });
  }
  
  // Méthode pour calculer et stocker les coordonnées d'écran des résidences
  Future<void> _calculateScreenCoordinates() async {
    if (_mapController == null || _nearbyResidences.isEmpty) {
      debugPrint('DEBUG: _calculateScreenCoordinates skipped - mapController: ${_mapController != null}, residences: ${_nearbyResidences.length}');
      return;
    }
    
    debugPrint('DEBUG: _calculateScreenCoordinates started with ${_nearbyResidences.length} residences');
    _screenCoordinates.clear();
    
    // Récupérer les limites visibles de la carte pour ne traiter que les résidences visibles
    LatLngBounds? visibleRegion;
    try {
      visibleRegion = await _mapController!.getVisibleRegion();
    } catch (error) {
      debugPrint('DEBUG: Erreur lors de la récupération des limites visibles: $error');
      // Continuons sans filtrage par région visible
    }

    // Obtenir les dimensions de l'écran
    final Size screenSize = MediaQuery.of(context).size;
    
    for (final residence in _nearbyResidences) {
      double? lat = residence.latitude;
      double? lng = residence.longitude;
      
      if (lat != null && lng != null) {
        final LatLng position = LatLng(lat, lng);
        
        // Vérifier si la résidence est dans les limites visibles de la carte
        bool isVisible = visibleRegion != null && 
          lat >= visibleRegion.southwest.latitude && 
          lat <= visibleRegion.northeast.latitude &&
          lng >= visibleRegion.southwest.longitude && 
          lng <= visibleRegion.northeast.longitude;
          
        if (!isVisible) {
          debugPrint('DEBUG: Résidence ${residence.id} hors écran visible, ignorée');
          continue; // Ignorer les résidences hors écran
        }

        try {
          final screenCoordinate = await _mapController!.getScreenCoordinate(position);
          
          // Vérifier que les coordonnées écran sont valides (dans les limites de l'écran ou proches)
          // Ajouter une marge pour les éléments partiellement visibles
          final double margin = 300; // pixels
          bool isOnScreen = 
              screenCoordinate.x >= -margin && 
              screenCoordinate.x <= screenSize.width + margin &&
              screenCoordinate.y >= -margin && 
              screenCoordinate.y <= screenSize.height + margin;
              
          if (!isOnScreen) {
            debugPrint('DEBUG: Coordonnées écran invalides pour ${residence.id}: ${screenCoordinate.x}, ${screenCoordinate.y}');
            continue; // Ne pas enregistrer les coordonnées invalides
          }
          
          _screenCoordinates[residence.id] = Offset(
            screenCoordinate.x.toDouble(),
            screenCoordinate.y.toDouble(),
          );
          debugPrint('DEBUG: Calculated screen coords for ${residence.id}: ${screenCoordinate.x}, ${screenCoordinate.y}');
        } catch (e) {
          debugPrint('Erreur calcul coordonnées écran pour ${residence.id}: $e');
        }
      } else {
        debugPrint('DEBUG: Invalid coordinates for ${residence.id}: lat=$lat, lng=$lng');
      }
    }
    
    debugPrint('DEBUG: _screenCoordinates map now has ${_screenCoordinates.length} entries');
    
    // Déclencher rebuild pour afficher les overlays
    if (mounted) {
      setState(() {});
    }
  }

  Set<Circle> _createPriceCircles() {
    final Set<Circle> circles = {};
    
    for (final residence in _nearbyResidences) {
      try {
        // Utiliser l'extension pour accéder aux coordonnées
        double? lat = residence.latitude;
        double? lng = residence.longitude;
        
        if (lat != null && lng != null) {
          circles.add(
            Circle(
              circleId: CircleId('price_${residence.id}'),
              center: LatLng(lat, lng),
              radius: 50, // Rayon en mètres
              fillColor: Colors.blue.withOpacity(0.2),
              strokeColor: Colors.blue,
              strokeWidth: 1,
            ),
          );
        }
      } catch (e) {
        debugPrint('Erreur lors de la création du cercle de prix: $e');
      }
    }
    
    return circles;
  }
  
  Future<void> _launchMapsUrl(double lat, double lng, String title) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=${Uri.encodeComponent(title)}'
    );
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Impossible d\'ouvrir Google Maps');
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
  
  // Afficher toutes les InfoWindows pour montrer les prix
  void _showAllInfoWindows() {
    if (_mapController == null) return;
    
    // Afficher toutes les InfoWindows des résidences à proximité pour voir les prix
    for (final residence in _nearbyResidences) {
      if (residence.latitude != null && residence.longitude != null) {
        final markerId = MarkerId('residence_${residence.id}');
        _mapController!.showMarkerInfoWindow(markerId);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Carte des résidences'),
        actions: [
          if (_userLocation != null)
            IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'Ma position',
              onPressed: () => _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(_userLocation!, 15),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            tooltip: 'Filtrer',
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Plus d\'options',
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(widget.centerLat, widget.centerLng),
                  zoom: 14.0,
                ),
                mapType: _mapType,
                markers: _markers,
                circles: _createPriceCircles(),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  debugPrint('DEBUG: Map créée, controller assigné');
                  
                  // Générer les marqueurs de prix personnalisés avant de les afficher
                  // Cette méthode asynchrone génèrera les marqueurs avec les prix exacts
                  // et mettra à jour la carte automatiquement une fois terminée
                  _preGenerateMarkers();
                  
                  // Si les overlays de prix sont activés ET que les résidences sont chargées,
                  // calculer les coordonnées d'écran avec un délai pour que la carte soit stabilisée
                  // Note: nous n'utilisons plus cette option car les prix sont intégrés aux marqueurs
                  if (_showPricesAboveMarkers && _nearbyResidences.isNotEmpty) {
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (_mapController != null && mounted) {
                        debugPrint('DEBUG: Calcul des coordonnées d\'écran depuis onMapCreated après délai');
                        _calculateScreenCoordinates();
                      }
                    });
                  }
                },
                onCameraMove: (position) {
                  // Stocker le zoom actuel pour le clustering
                  _currentZoom = position.zoom;
                },
                onCameraIdle: () {
                  // Mettre à jour les marqueurs avec clustering lorsque la caméra s'arrête
                  _preGenerateMarkers();
                },
              ),
              
              // Note: Overlays de prix supprimés - les prix sont maintenant intégrés directement dans les marqueurs
              
              // Panel de filtres par type de résidence (en haut)
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.smd),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildFilterChip(ResidenceMarkerExtension.categoryMeubles, 'Meublés', Icons.home_outlined),
                          SizedBox(width: AppSpacing.sm),
                          _buildFilterChip(ResidenceMarkerExtension.categoryHotels, 'Hôtels', Icons.hotel_outlined),
                          SizedBox(width: AppSpacing.sm),
                          _buildFilterChip(ResidenceMarkerExtension.categoryInsolites, 'Insolites', Icons.forest_outlined),
                          SizedBox(width: AppSpacing.sm),
                          _buildFilterChip(ResidenceMarkerExtension.categoryColocations, 'Colocation', Icons.people_outlined),
                          SizedBox(width: AppSpacing.sm),
                          _buildFilterChip(ResidenceMarkerExtension.categoryLongueDuree, 'Long terme', Icons.calendar_month_outlined),
                          SizedBox(width: AppSpacing.sm),
                          _buildFilterChip(ResidenceMarkerExtension.categoryEconomiques, 'Économique', Icons.savings_outlined),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Bouton d'itinéraire (visible uniquement si une résidence est sélectionnée)
              if (_selectedResidence != null)
                Positioned(
                  bottom: 120,
                  right: 10,
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      if (_selectedResidence != null && 
                          _selectedResidence!.latitude != null && 
                          _selectedResidence!.longitude != null) {
                        _launchMapsUrl(
                          _selectedResidence!.latitude!,
                          _selectedResidence!.longitude!,
                          _selectedResidence!.name,
                        );
                      }
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Itinéraire'),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              
              // Suppression du chip statique "Centre-ville"
              
              // Widget détaillé pour la résidence sélectionnée (en bas de l'écran)
              if (_selectedResidence != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildResidenceDetailCard(_selectedResidence!),
                ),
              
              // Boutons pour navigation, couches, etc. (optionnel)
              Positioned(
                bottom: 16,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: 'layers',
                      mini: true,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black54,
                      child: const Icon(Icons.layers),
                      onPressed: _showLayersPopup,
                    ),
                    AppSpacing.verticalSm,
                    FloatingActionButton(
                      heroTag: 'target',
                      mini: true,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black54,
                      child: const Icon(Icons.gps_fixed),
                      onPressed: () async {
                        if (_userLocation != null && _mapController != null) {
                          _mapController!.animateCamera(
                            CameraUpdate.newLatLngZoom(_userLocation!, 15),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
  
  // ── Popup filtres ────────────────────────────────────────────────────────
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final categories = [
          (ResidenceMarkerExtension.categoryMeubles,    'Meublés',    Icons.home_outlined),
          (ResidenceMarkerExtension.categoryHotels,     'Hôtels',     Icons.hotel_outlined),
          (ResidenceMarkerExtension.categoryInsolites,  'Insolites',  Icons.forest_outlined),
          (ResidenceMarkerExtension.categoryColocations,'Colocation', Icons.people_outlined),
          (ResidenceMarkerExtension.categoryLongueDuree,'Long terme', Icons.calendar_month_outlined),
          (ResidenceMarkerExtension.categoryEconomiques,'Économique', Icons.savings_outlined),
        ];
        return StatefulBuilder(builder: (ctx, setSt) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filtrer par catégorie',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((c) {
                    final isOn = _activeFilters.contains(c.$1);
                    return FilterChip(
                      avatar: Icon(c.$3,
                          size: 16,
                          color: isOn ? Colors.white : AppTheme.textSecondary),
                      label: Text(c.$2),
                      selected: isOn,
                      selectedColor: AppTheme.primaryColor,
                      checkmarkColor: Colors.white,
                      backgroundColor: AppTheme.dividerColor,
                      labelStyle: TextStyle(
                          color: isOn ? Colors.white : AppTheme.textPrimary,
                          fontWeight: isOn ? FontWeight.w600 : FontWeight.normal),
                      onSelected: (v) {
                        setSt(() {
                          v ? _activeFilters.add(c.$1) : _activeFilters.remove(c.$1);
                        });
                        setState(() {
                          _updateFilteredResidences();
                          _preGenerateMarkers();
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Appliquer'),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // ── Popup type de carte (couches) ─────────────────────────────────────────
  void _showLayersPopup() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Type de carte',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.map_outlined, color: AppTheme.textPrimary),
                title: const Text('Standard'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _mapType = MapType.normal);
                },
              ),
              ListTile(
                leading: Icon(Icons.satellite_alt_outlined, color: AppTheme.textPrimary),
                title: const Text('Satellite'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _mapType = MapType.satellite);
                },
              ),
              ListTile(
                leading: Icon(Icons.terrain_outlined, color: AppTheme.textPrimary),
                title: const Text('Hybride'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _mapType = MapType.hybrid);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Popup plus d'options ─────────────────────────────────────────────────
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppTheme.dividerColor, borderRadius: BorderRadius.circular(2)),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt_outlined),
            title: const Text('Voir la liste'),
            onTap: () { Navigator.pop(context); context.pop(); },
          ),
          ListTile(
            leading: const Icon(Icons.gps_fixed_outlined),
            title: const Text('Centrer sur ma position'),
            onTap: () {
              Navigator.pop(context);
              if (_userLocation != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(_userLocation!, 14),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.filter_list_off_outlined),
            title: const Text('Effacer les filtres'),
            onTap: () {
              Navigator.pop(context);
              setState(() { _activeFilters.clear(); });
              _updateFilteredResidences();
              _preGenerateMarkers();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Méthode pour construire la carte de détail d'une résidence sélectionnée
  Widget _buildResidenceDetailCard(Residence residence) {
    // Formatage du prix avec la devise
    final priceText = residence.price > 0 
        ? 'XOF ${residence.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ' ')}'
        : 'Prix sur demande';
    
    // Période de prix
    final periodText = residence.pricePeriod.isNotEmpty 
        ? _getPeriodLabel(residence.pricePeriod)
        : '/nuit';
    
    return GestureDetector(
      onTap: () => context.push('/residence/${residence.id}'),
      child: Container(
        margin: AppSpacing.pagePadding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: SizedBox(
            height: 175,
            child: Row(
              children: [
                // Image de la résidence
                SizedBox(
                  width: 140,
                  height: 175,
                  child: Stack(
                    children: [
                      // Image principale
                      residence.images.isNotEmpty
                        ? Image.network(
                            residence.images[0],
                            width: 140,
                            height: 160,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: AppTheme.dividerColor,
                              child: const Icon(Icons.home, size: 50),
                            ),
                          )
                        : Container(
                            color: AppTheme.dividerColor,
                            child: const Icon(Icons.home, size: 50),
                          ),
                      
                      // Badge VIP/Featured si applicable
                      if (residence.isVip || residence.isFeatured)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: AppSpacing.smd / 2, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: residence.isVip ? Colors.orange : Colors.green,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Text(
                              residence.isVip ? 'VIP' : 'Populaire',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      
                      // Badge prix en bas à gauche
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: Colors.blue[700],
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: Text(
                            '$priceText$periodText',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Détails de la résidence (padding réduit pour éviter overflow)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre et rating
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                residence.title.isNotEmpty ? residence.title : 'Résidence sans nom',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Badge rating
                            if (residence.rating > 0)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: AppSpacing.smd / 2, vertical: AppSpacing.xs / 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[800],
                                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      residence.rating.toStringAsFixed(1),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: AppSpacing.xs / 2),
                                    const Icon(Icons.star, color: Colors.white, size: 12),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        
                        AppSpacing.verticalXs,
                        
                        // Adresse
                        Text(
                          residence.location.displayAddress.isNotEmpty 
                              ? residence.location.displayAddress 
                              : 'Adresse non disponible',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Type de résidence
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: AppTheme.dividerColor,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            residence.type.displayName,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 2),
                        
                        // Amenities (max 3, une ligne)
                        if (residence.amenities.isNotEmpty)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: residence.amenities.take(3).map((amenity) {
                              final amenityIcon = _getAmenityIcon(amenity);
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(amenityIcon, size: 12, color: AppTheme.textSecondary),
                                    const SizedBox(width: 2),
                                    Text(
                                      _getAmenityLabel(amenity),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Afficher les détails',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: AppTheme.primaryColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Méthode utilitaire pour le formatage des périodes
  String _getPeriodLabel(String period) {
    switch (period.toLowerCase()) {
      case 'hour':
        return '/heure';
      case 'day':
        return '/jour';
      case 'week':
        return '/semaine';
      case 'month':
        return '/mois';
      case 'year':
        return '/an';
      default:
        return '/nuit';
    }
  }
  
  // Méthode utilitaire pour les icônes d'amenities
  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'parking':
        return Icons.local_parking;
      case 'pool':
      case 'swimming_pool':
        return Icons.pool;
      case 'gym':
      case 'fitness':
        return Icons.fitness_center;
      case 'ac':
      case 'air_conditioning':
        return Icons.ac_unit;
      case 'kitchen':
        return Icons.kitchen;
      case 'breakfast':
        return Icons.free_breakfast;
      case 'pets':
        return Icons.pets;
      case 'smoking':
        return Icons.smoking_rooms;
      case 'balcony':
        return Icons.balcony;
      default:
        return Icons.star;
    }
  }
  
  // Méthode utilitaire pour les labels d'amenities
  String _getAmenityLabel(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return 'WiFi';
      case 'parking':
        return 'Parking';
      case 'pool':
      case 'swimming_pool':
        return 'Piscine';
      case 'gym':
      case 'fitness':
        return 'Gym';
      case 'ac':
      case 'air_conditioning':
        return 'Clim';
      case 'kitchen':
        return 'Cuisine';
      case 'wifi':
        return 'WiFi';
      case 'pets':
        return 'Animaux';
      case 'smoking':
        return 'Fumeur';
      case 'balcony':
        return 'Balcon';
      default:
        // Sécuriser le substring pour éviter les RangeError
        return amenity.length > 6 ? amenity.substring(0, 6) : amenity;
    }
  }
  
  List<Widget> _buildPriceOverlays() {
    // Retourner une liste vide si l'affichage des prix est désactivé
    if (!_showPricesAboveMarkers) {
      debugPrint('DEBUG: _buildPriceOverlays skipped - _showPricesAboveMarkers: false');
      return [];
    }
    
    // Sélectionner la liste à utiliser selon les filtres actifs
    final residencesToShow = _activeFilters.isEmpty ? _nearbyResidences : _filteredResidences;
    
    debugPrint('DEBUG: _buildPriceOverlays called - residences: ${residencesToShow.length}, screenCoords: ${_screenCoordinates.length}');
    
    final List<Widget> overlays = [];
    
    for (final residence in residencesToShow) {
      try {
        // Utiliser les coordonnées d'écran précalculées
        final screenCoord = _screenCoordinates[residence.id];
        
        // Utiliser une marge pour afficher plus d'overlays, cohérente avec celle de _calculateScreenCoordinates
        final double margin = 150; // Marge réduite par rapport au 300 de _calculateScreenCoordinates
        final Size screenSize = MediaQuery.of(context).size;
        
        if (screenCoord != null && 
            screenCoord.dx > -margin && 
            screenCoord.dy > -margin &&
            screenCoord.dx < screenSize.width + margin &&
            screenCoord.dy < screenSize.height + margin) {
          
          debugPrint('DEBUG: Creating overlay for ${residence.id} at ${screenCoord.dx}, ${screenCoord.dy}');
          
          overlays.add(
            Positioned(
              left: screenCoord.dx - 40, // Centrer le widget sur les coordonnées, légèrement ajusté
              top: screenCoord.dy - 40, // Positionner au-dessus du marker, plus proche comme dans Booking
              child: GestureDetector(
                onTap: () {
                  context.push('/residence/${residence.id}');
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.smd, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900, // Bleu foncé comme dans Booking
                    borderRadius: BorderRadius.circular(AppSpacing.smd / 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  // Style simplifié comme Booking, uniquement le prix
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'XOF ${residence.price.toStringAsFixed(0).replaceAllMapped(
                          RegExp(r'\B(?=(\d{3})+(?!\d))'), 
                          (Match match) => ' '
                        )}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else {
          debugPrint('DEBUG: Skipping overlay for ${residence.id} - screenCoord: $screenCoord');
        }
      } catch (e) {
        debugPrint('Erreur lors de la création de l\'overlay de prix pour ${residence.id}: $e');
      }
    }
    
    debugPrint('DEBUG: _buildPriceOverlays returning ${overlays.length} overlays');
    return overlays;
  }

  // Chip de filtre uniforme — icône Material + couleur or
  Widget _buildFilterChip(String category, String label, IconData icon) {
    final bool isSelected = _activeFilters.contains(category);
    return FilterChip(
      avatar: Icon(icon,
          size: 15,
          color: isSelected ? Colors.white : AppTheme.textSecondary),
      label: Text(label),
      selected: isSelected,
      checkmarkColor: Colors.white,
      selectedColor: AppTheme.primaryColor,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? Colors.white : AppTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      onSelected: (bool selected) {
        setState(() {
          selected ? _activeFilters.add(category) : _activeFilters.remove(category);
          _updateFilteredResidences();
        });
        _preGenerateMarkers();
      },
    );
  }

  // Met à jour les résidences filtrées en fonction des filtres actifs
  void _updateFilteredResidences() {
    if (_activeFilters.isEmpty) {
      _filteredResidences = List.from(_nearbyResidences);
    } else {
      _filteredResidences = _nearbyResidences.where((residence) {
        return _activeFilters.contains(residence.markerCategory);
      }).toList();
    }
    setState(() {}); // Pour déclencher une mise à jour de l'UI
  }
}
