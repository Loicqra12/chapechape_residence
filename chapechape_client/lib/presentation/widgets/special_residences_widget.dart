import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart'; // Importer la bibliothèque intl pour utiliser NumberFormat

import '../../core/models/residence_model.dart';
import '../../core/models/listing_model.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/utils/residence_adapters.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_assets.dart';

class SpecialResidencesWidget extends StatefulWidget {
  final List<dynamic> items;
  final bool isLoading;
  final VoidCallback? onSeeAllPressed;
  final EdgeInsets padding;
  final String title;
  final String subtitle;
  final String emptyStateMessage;
  final dynamic filterType;
  final bool enableAnimation;

  const SpecialResidencesWidget({
    Key? key,
    this.items = const [],
    this.isLoading = false,
    this.onSeeAllPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.title = 'Résidences spéciales',
    this.subtitle = 'Découvrez nos propriétés exceptionnelles',
    this.emptyStateMessage = 'Aucune résidence spéciale disponible',
    this.filterType,
    this.enableAnimation = true,
  }) : super(key: key);

  @override
  State<SpecialResidencesWidget> createState() => _SpecialResidencesWidgetState();
}

class _SpecialResidencesWidgetState extends State<SpecialResidencesWidget> {
  final ScrollController _scrollController = ScrollController();
  int _hoveredIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                : _buildItemsList(context),
            ),
          ],
        );
      }
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
                context.push('/residences');
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

  Widget _buildItemsList(BuildContext context) {
    if (widget.items.isEmpty) {
      return _buildEmptyState(context);
    }

    return SizedBox(
      height: 350,
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              bool isHovered = _hoveredIndex == index;
              
              Widget card = _buildItemCard(context, item, index, isHovered);
              
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
          if (widget.items.length > 2)
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

  Widget _buildItemCard(BuildContext context, dynamic item, int index, bool isHovered) {
    // Récupérer les propriétés de manière compatible avec Listing et Residence
    final String title = _getItemTitle(item);
    final String? location = _getItemLocation(item);
    final double? price = _getItemPrice(item);
    final int? bedrooms = _getItemBedrooms(item);
    final int? bathrooms = _getItemBathrooms(item);
    final bool isSpecial = _isItemSpecial(item);
    final String detailRoute = _getDetailRoute(item);
    
    return GestureDetector(
      onTap: () {
        context.push(detailRoute);
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        child: Card(
          elevation: isHovered ? 6 : 3,
          shadowColor: isHovered 
              ? AppTheme.primaryColor.withOpacity(0.4) 
              : Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isHovered 
                ? BorderSide(color: AppTheme.primaryColor.withOpacity(0.5), width: 1.5)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Stack(
                children: [
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: _buildImage(item),
                  ),
                  if (isSpecial)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _buildSpecialBadge(),
                    ),
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
                        _buildFeatureChip(
                          icon: Icons.hotel_outlined,
                          text: bedrooms != null ? '$bedrooms Ch.' : '-',
                        ),
                        _buildFeatureChip(
                          icon: Icons.bathtub_outlined,
                          text: bathrooms != null ? '$bathrooms SdB' : '-',
                        ),
                        _buildFeatureChip(
                          icon: bedrooms != null && bedrooms > 3
                              ? Icons.villa_outlined
                              : Icons.apartment_outlined,
                          text: _getCategoryName(item),
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
  }

  Widget _buildFeatureChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.purple,
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
            'Spécial',
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
        _formatPrice(price),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
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

    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildImagePlaceholder(),
        errorWidget: (context, url, error) => _buildImageError(),
      );
    } else {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImageError(),
      );
    }
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

  Widget _buildImageError() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.home_outlined,
          color: Colors.grey[400],
          size: 32,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.villa_outlined,
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
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.onSeeAllPressed ?? () {
                context.push('/residences');
              },
              icon: const Icon(Icons.search, size: 16),
              label: const Text('Explorer toutes les résidences'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 600));
  }

  Widget _buildLoadingSkeleton() {
    return SizedBox(
      height: 350,
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
                    // Image placeholder
                    Container(
                      height: 180,
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

  // Méthodes d'adaptation pour récupérer les propriétés des différents types d'éléments
  String _getItemTitle(dynamic item) {
    if (item is Listing) return item.title;
    if (item is Residence) return item.title;
    return 'Résidence';
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

  bool _isItemSpecial(dynamic item) {
    if (item is Listing) return item.isPromoted;
    if (item is Residence) {
      return item.isSpecialResidence || item.isVip;
    }
    return false;
  }

  String _getDetailRoute(dynamic item) {
    if (item is Listing) return '/listings/${item.id}';
    if (item is Residence) return '/residences/${item.id}';
    return '/residences';
  }

  String _getCategoryName(dynamic item) {
    if (item is Listing) {
      return item.category ?? 'Autre';
    }
    if (item is Residence) {
      if (item.type is String) {
        switch (item.type.toString().toLowerCase()) {
          case 'apartment':
          case 'appartement':
            return 'Appart.';
          case 'house':
          case 'maison':
            return 'Maison';
          case 'villa':
            return 'Villa';
          case 'studio':
            return 'Studio';
          case 'luxury':
          case 'luxe':
            return 'Luxe';
          default:
            return 'Autre';
        }
      } else {
        // Si c'est un enum ResidenceType
        return ResidenceAdapters.getTypeDisplayName(item.type);
      }
    }
    return 'Autre';
  }

  String _formatPrice(double? price) {
    if (price == null) {
      return 'Sur demande';
    } else {
      return NumberFormat.currency(
        locale: 'fr_FR',
        symbol: 'FCFA',
        decimalDigits: 0,
      ).format(price);
    }
  }
}
