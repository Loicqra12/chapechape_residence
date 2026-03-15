import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/models/residence_model.dart';
import '../../core/service_locator.dart';
import '../../core/services/residence_service.dart';
import '../../core/utils/string_utils.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_styles.dart';
import '../../core/constants/app_assets.dart';

/// Section « Tendances dans votre ville » : résidences les plus réservées (7 j).
/// Titre hyper-local : quartier > commune > ville.
class TendancesWidget extends StatefulWidget {
  final String? city;
  final String? commune;
  final String? quartier;
  final int limit;
  final EdgeInsets padding;

  const TendancesWidget({
    Key? key,
    this.city,
    this.commune,
    this.quartier,
    this.limit = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  }) : super(key: key);

  @override
  State<TendancesWidget> createState() => _TendancesWidgetState();
}

class _TendancesWidgetState extends State<TendancesWidget> {
  final ScrollController _scrollController = ScrollController();
  int _hoveredIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _buildTitle() {
    if (widget.quartier != null && widget.quartier!.isNotEmpty) {
      return 'Tendance à ${widget.quartier}';
    }
    if (widget.commune != null && widget.commune!.isNotEmpty) {
      return 'Les plus réservées à ${widget.commune} cette semaine';
    }
    final city = widget.city ?? 'Abidjan';
    return 'Les plus demandées à $city';
  }

  @override
  Widget build(BuildContext context) {
    final residenceService = sl<ResidenceService>();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: residenceService.getTrendingResidences(
        city: widget.city ?? 'Abidjan',
        commune: widget.commune,
        quartier: widget.quartier,
        limit: widget.limit,
      ),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final list = snapshot.data ?? [];
        final hasError = snapshot.hasError;

        return LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 4),
                Expanded(
                  child: isLoading
                      ? _buildLoadingSkeleton(context)
                      : hasError || list.isEmpty
                          ? _buildEmptyState(context)
                          : _buildItemsList(context, list),
                ),
              ],
            );
          },
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
            child: Row(
              children: [
                Icon(
                  Icons.trending_up,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _buildTitle(),
                    style: AppTextStyles.title.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/search'),
            icon: Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).colorScheme.onSurface),
            style: IconButton.styleFrom(minimumSize: const Size(40, 40), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
            tooltip: 'Voir tout',
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context, List<Map<String, dynamic>> items) {
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.only(
        left: widget.padding.left,
        right: widget.padding.right,
        top: 4,
        bottom: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final entry = items[index];
        final residence = entry['residence'] as Residence?;
        final bookingCount = entry['bookingCount'] is int
            ? entry['bookingCount'] as int
            : 0;
        if (residence == null) return const SizedBox.shrink();
        final isHovered = _hoveredIndex == index;
        return MouseRegion(
          onEnter: (_) => setState(() => _hoveredIndex = index),
          onExit: (_) => setState(() => _hoveredIndex = -1),
          child: _buildCard(context, residence, bookingCount, isHovered),
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    Residence residence,
    int bookingCount,
    bool isHovered,
  ) {
    final title = residence.title.isEmpty ? 'Résidence' : residence.title;
    final String location = residence.formattedAddress.isNotEmpty
        ? residence.formattedAddress
        : (residence.address.isNotEmpty ? residence.address : (residence.city.isNotEmpty ? residence.city : 'Emplacement non spécifié'));
    final price = residence.price;
    final imageUrl = residence.images.isNotEmpty ? residence.images.first : null;

    // Design uniforme : carte = image seule, texte en dessous (réf. featured_listings)
    return GestureDetector(
      onTap: () => context.push('/residence/${residence.id}'),
      child: Container(
        width: 176,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: _buildImage(imageUrl),
                  ),
                  Positioned(top: 6, right: 6, child: _buildPopulaireBadge()),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 5,
                    left: 8,
                    child: Text(
                      _formatPrice(price),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              StringUtils.toTitleCase(title),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (bookingCount > 0) ...[
              const SizedBox(height: 2),
              Text(
                '$bookingCount réservation${bookingCount > 1 ? 's' : ''} cette semaine',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPopulaireBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.trending_up, color: Colors.white, size: 10),
          SizedBox(width: 3),
          Text(
            'Populaire',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String? imageUrl) {
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
        placeholder: (context, url) => _buildImagePlaceholder(context),
        errorWidget: (context, url, error) => _buildImageError(context),
      );
    }
    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildImageError(context),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: Container(color: Theme.of(context).colorScheme.surface),
    );
  }

  Widget _buildImageError(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Center(
        child: Icon(Icons.home_outlined, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 32),
      ),
    );
  }

  String _formatPrice(double? price) {
    if (price == null) return '—';
    return '${NumberFormat('#,###', 'fr').format(price)} F/j';
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              'Aucune tendance disponible pour le moment.',
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/search'),
              icon: const Icon(Icons.search, size: 16),
              label: const Text('Explorer les résidences'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.textLight,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    return SizedBox(
      height: 350,
      child: ListView.builder(
        padding: EdgeInsets.only(
          left: widget.padding.left,
          right: widget.padding.right,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 176,
            margin: const EdgeInsets.only(right: 10),
            child: Shimmer.fromColors(
              baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              highlightColor: Theme.of(context).colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(height: 14, width: 140, color: Theme.of(context).colorScheme.surface),
                  const SizedBox(height: 2),
                  Container(height: 12, width: 100, color: Theme.of(context).colorScheme.surface),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
