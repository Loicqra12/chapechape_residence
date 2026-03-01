import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:get_it/get_it.dart';

import '../../core/models/residence_model.dart';
import '../../core/services/residence_service.dart';
import '../../core/services/recently_viewed_service.dart';
import '../../core/utils/string_utils.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_styles.dart';
import '../../core/constants/app_assets.dart';

/// Section compacte « Mieux notées » : une ligne horizontale, style pro.
class TopRatedSectionWidget extends StatelessWidget {
  final int limit;
  final EdgeInsets padding;

  const TopRatedSectionWidget({
    Key? key,
    this.limit = 6,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final residenceService = GetIt.instance<ResidenceService>();
    return FutureBuilder<List<Residence>>(
      future: residenceService.getPopularResidences(forceRefresh: false),
      builder: (context, snapshot) {
        final list = (snapshot.data ?? []).take(limit).toList();
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        if (isLoading) return _buildSkeleton(context);
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: padding.left, right: padding.right),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  return _CompactResidenceCard(
                    residence: list[index],
                    badge: _buildRatingBadge(list[index].rating),
                    onTap: () => context.push('/residence/${list[index].id}'),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Icon(Icons.star_rounded, size: 20, color: const Color(0xFF1A1A1A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Mieux notées', style: AppTextStyles.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF1A1A1A)),
            style: IconButton.styleFrom(minimumSize: const Size(40, 40), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
            tooltip: 'Voir tout',
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 10),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(left: padding.left, right: padding.right),
            itemCount: 3,
            itemBuilder: (context, index) => _ShimmerCard(),
          ),
        ),
      ],
    );
  }
}

/// Section compacte « Récemment consultées » : une ligne horizontale.
class RecentlyViewedSectionWidget extends StatefulWidget {
  final int maxItems;
  final EdgeInsets padding;

  const RecentlyViewedSectionWidget({
    Key? key,
    this.maxItems = 6,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  }) : super(key: key);

  @override
  State<RecentlyViewedSectionWidget> createState() => _RecentlyViewedSectionWidgetState();
}

class _RecentlyViewedSectionWidgetState extends State<RecentlyViewedSectionWidget> {
  late final Future<List<Residence>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadRecentlyViewed();
  }

  Future<List<Residence>> _loadRecentlyViewed() async {
    final recentService = await RecentlyViewedService.getInstance();
    final ids = await recentService.getIds();
    if (ids.isEmpty) return [];
    final service = GetIt.instance<ResidenceService>();
    final results = await Future.wait(
      ids.take(widget.maxItems).map((id) => service.getResidenceById(id)),
    );
    return results.whereType<Residence>().toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Residence>>(
      future: _future,
      builder: (context, snapshot) {
        final list = snapshot.data ?? [];
        if (list.isEmpty) return const SizedBox.shrink();
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        if (isLoading) return _buildSkeleton(context);
        return Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: widget.padding.left, right: widget.padding.right),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  return _CompactResidenceCard(
                    residence: list[index],
                    badge: null,
                    onTap: () => context.push('/residence/${list[index].id}'),
                  );
                },
              ),
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
        children: [
          const Icon(Icons.history, size: 20, color: Color(0xFF1A1A1A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Récemment consultées', style: AppTextStyles.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            onPressed: () => context.push('/search'),
            icon: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF1A1A1A)),
            style: IconButton.styleFrom(minimumSize: const Size(40, 40), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
            tooltip: 'Voir tout',
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(left: widget.padding.left, right: widget.padding.right),
            itemCount: 3,
            itemBuilder: (context, index) => _ShimmerCard(),
          ),
        ),
      ],
    );
  }
}

/// Carte résidence compacte (design uniforme : image = carte, texte en dessous).
class _CompactResidenceCard extends StatelessWidget {
  final Residence residence;
  final Widget? badge;
  final VoidCallback onTap;

  const _CompactResidenceCard({
    required this.residence,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = residence.title ?? 'Résidence';
    final location = residence.formattedAddress.isNotEmpty
        ? residence.formattedAddress
        : (residence.address.isNotEmpty
            ? residence.address
            : (residence.city.isNotEmpty ? residence.city : 'Emplacement non spécifié'));
    final imageUrl = residence.images.isNotEmpty ? residence.images.first : null;

    return GestureDetector(
      onTap: onTap,
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
                  if (badge != null) Positioned(top: 6, right: 6, child: badge!),
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
                      _formatPrice(residence.price),
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
            const SizedBox(height: 5),
            Text(
              StringUtils.toTitleCase(title),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null) {
      return Image.asset(AppAssets.placeholderImage, fit: BoxFit.cover);
    }
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(color: Colors.white),
        ),
        errorWidget: (_, __, ___) => Container(
          color: Colors.grey[200],
          child: Icon(Icons.home_outlined, color: Colors.grey[400], size: 28),
        ),
      );
    }
    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey[200],
        child: Icon(Icons.home_outlined, color: Colors.grey[400], size: 28),
      ),
    );
  }

  String _formatPrice(double? price) {
    if (price == null) return '—';
    return '${NumberFormat('#,###', 'fr').format(price)} F/j';
  }
}

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176,
      margin: const EdgeInsets.only(right: 10),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Container(height: 14, width: 140, color: Colors.white),
            const SizedBox(height: 1),
            Container(height: 10, width: 100, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
