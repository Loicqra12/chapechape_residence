import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart'; // Importer Intl pour utiliser NumberFormat

import '../../core/models/listing_model.dart';
import '../../core/models/residence_model.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/string_utils.dart';
import '../../core/constants/app_assets.dart';
import '../../core/config/app_config_manager.dart'; // Import AppConfigManager
import '../../core/services/logger_service.dart'; // Import LoggerService
import 'common/premium_card.dart';

/// Widget pour afficher les annonces et résidences en vedette
/// 
/// Ce widget est compatible avec les types Listing et Residence
/// et utilise les extensions de modèle pour accéder aux propriétés
/// de manière cohérente
class FeaturedListings extends StatefulWidget {
  /// Liste d'éléments à afficher, peut contenir des objets Listing ou Residence
  final List<dynamic> listings;
  final bool isLoading;
  final VoidCallback? onSeeAllPressed;
  final EdgeInsets padding;
  final String title;
  final String subtitle;
  final String emptyStateMessage;
  final bool enableAnimation;
  final String routePath;

  const FeaturedListings({
    Key? key,
    this.listings = const [],
    this.isLoading = false,
    this.onSeeAllPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.title = 'Annonces en vedette',
    this.subtitle = 'Découvrez nos meilleures propriétés sélectionnées pour vous',
    this.emptyStateMessage = 'Aucune annonce en vedette disponible',
    this.enableAnimation = true,
    this.routePath = '/listings',
  }) : super(key: key);

  @override
  State<FeaturedListings> createState() => _FeaturedListingsState();
}

class _FeaturedListingsState extends State<FeaturedListings> {
  final ScrollController _scrollController = ScrollController();
  final LoggerService _logger = LoggerService(); // Initialiser le logger
  int _hoveredIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.debug('FeaturedListings.build - isLoading: ${widget.isLoading}, listings.length: ${widget.listings.length}');
    if (widget.listings.isNotEmpty) {
      _logger.debug('Premier élément: ${widget.listings.first.runtimeType}');
      if (widget.listings.first is Map) {
        _logger.debug('Contenu du premier élément (Map): ${widget.listings.first}');
      }
    } else {
      _logger.debug('Aucun élément à afficher');
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            _buildSubtitle(context),
            const SizedBox(height: 8), 
            Expanded(
              child: widget.isLoading
                  ? _buildLoadingSkeleton()
                  : _buildListingsList(context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                fontSize: context.responsiveFontSize(22),
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextButton(
              onPressed: widget.onSeeAllPressed ?? () {
                context.push(widget.routePath);
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Voir tout'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: widget.padding.left,
        right: widget.padding.right,
      ),
      child: Text(
        widget.subtitle,
        style: TextStyle(
          fontSize: context.responsiveFontSize(14),
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildListingsList(BuildContext context) {
    if (widget.listings.isEmpty) {
      _logger.debug('_buildListingsList - Aucune résidence trouvée');
      return _buildEmptyState(context);
    }

    _logger.debug('_buildListingsList - ${widget.listings.length} résidences trouvées');
    return SizedBox(
      height: 330, // Augmenter la hauteur du conteneur de liste
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: widget.listings.length,
            itemBuilder: (context, index) {
              final item = widget.listings[index];
              bool isHovered = _hoveredIndex == index;
              
              Widget card = _buildListingCard(context, item, index, isHovered);
              
              // Animation simple et contrôlée pour éviter les conflits de layout
              if (widget.enableAnimation && index < 5) {
                card = card.animate().fadeIn(
                  duration: const Duration(milliseconds: 300),
                  delay: Duration(milliseconds: index * 100),
                );
              }
              
              return MouseRegion(
                onEnter: (_) {
                  setState(() {
                    _hoveredIndex = index;
                  });
                },
                onExit: (_) {
                  setState(() {
                    _hoveredIndex = -1;
                  });
                },
                child: card,
              );
            },
          ),
          // Overlay avec gradient transparent pour indiquer du contenu supplémentaire
          Positioned.fill(
            child: IgnorePointer(
              child: _buildFadeEdges(),
            ),
          ),
          // Boutons de navigation
          if (widget.listings.length > 2)
            _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildFadeEdges() {
    return Row(
      children: [
        Container(
          width: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                Colors.white.withOpacity(0),
                Colors.white.withOpacity(0.8),
              ],
            ),
          ),
        ),
        const Spacer(),
        Container(
          width: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withOpacity(0),
                Colors.white.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Positioned.fill(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: _buildNavigationButton(
              icon: Icons.arrow_back_ios,
              onTap: () {
                _scrollController.animateTo(
                  _scrollController.offset - 250,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutQuad,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _buildNavigationButton(
              icon: Icons.arrow_forward_ios,
              onTap: () {
                _scrollController.animateTo(
                  _scrollController.offset + 250,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutQuad,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.8),
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 16),
        ),
      ),
    );
  }

  Widget _buildListingCard(BuildContext context, dynamic item, int index, bool isHovered) {
    // Récupérer les propriétés de manière compatible avec Listing et Residence
    final String title = _getItemTitle(item);
    final String? location = _getItemLocation(item);
    final double? price = _getItemPrice(item);
    final int? bedrooms = _getItemBedrooms(item);
    final int? bathrooms = _getItemBathrooms(item);
    final double? area = _getItemArea(item);
    final bool isPromoted = _isItemPromoted(item);
    final String? status = _getItemStatus(item);
    final String detailRoute = _getDetailRoute(item);
    
    return GestureDetector(
      onTap: () {
        context.push(detailRoute);
      },
      child: Container(
        width: 280,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      child: PremiumCard(
        borderRadius: 20,
        elevation: isHovered ? 8 : 4,
        backgroundColor: Colors.white,
        border: isHovered 
            ? Border.all(color: AppTheme.primaryColor.withOpacity(0.5), width: 1.5)
            : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
          constraints: BoxConstraints(maxHeight: 350), // Contrainte de hauteur maximale
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(), // Empêche le défilement tout en permettant le contenu de déborder
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image - hauteur fixe
                          Stack(
                            children: [
                              SizedBox(
                                height: 160,
                                width: double.infinity,
                                child: _buildImage(item),
                              ),
                              if (isPromoted)
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: _buildPromotedBadge(),
                                ),
                              _buildStatusBadge(status),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                left: 12,
                                child: _buildPriceBadge(price),
                              ),
                            ],
                          ),
                          
                          // Contenu
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        location ?? 'Emplacement non spécifié',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildFeatureItem(
                                      icon: Icons.hotel_outlined,
                                      value: bedrooms != null
                                          ? '$bedrooms'
                                          : '-',
                                      label: 'Chambres',
                                    ),
                                    _buildFeatureItem(
                                      icon: Icons.bathtub_outlined,
                                      value: bathrooms != null
                                          ? '$bathrooms'
                                          : '-',
                                      label: 'SdB',
                                    ),
                                    _buildFeatureItem(
                                      icon: Icons.square_foot_outlined,
                                      value: area != null
                                          ? '${area.toInt()}'
                                          : '-',
                                      label: 'm²',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        ),
      ),
    );
  }

  // Méthodes d'adaptation pour récupérer les propriétés des différents types d'éléments
  String _getItemTitle(dynamic item) {
    if (item is Listing) return item.title;
    if (item is Residence) return item.title;
    return 'Titre non disponible';
  }

  String? _getItemLocation(dynamic item) {
    if (item is Listing) return item.location;
    if (item is Residence) {
      if (item.location.containsKey('city')) {
        return item.location['city'];
      } else if (item.location.containsKey('formattedAddress')) {
        return item.location['formattedAddress'];
      }
    }
    return null;
  }

  double? _getItemPrice(dynamic item) {
    if (item is Listing) return item.price;
    if (item is Residence) return item.price;
    return null;
  }

  int? _getItemBedrooms(dynamic item) {
    if (item is Listing) return item.bedrooms;
    if (item is Residence) return item.bedrooms;
    return null;
  }

  int? _getItemBathrooms(dynamic item) {
    if (item is Listing) return item.bathrooms;
    if (item is Residence) return item.bathrooms;
    return null;
  }

  double? _getItemArea(dynamic item) {
    if (item is Listing) return item.area;
    if (item is Residence) return item.squareMeters;
    return null;
  }

  bool _isItemPromoted(dynamic item) {
    if (item is Listing) return item.isPromoted;
    if (item is Residence) return item.isFeatured || item.isVip;
    return false;
  }

  String? _getItemStatus(dynamic item) {
    if (item is Listing) return item.status;
    if (item is Residence) return item.isAvailable ? 'available' : 'unavailable';
    return null;
  }

  String _getDetailRoute(dynamic item) {
    if (item is Listing) return '${widget.routePath}/${item.id}';
    if (item is Residence) return '/residence/${item.id}';
    return widget.routePath;
  }

  Widget _buildStatusBadge(String? status) {
    final String statusLower = status?.toLowerCase() ?? 'available';
    
    Color badgeColor = Colors.green;
    String statusText = 'Disponible';
    
    if (statusLower == 'pending' || statusLower == 'en attente') {
      badgeColor = Colors.orange;
      statusText = 'En attente';
    } else if (statusLower == 'unavailable' || statusLower == 'indisponible' || statusLower == 'sold' || statusLower == 'vendu') {
      badgeColor = Colors.red;
      statusText = 'Indisponible';
    }
    
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          statusText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPromotedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.star,
            color: Colors.white,
            size: 12,
          ),
          SizedBox(width: 4),
          Text(
            'Premium',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBadge(double? price) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        _formatPrice(price ?? 0), // Utiliser 0 par défaut si price est null
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return SizedBox(
      width: 78, // Réduire légèrement la largeur
      child: Column(
        children: [
          Icon(
            icon,
            size: 18, // Réduire légèrement la taille de l'icône
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 4), // Réduire l'espace
          Text(
            value,
            style: const TextStyle(
              fontSize: 13, // Réduire légèrement la taille de la police
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2), // Réduire l'espace
          Text(
            label,
            style: TextStyle(
              fontSize: 11, // Réduire légèrement la taille de la police
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(dynamic item) {
    String? imageUrl;
    
    if (item is Listing) {
      imageUrl = item.images != null && item.images!.isNotEmpty ? item.images!.first : null;
    } else if (item is Residence) {
      imageUrl = item.images.isNotEmpty ? item.images.first : null;
    }

    if (imageUrl == null) {
      return Image.asset(
        AppAssets.placeholderImage,
        fit: BoxFit.cover,
      );
    }
    
    // Vérifier si c'est un asset local
    if (_isLocalAsset(imageUrl)) {
      _logger.debug('Chargement d\'asset local: $imageUrl');
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          _logger.error('Erreur de chargement d\'asset local: $error');
          return Image.asset(
            AppAssets.placeholderImage,
            fit: BoxFit.cover,
          );
        },
      );
    }
    
    // Si c'est une URL réseau, utiliser CachedNetworkImage
    // Récupérer le token d'authentification pour les images
    return FutureBuilder<String?>(
      future: const FlutterSecureStorage().read(key: 'token'),
      builder: (context, snapshot) {
        // Afficher un placeholder pendant le chargement du token
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildImagePlaceholder();
        }
        
        final token = snapshot.data;
        
        // S'assurer que imageUrl n'est jamais null ici
        final nonNullImageUrl = imageUrl ?? AppAssets.placeholderImage;
        
        return CachedNetworkImage(
          imageUrl: nonNullImageUrl,
          fit: BoxFit.cover,
          // Ajouter le token d'authentification aux headers si disponible
          httpHeaders: token != null ? {'Authorization': 'Bearer $token'} : null,
          placeholder: (context, url) => _buildImagePlaceholder(),
          errorWidget: (context, url, error) => _buildImageErrorWithFallback(url),
        );
      }
    );
  }

  Widget _buildImagePlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        color: Colors.white,
      ),
    );
  }

  // Amélioration de l'affichage des erreurs avec une tentative de chargement sans token
  // Vérifier si l'URL est un asset local
  bool _isLocalAsset(String url) {
    return url.startsWith('assets/') || 
           url.startsWith('asset/') || 
           url.startsWith('./assets/') || 
           url.startsWith('/assets/');
  }

  Widget _buildImageErrorWithFallback(String? url) {
    // Si l'URL est null, afficher le widget d'erreur par défaut
    if (url == null) {
      _logger.warning('URL d\'image nulle');
      return _buildDefaultErrorWidget();
    }
    
    // Si c'est un asset local, utiliser Image.asset
    if (_isLocalAsset(url)) {
      _logger.debug('URL d\'asset local détectée dans errorWidget: $url');
      return Image.asset(
        AppAssets.placeholderImage,
        fit: BoxFit.cover,
      );
    }
    
    _logger.debug('Traitement de l\'URL d\'image: $url');
    
    // Pour les URLs externes ou déjà complètes, essayer de les charger directement
    if (url.startsWith('http')) {
      _logger.debug('URL externe ou complète détectée: $url');
      
      // Déterminer si c'est une URL avec ou sans le sous-dossier 'residences'
      String alternativeUrl = '';
      if (url.contains('/uploads/residences/')) {
        // Si l'URL contient déjà /uploads/residences/, créer une alternative sans ce sous-dossier
        alternativeUrl = url.replaceFirst('/uploads/residences/', '/uploads/');
      } else if (url.contains('/uploads/') && !url.contains('/uploads/residences/')) {
        // Si l'URL contient /uploads/ mais pas /residences/, créer une alternative avec ce sous-dossier
        alternativeUrl = url.replaceFirst('/uploads/', '/uploads/residences/');
      }
      
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildImagePlaceholder(),
        errorWidget: (context, url, error) {
          _logger.warning('Erreur de chargement d\'URL externe: $error ($url)');
          
          // Si une URL alternative est disponible, l'essayer
          if (alternativeUrl.isNotEmpty) {
            _logger.debug('Tentative avec URL alternative: $alternativeUrl');
            return CachedNetworkImage(
              imageUrl: alternativeUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildImagePlaceholder(),
              errorWidget: (context, url, error) {
                _logger.error('Erreur aussi avec l\'URL alternative: $error');
                return _buildDefaultErrorWidget();
              },
            );
          }
          
          return _buildDefaultErrorWidget();
        },
      );
    }
    
    // Pour les chemins relatifs avec /uploads/ (non complets)
    if (url.startsWith('/uploads/')) {
      // Utiliser AppConfigManager pour construire l'URL
      final String fullUrl = AppConfigManager.getResidenceImageUrl(url);
      
      _logger.debug('URL relative convertie en URL complète: $fullUrl');
      
      return CachedNetworkImage(
        imageUrl: fullUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildImagePlaceholder(),
        errorWidget: (context, url, error) {
          _logger.warning('Erreur de chargement après conversion: $error ($fullUrl)');
          
          // Tenter avec le chemin alternatif (ajouter ou supprimer /residences/)
          String alternativeUrl = '';
          if (url.contains('/uploads/residences/')) {
            alternativeUrl = AppConfigManager.getResidenceImageUrl(url.replaceFirst('/uploads/residences/', '/uploads/'));
          } else {
            alternativeUrl = AppConfigManager.getResidenceImageUrl(url.replaceFirst('/uploads/', '/uploads/residences/'));
          }
          
          _logger.debug('Tentative avec le chemin alternatif: $alternativeUrl');
          
          return CachedNetworkImage(
            imageUrl: alternativeUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildImagePlaceholder(),
            errorWidget: (context, url, error) {
              _logger.error('Erreur également avec le chemin alternatif: $error');
              return _buildDefaultErrorWidget();
            },
          );
        },
      );
    }
    
    // Fallback pour les autres cas
    _logger.warning('Format d\'URL non reconnu, utilisation de l\'image par défaut');
    return Image.asset(
      AppAssets.placeholderImage,
      fit: BoxFit.cover,
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              widget.emptyStateMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SizedBox(
      height: 300,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 160,
                      color: Colors.white,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 150,
                            height: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 100,
                            height: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              3,
                              (i) => Container(
                                width: 60,
                                height: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatPrice(double price) {
    // Utiliser NumberFormat pour un affichage complet et cohérent
    return NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    ).format(price);
  }

  String _getCategoryName(String? categoryId) {
    if (categoryId == null) {
      return 'Non catégorisé';
    }

    final Map<String, String> categories = {
      'apartment': 'Appartement',
      'house': 'Maison',
      'villa': 'Villa',
      'studio': 'Studio',
      'room': 'Chambre',
      'hotel': 'Hôtel',
      'hotelRoom': 'Chambre d\'hôtel',
      'vacation': 'Résidence de vacances',
      'eco': 'Éco-lodge',
      'beach': 'Maison de plage',
      'student': 'Logement étudiant',
      'luxury': 'Luxe',
      'commercial': 'Commercial',
      'office': 'Bureau',
      'land': 'Terrain',
      'other': 'Autre',
    };

    return categories[categoryId] ?? 'Autre';
  }
}
