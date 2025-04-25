import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/location_service.dart';
import '../../core/models/location_suggestion_model.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/services/map_provider/map_service_interface.dart';
import '../../core/services/map_provider/osm_map_service.dart';

/// Widget qui affiche les résidences à proximité de l'utilisateur
class AroundMeWidget extends StatefulWidget {
  /// Titre du widget
  final String title;
  
  /// Sous-titre explicatif
  final String? subtitle;
  
  /// Nombre d'éléments à afficher
  final int itemCount;
  
  /// Rayon de recherche en kilomètres
  final double radiusKm;
  
  /// Si true, affiche une carte en plus de la liste
  final bool showMap;
  
  const AroundMeWidget({
    Key? key,
    this.title = 'Autour de moi',
    this.subtitle = 'Découvrez des résidences proches de votre position',
    this.itemCount = 5,
    this.radiusKm = 5.0,
    this.showMap = true,
  }) : super(key: key);

  @override
  State<AroundMeWidget> createState() => _AroundMeWidgetState();
}

class _AroundMeWidgetState extends State<AroundMeWidget> with SingleTickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  final MapServiceInterface _mapService = OSMMapService();
  
  dynamic _userLocation;
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  int _hoveredIndex = -1;
  List<LocationSuggestionModel> _nearbyLocations = [];
  late AnimationController _animationController;
  
  // Marqueurs pour la carte
  final Map<String, dynamic> _markers = {'markers': []};
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _initialize();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Demander l'autorisation de localisation
      _hasLocationPermission = await _locationService.requestLocationPermission();
      
      if (_hasLocationPermission) {
        // Obtenir la position de l'utilisateur
        _userLocation = await _locationService.getCurrentUserLocation();
        
        if (_userLocation != null) {
          // Rechercher les emplacements à proximité
          _nearbyLocations = await _locationService.getNearbyLocations(
            _userLocation,
            radiusKm: widget.radiusKm,
          );
          
          // Limiter le nombre d'éléments affichés
          if (_nearbyLocations.length > widget.itemCount) {
            _nearbyLocations = _nearbyLocations.sublist(0, widget.itemCount);
          }
          
          // Créer les marqueurs pour la carte
          _createMarkers();
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation de AroundMeWidget: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Démarrer les animations
        _animationController.forward();
      }
    }
  }
  
  // Créer les marqueurs pour la carte
  void _createMarkers() {
    List<dynamic> markersList = [];
    
    // Marqueur pour la position de l'utilisateur
    if (_userLocation != null) {
      final userMarker = _mapService.createMarker(
        id: 'user_location',
        latitude: _userLocation.latitude,
        longitude: _userLocation.longitude,
        title: 'Votre position',
      );
      
      if (userMarker != null) {
        markersList.add(userMarker);
      }
    }
    
    // Marqueurs pour les emplacements à proximité
    for (int i = 0; i < _nearbyLocations.length; i++) {
      final location = _nearbyLocations[i];
      
      final marker = _mapService.createMarker(
        id: 'location_$i',
        latitude: location.latitude ?? 0.0,
        longitude: location.longitude ?? 0.0,
        title: location.name,
        snippet: location.fullAddress,
        onTap: () {
          // Mettre en surbrillance l'élément correspondant dans la liste
          setState(() {
            _hoveredIndex = i;
          });
        },
      );
      
      if (marker != null) {
        markersList.add(marker);
      }
    }
    
    setState(() {
      _markers['markers'] = markersList;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        
        // Section principale avec carte et liste
        _isLoading
            ? _buildLoadingIndicator()
            : !_hasLocationPermission
                ? _buildPermissionDenied()
                : _nearbyLocations.isEmpty
                    ? _buildNoLocationsFound()
                    : _buildContent(),
      ],
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              fontSize: context.responsiveFontSize(20),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.subtitle!,
              style: TextStyle(
                fontSize: context.responsiveFontSize(14),
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Container(
      height: 250,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Recherche des résidences à proximité...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPermissionDenied() {
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
              setState(() {
                widget.radiusKm * 2;
                _initialize();
              });
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
  
  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Carte (si activée)
        if (widget.showMap && _userLocation != null)
          _buildMap(),
        
        const SizedBox(height: 16),
        
        // Liste des emplacements à proximité
        _buildLocationsList(),
      ],
    );
  }
  
  Widget _buildMap() {
    return Container(
      height: 180,
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
      child: _mapService.createMapWidget(
        latitude: _userLocation.latitude,
        longitude: _userLocation.longitude,
        zoom: 13.5,
        markers: _markers,
        onMapCreated: (controller) {
          // Nous gardons une référence au contrôleur mais ne l'utilisons pas actuellement
          // Cette référence pourrait être utile pour des fonctionnalités futures comme
          // se déplacer vers un marqueur spécifique
        },
      ),
    )
    .animate(controller: _animationController)
    .fadeIn(duration: 300.ms, curve: Curves.easeOutQuad)
    .moveY(begin: 20, end: 0, duration: 400.ms, curve: Curves.easeOutQuad);
  }
  
  Widget _buildLocationsList() {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _nearbyLocations.length,
        itemBuilder: (context, index) {
          final location = _nearbyLocations[index];
          final isHovered = _hoveredIndex == index;
          
          // Calculer la distance entre l'utilisateur et cet emplacement
          final distance = _userLocation != null
              ? _locationService.calculateDistance(
                  _userLocation.latitude,
                  _userLocation.longitude,
                  location.latitude ?? 0.0,
                  location.longitude ?? 0.0,
                )
              : null;
          
          return _buildLocationCard(location, distance, index, isHovered);
        },
      ),
    );
  }
  
  Widget _buildLocationCard(
    LocationSuggestionModel location,
    double? distance,
    int index,
    bool isHovered,
  ) {
    // Ajustement de la taille pour corriger le débordement
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: GestureDetector(
        onTap: () {
          // Naviguer vers la page des résidences dans ce quartier
          context.push('/residences?location=${Uri.encodeComponent(location.fullAddress)}');
        },
        child: Container(
          width: 220,
          // Réduire davantage la hauteur pour éviter le débordement de 6 pixels
          height: 259,
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
            children: [
              // Image de l'emplacement (simulée pour le moment)
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Container(
                  // Réduire légèrement la hauteur de l'image
                  height: 115,
                  width: double.infinity,
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  child: Stack(
                    children: [
                      // Image simulée basée sur l'index
                      Image.asset(
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
                      
                      // Badge de distance
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
              
              // Contenu textuel
              Padding(
                // Réduire légèrement le padding
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom du quartier
                    Text(
                      location.district?.isNotEmpty == true ? location.district! : location.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 3),
                    
                    // Adresse complète
                    Text(
                      location.fullAddress,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Bouton explorer
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/residences?location=${Uri.encodeComponent(location.fullAddress)}');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          // Réduire légèrement le padding du bouton
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Explorer'),
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
