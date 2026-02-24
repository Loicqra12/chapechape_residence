import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/residence_model.dart';
import '../../core/models/residence_type_enum.dart';
import '../../core/services/location_service.dart';
import '../../core/services/nearby_residences_service.dart';
import '../../core/extensions/residence_extensions.dart';
import '../../core/extensions/residence_marker_extension.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_styles.dart';
import 'advanced_search_widget.dart';

/// Widget qui affiche les résidences à proximité de l'utilisateur
class AroundMeWidget extends StatefulWidget {
  /// Titre du widget
  final String title;

  /// Sous-titre optionnel
  final String? subtitle;

  /// Nombre d'éléments à afficher
  final int itemCount;

  /// Rayon de recherche en km
  final double radiusKm;
  
  /// Si true, affiche une carte en plus de la liste
  final bool showMap;

  /// Constructeur
  const AroundMeWidget({
    this.title = 'Autour de moi',
    this.subtitle = 'Découvrez des résidences proches de votre position',
    this.itemCount = 5,
    this.radiusKm = 5.0,
    this.showMap = true,
    super.key,
  });

  @override
  State<AroundMeWidget> createState() => _AroundMeWidgetState();
}

class _AroundMeWidgetState extends State<AroundMeWidget> with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final NearbyResidencesService _nearbyResidencesService = NearbyResidencesService();
  
  // Variables d'état
  LatLng? _userLocation;
  bool _isPermissionDenied = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Contrôleurs
  late AnimationController _animationController;
  final Completer<GoogleMapController> _mapControllerCompleter = Completer<GoogleMapController>();

  // Données
  List<Residence> _nearbyResidences = [];
  Set<Marker> _markers = {};
  int _hoveredIndex = -1;
  Residence? _selectedMarkerResidence;
  
  // Filtres
  String? _selectedCategory;
  String? _selectedType;
  double _searchRadius = 3.0; // km, valeur par défaut
  
  // Filtres avancés
  String? _searchTerm;
  String? _selectedCity; // Changer le type de City? à String?
  DateTimeRange? _selectedDateRange; // Conservé pour une future implémentation de filtrage par dates
  RangeValues? _priceRange;
  
  // Rayon de recherche courant (peut être modifié contrairement à widget.radiusKm qui est final)
  double _currentRadius = 0.0;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    
    // Augmenter le rayon de recherche par défaut pour trouver plus de résidences
    _currentRadius = widget.radiusKm > 5.0 ? widget.radiusKm : 10.0; // Utiliser au moins 10km
    _searchRadius = 5.0; // Valeur par défaut pour le slider
    
    _initialize();
  }
  
  /// Affiche le widget de recherche avancée dans une modal bottom sheet
  void _showAdvancedSearch() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true, // Pour occuper tout l'écran
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9, // 90% de la hauteur
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.only(top: 8),
        // Utiliser SingleChildScrollView pour rendre tout le contenu scrollable
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: AdvancedSearchWidget(
              onSearch: (searchParams) {
                Navigator.pop(context, searchParams);
              },
            ),
          ),
        ),
      ),
    );
    
    // Si l'utilisateur a sélectionné des filtres, les appliquer
    if (result != null) {
      setState(() {
        // Récupérer les filtres avancés
        _searchTerm = result['searchTerm'];
        _selectedCity = result['city']; // C'est une String
        _selectedDateRange = result['dateRange'];
        _priceRange = result['priceRange'];
        
        // Mettre à jour les filtres existants
        if (result['residenceType'] != null) {
          _selectedType = result['residenceType'];
        }
        if (result['categoryId'] != null) {
          _selectedCategory = result['categoryId'];
        }
      });
      
      // Appliquer les nouveaux filtres
      _applyAdvancedFilters();
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  /// Initialise les données du widget
  Future<void> _initialize() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
      
      // 1. Vérifier les permissions de localisation
      final hasPermission = await _locationService.requestLocationPermission();
      
      if (!mounted) return;
      
      setState(() {
        _isPermissionDenied = !hasPermission;
      });
      
      if (!hasPermission) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // 2. Récupérer la position de l'utilisateur
      final position = await _locationService.getCurrentUserLocation();
      
      if (!mounted) return;
      
      if (position != null) {
        final userLocation = LatLng(position.latitude, position.longitude);
        
        setState(() {
          _userLocation = userLocation;
        });
        
        // Charger les résidences à proximité
        await _loadNearbyResidences();
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Impossible de déterminer votre position';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Une erreur est survenue lors de l\'initialisation: $e';
      });
    }
  }
  
  /// Applique les filtres avancés aux résidences chargées
  Future<void> _applyAdvancedFilters() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Si la géolocalisation n'est pas disponible, ne rien faire
      if (_userLocation == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Charger toutes les résidences à proximité d'abord
      final residences = await _nearbyResidencesService.getNearbyResidences(
        latitude: _userLocation!.latitude,
        longitude: _userLocation!.longitude,
        radius: _currentRadius,
        limit: 50, // Augmentation de la limite pour avoir plus de résultats à filtrer
        categoryId: _selectedCategory, // Utiliser le filtre catégorie directement dans l'API si possible
        typeId: _selectedType, // Utiliser le filtre type directement dans l'API si possible
      );
      
      // Appliquer les filtres avancés côté client
      final List<Residence> filteredResidences = residences.where((residence) {
        // Filtre de recherche textuelle
        if (_searchTerm != null && _searchTerm!.isNotEmpty) {
          final searchLower = _searchTerm!.toLowerCase();
          
          // Vérifier les correspondances du terme de recherche dans les propriétés de la résidence
          // Utilisation de try-catch pour éviter les erreurs de null ou de format
          bool titleMatches = false;
          try {
            // Vérifier si le titre contient le terme de recherche
            if (residence.title.isNotEmpty) {
              titleMatches = residence.title.toLowerCase().contains(searchLower);
            }
          } catch (e) {
            // En cas d'erreur, ignorer cette correspondance
          }
          
          bool descMatches = false;
          try {
            // Vérifier si la description contient le terme de recherche
            if (residence.description.isNotEmpty) {
              descMatches = residence.description.toLowerCase().contains(searchLower);
            }
          } catch (e) {
            // En cas d'erreur, ignorer cette correspondance
          }
          
          bool addressMatches = false;
          try {
            // Vérifier si l'adresse contient le terme de recherche
            if (residence.address.isNotEmpty) {
              addressMatches = residence.address.toLowerCase().contains(searchLower);
            }
          } catch (e) {
            // En cas d'erreur, ignorer cette correspondance
          }
          
          if (!titleMatches && !descMatches && !addressMatches) {
            return false;
          }
        }
        
        // Filtre par ville
        if (_selectedCity != null && _selectedCity!.isNotEmpty) {
          // Vérifier si l'adresse contient la ville
          final bool cityInAddress = residence.address != null && 
              residence.address.toLowerCase().contains(_selectedCity!.toLowerCase());
          
          // Vérifier la ville dans location si disponible
          bool cityInLocation = false;
          if (residence.location != null && 
              residence.location.containsKey('city') && 
              residence.location['city'] != null) {
            final cityValue = residence.location['city'].toString().toLowerCase();
            cityInLocation = cityValue == _selectedCity!.toLowerCase();
          }
          
          if (!cityInAddress && !cityInLocation) {
            return false;
          }
        }
        
        // Filtre par fourchette de prix
        if (_priceRange != null) {
          final price = residence.price;
          if (price == null || 
             (price < _priceRange!.start || price > _priceRange!.end)) {
            return false;
          }
        }
        
        // Note: Filtre par dates désactivé car les données de disponibilité ne sont pas encore implémentées
        // Cette fonctionnalité sera implémentée ultérieurement avec les vraies données de disponibilité
        
        return true;
      }).toList();
      
      // Tri des résidences par distance
      filteredResidences.sort((a, b) {
        final distanceA = _calculateDistanceToResidence(a);
        final distanceB = _calculateDistanceToResidence(b);
        return distanceA.compareTo(distanceB);
      });
      
      if (!mounted) return;
      
      setState(() {
        _nearbyResidences = filteredResidences;
        _isLoading = false;
      });
      
      // Créer les marqueurs pour la carte
      _createMarkers();
      
      // Démarrer les animations si tout est bien chargé
      _animationController.forward();
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Erreur lors de l\'application des filtres: $e';
      });
    }
  }

  // Charge les résidences à proximité de la position utilisateur
  Future<void> _loadNearbyResidences() async {
    if (_userLocation == null) return;

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
      
      debugPrint('📍 Chargement des résidences à proximité de: ${_userLocation!.latitude},${_userLocation!.longitude} | Rayon: $_currentRadius km');
      
      // Réinitialiser les filtres avancés pour garantir qu'ils ne sont pas trop restrictifs
      _searchTerm = null;
      _selectedCity = null;
      _selectedDateRange = null;
      _priceRange = null;
      _selectedCategory = null; // S'assurer qu'aucune catégorie n'est sélectionnée par défaut
      _selectedType = null;
      
      // Charger directement les résidences depuis le service avec un rayon augmenté
      final residences = await _nearbyResidencesService.getNearbyResidences(
        latitude: _userLocation!.latitude,
        longitude: _userLocation!.longitude,
        radius: _currentRadius,
        limit: 50, // Augmenter la limite pour avoir plus de résultats
      );
      
      debugPrint('🏠 ${residences.length} résidences trouvées dans un rayon de $_currentRadius km');
      
      if (!mounted) return;
      
      // Tri des résidences par distance
      residences.sort((a, b) {
        final distanceA = _calculateDistanceToResidence(a);
        final distanceB = _calculateDistanceToResidence(b);
        return distanceA.compareTo(distanceB);
      });
      
      setState(() {
        _nearbyResidences = residences;
        _isLoading = false;
      });
      
      // Créer les marqueurs pour la carte
      _createMarkers();
      
      // Démarrer les animations si tout est bien chargé
      _animationController.forward();
      
    } catch (e) {
      debugPrint('⚠️ Erreur lors du chargement des résidences: $e');
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Erreur lors du chargement des résidences: $e';
      });
    }
  }
  
  // Calcule la distance entre l'utilisateur et une résidence
  double _calculateDistanceToResidence(Residence residence) {
    if (_userLocation == null) return double.maxFinite;
    
    try {
      // Utiliser l'extension pour récupérer les coordonnées (elle gère les deux formats)
      double? lat = residence.latitude;
      double? lng = residence.longitude;
      
      if (lat == null || lng == null) return double.maxFinite;
      
      return _locationService.calculateDistance(
        _userLocation!.latitude,
        _userLocation!.longitude,
        lat,
        lng,
      );
    } catch (e) {
      debugPrint('Erreur de calcul de distance: $e');
      return double.maxFinite;
    }  
  }
  
  /// Crée les marqueurs pour la carte Google Maps - MARQUEURS BLEU FONCÉ UNIFORMES
  Future<void> _createMarkers() async {
    if (_userLocation == null) return;
    
    final Set<Marker> markers = {};
    
    // Ajouter le marqueur pour la position de l'utilisateur
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _userLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
    
    // Ajouter un marqueur pour chaque résidence avec le nouveau système unifié
    for (final residence in _nearbyResidences) {
      // Utiliser l'extension pour récupérer les coordonnées
      final double? lat = residence.latitude;
      final double? lng = residence.longitude;
      
      if (lat != null && lng != null) {
        final BitmapDescriptor markerIcon = await ResidenceMarkerExtension.generateMarkerForResidence(residence);
        
        markers.add(
          Marker(
            markerId: MarkerId('residence_${residence.id}'),
            position: LatLng(lat, lng),
            icon: markerIcon,
            consumeTapEvents: true,
            onTap: () {
              final index = _nearbyResidences.indexWhere((r) => r.id == residence.id);
              setState(() {
                _selectedMarkerResidence = residence;
                if (index != -1) _hoveredIndex = index;
              });
            },
          ),
        );
      }
    }
    
    setState(() {
      _markers = markers;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du widget
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Titre et sous-titre
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 20,
                            color: const Color(0xFF1A1A1A),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.title,
                              style: AppTextStyles.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (widget.subtitle != null) ...[                  
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Bouton de recherche avancée
                IconButton(
                  onPressed: _showAdvancedSearch,
                  icon: const Icon(Icons.tune),
                  tooltip: 'Recherche avancée',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Contrôles de filtrage (ajustement de distance et catégories)
          // Affichés uniquement si nous avons des données à filtrer
          if (!_isLoading && !_isPermissionDenied && !_hasError && _nearbyResidences.isNotEmpty)
            _buildFilterControls(),
          
          const SizedBox(height: 10),
          
          // Contenu principal
          if (_isLoading) 
            _buildLoading()
          else if (_isPermissionDenied)
            _buildNoPermission()
          else if (_hasError)
            _buildError()
          else if (_nearbyResidences.isEmpty)
            _buildNoLocationsFound()
          else
            _buildContent(),
        ],
      ),
    );
  }
  
  /// Widget affichant un indicateur de chargement
  Widget _buildLoading() {
    return Container(
      height: 250,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Recherche des résidences à proximité...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Widget pour informer l'utilisateur que la permission de localisation est nécessaire
  Widget _buildNoPermission() {
    return Container(
      height: 250,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Accès à la localisation refusé',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Pour découvrir les résidences à proximité, veuillez activer la localisation dans les paramètres de votre appareil.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initialize,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
  
  /// Widget pour afficher un message d'erreur
  Widget _buildError() {
    return Container(
      height: 250,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'Une erreur est survenue',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initialize,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
  
  /// Widget affichant un message quand aucune résidence n'est trouvée
  Widget _buildNoLocationsFound() {
    return Container(
      height: 250,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune résidence trouvée à proximité',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez d\'élargir votre rayon de recherche ou d\'explorer d\'autres quartiers.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (mounted) {
                // Vérifier si nous avons une position utilisateur
                if (_userLocation != null) {
                  // Naviguer vers l'écran de carte complète
                  context.push('/full-map', extra: {
                    'centerLat': _userLocation!.latitude,
                    'centerLng': _userLocation!.longitude,
                    'radius': _currentRadius * 2, // Double le rayon pour la carte
                  });
                } else {
                  // Si pas de position utilisateur, essayer de réinitialiser avec un rayon plus large
                  setState(() {
                    // Double le rayon ou ajoute 5km, en prenant le maximum des deux
                    _currentRadius = max(_currentRadius * 2, _currentRadius + 5);
                    // Limiter à 20km maximum pour éviter de charger trop de données
                    if (_currentRadius > 20) _currentRadius = 20;
                  });
                  _initialize();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Élargir le rayon'),
          ),
        ],
      ),
    );
  }
  
  /// Widget construit le contenu principal (carte et liste des emplacements)
  // Construit les contrôles de filtrage (distance et catégories)
  Widget _buildFilterControls() {
    // Définition des catégories principales
    final List<Map<String, dynamic>> categories = [
      {'id': 'all', 'name': 'Tous les types'},
      {'id': 'residence_meublee', 'name': 'Résidences meublées'},
      {'id': 'hotel', 'name': 'Hôtels'},
      {'id': 'insolite', 'name': 'Hébergements insolites'},
      {'id': 'colocation', 'name': 'Colocations'},
      {'id': 'longue_duree', 'name': 'Résidences longue durée'},
      {'id': 'economique', 'name': 'Hébergements économiques'},
    ];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slider pour ajuster la distance
          Row(
            children: [
              const Icon(Icons.my_location, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rayon de recherche: ${_searchRadius.toStringAsFixed(1)} km',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Slider(
                      value: _searchRadius,
                      min: 0.5, // 500 mètres
                      max: 10.0, // 10 kilomètres
                      divisions: 19, // 19 étapes
                      label: '${_searchRadius.toStringAsFixed(1)} km',
                      onChanged: (value) {
                        setState(() {
                          _searchRadius = value;
                        });
                      },
                      onChangeEnd: (value) {
                        _applyFilters();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Catégories horizontales
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategory == category['id'] || 
                                 (_selectedCategory == null && category['id'] == 'all');
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category['name']),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? 
                          (category['id'] == 'all' ? null : category['id']) : null;
                        _selectedType = null; // Réinitialiser le type lorsqu'on change de catégorie
                      });
                      _applyFilters();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  // Méthode pour appliquer les filtres après changement
  Future<void> _applyFilters() async {
    if (_userLocation == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _loadNearbyResidences();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Erreur lors de l\'application des filtres: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Carte (si activée)
        if (widget.showMap && _userLocation != null)
          _buildMap(),
        
        const SizedBox(height: 16),
        
        // Liste des résidences — pas de second titre "À proximité", uniquement la liste
        _buildLocationsList(),
      ],
    );
  }
  
  Widget _buildMap() {
    return Container(
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_userLocation?.latitude ?? 0.0, _userLocation?.longitude ?? 0.0),
              zoom: 14.0,
            ),
            markers: _markers,
            onMapCreated: (controller) {
              if (!_mapControllerCompleter.isCompleted) {
                _mapControllerCompleter.complete(controller);
              }
            },
            onTap: (_) => setState(() => _selectedMarkerResidence = null),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          // Carte flottante au tap d'un marqueur
          if (_selectedMarkerResidence != null)
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: _buildMapOverlayCard(_selectedMarkerResidence!),
            ),
        ],
      ),
    )
    .animate(controller: _animationController)
    .fadeIn(duration: 300.ms, curve: Curves.easeOutQuad)
    .moveY(begin: 20, end: 0, duration: 400.ms, curve: Curves.easeOutQuad);
  }

  /// Carte compacte affichée en superposition sur la mini-carte au tap d'un marqueur
  Widget _buildMapOverlayCard(Residence residence) {
    return GestureDetector(
      onTap: () => context.pushNamed('residence_details', pathParameters: {'id': residence.id}),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Row(
          children: [
            // Miniature image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: SizedBox(
                width: 80,
                height: 72,
                child: residence.photos != null && residence.photos!.isNotEmpty
                    ? Image.network(residence.photos!.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: Colors.grey[200], child: const Icon(Icons.home, color: Colors.grey)))
                    : Container(color: Colors.grey[200], child: const Icon(Icons.home, color: Colors.grey)),
              ),
            ),
            // Infos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      residence.title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      residence.type.displayName,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      residence.formattedPrice,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFD4AF37)),
                    ),
                  ],
                ),
              ),
            ),
            // Bouton fermer
            GestureDetector(
              onTap: () => setState(() => _selectedMarkerResidence = null),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.close, size: 16, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Liste horizontale des résidences. Un seul titre "À proximité" en haut du widget (build), pas ici.
  Widget _buildLocationsList() {
    return Container(
      height: 320,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 280,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _nearbyResidences.length,
              itemBuilder: (context, index) {
                final residence = _nearbyResidences[index];
                final isHovered = _hoveredIndex == index;
                // Calcul correct de la distance entre l'utilisateur et la résidence
                double? distance;
                try {
                  if (_userLocation != null) {
                    // Vérification que les coordonnées sont disponibles
                    if (residence.latitude != null && residence.longitude != null) {
                      distance = _locationService.calculateDistance(
                        _userLocation!.latitude,
                        _userLocation!.longitude,
                        residence.latitude!,
                        residence.longitude!,
                      );
                      // Vérifier si la distance est raisonnable (moins de 100 km)
                      if (distance > 100) {
                        print('Distance suspecte: $distance km pour ${residence.name}');
                        distance = null;
                      }
                    }
                  }
                } catch (e) {
                  print('Erreur dans le calcul de distance: $e');
                  distance = null;
                }
                return _buildLocationCard(residence, distance, index, isHovered);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLocationCard(
    Residence residence,
    double? distance,
    int index,
    bool isHovered,
  ) {
    return MouseRegion(
      onEnter: (_) {
        if (mounted) {
          setState(() => _hoveredIndex = index);
        }
      },
      onExit: (_) {
        if (mounted) {
          setState(() => _hoveredIndex = -1);
        }
      },
      child: GestureDetector(
        onTap: () {
          // Navigation directe vers la page de détail de la résidence
          try {
            // L'ID ne peut pas être null donc on supprime la vérification
            final id = residence.id;
            final routeName = 'residence_details'; // Utiliser le nom de la route plutôt que le chemin
            
            print('Début navigation vers résidence détails - ID: $id, Nom de route: $routeName');
            
            // Essayer d'utiliser le nom de la route plutôt que le chemin
            context.pushNamed(routeName, pathParameters: {'id': id});
            
            print('Navigation réussie vers résidence détails');
          } catch (e) {
            print('Erreur de navigation: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur de navigation: $e')),
            );
          }
        },
        child: Container(
          width: 220,
          height: 380, // Augmenté pour accommoder les adresses particulièrement longues et éviter l'overflow sur toutes les résidences
          margin: const EdgeInsets.only(right: 16, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isHovered ? 0.15 : 0.08),
                blurRadius: isHovered ? 12 : 8,
                offset: Offset(0, isHovered ? 6 : 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Empêche la colonne d'exiger plus d'espace que nécessaire
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Container(
                  height: 140,  // Augmenter la hauteur pour les images
                  width: double.infinity,
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  child: Stack(
                    children: [
                      residence.photos != null && residence.photos!.isNotEmpty
                      ? Image.network(
                          residence.photos!.first,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            print('Erreur de chargement image: ${residence.photos?.first}');
                            // Utiliser une image de secours en cas d'erreur
                            return Image.asset(
                              index % 2 == 0
                                ? 'assets/images/residences/promo${(index % 2) + 1}.png'
                                : 'assets/images/residences/premium${(index % 2) + 1}.png',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.location_city,
                                    size: 48,
                                    color: AppTheme.primaryColor.withOpacity(0.5),
                                  ),
                                );
                              },
                            );
                          },
                        )
                      : Image.asset(
                          index % 2 == 0
                            ? 'assets/images/residences/promo${(index % 2) + 1}.png'
                            : 'assets/images/residences/premium${(index % 2) + 1}.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.location_city,
                                size: 48,
                                color: AppTheme.primaryColor.withOpacity(0.5),
                              ),
                            );
                          },
                        ),

                      if (distance != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.near_me,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  distance < 1
                                      ? '${(distance * 1000).toStringAsFixed(0)} m'
                                      : '${distance.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, top: 6, bottom: 4), // Padding réduit encore plus
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Empêche le flex de prendre trop d'espace
                  children: [
                    // Titre de la résidence
                    Text(
                      residence.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Prix avec mise en avant
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        residence.formattedPrice,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    
                    // Caractéristiques basiques
                    Row(
                      children: [
                        Icon(Icons.king_bed_outlined, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('${residence.bedrooms}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(width: 10),
                        Icon(Icons.bathtub_outlined, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('${residence.bathrooms}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(width: 10),
                        Icon(Icons.square_foot, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('${residence.squareMeters.toStringAsFixed(0)}m²', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // Adresse avec contrainte de hauteur
                    // Limiter l'adresse à une seule ligne avec ellipsis pour les adresses longues
                    Text(
                      residence.location['displayAddress'] ?? residence.location['address'] ?? 'Adresse non disponible',
                      style: TextStyle(
                        fontSize: 11, // Police plus petite pour les adresses longues
                        height: 1.1, // Interligne très réduit
                        color: Colors.grey[600],
                      ),
                      maxLines: 1, // Limite à une seule ligne pour éviter les débordements
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // Bouton Explorer avec contraintes réduites
                    SizedBox(
                      width: double.infinity,
                      height: 30, // Hauteur réduite pour le bouton
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigation directe vers la page de détail de la résidence
                          try {
                            // L'ID ne peut pas être null donc on supprime la vérification
                            final id = residence.id;
                            final routeName = 'residence_details'; // Utiliser le nom de la route plutôt que le chemin
                            
                            print('Bouton Explorer: Début navigation vers résidence détails - ID: $id, Nom de route: $routeName');
                            
                            // Utiliser le nom de la route plutôt que le chemin
                            context.pushNamed(routeName, pathParameters: {'id': id});
                            
                            print('Bouton Explorer: Navigation réussie vers résidence détails');
                          } catch (e) {
                            print('Bouton Explorer: Erreur de navigation: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur de navigation: $e')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: Size.zero, // Permettre des tailles plus petites
                          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Explorer', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate(target: isHovered ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.03, 1.03),
          duration: 200.ms,
          curve: Curves.easeOutQuad,
        ),
      )
      .animate(delay: 100.ms * index)
      .fadeIn(duration: 500.ms, curve: Curves.easeOutQuad)
      .moveX(begin: 20, end: 0, duration: 500.ms, curve: Curves.easeOutQuad),
    );
  }
}
