import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/models/residence_model.dart';
import '../../core/services/recommendation_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/string_utils.dart';
import '../../core/constants/app_assets.dart';
import '../../core/services/logger_service.dart';

/// Widget qui affiche les résidences recommandées personnalisées
/// 
/// Ce widget utilise le RecommendationService pour générer des suggestions
/// adaptées aux préférences et à l'historique de l'utilisateur
class RecommendedResidencesWidget extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onSeeAllPressed;
  final EdgeInsets padding;
  final String title;
  final String subtitle;
  final String emptyStateMessage;
  final bool enableAnimation;
  final int itemCount;

  const RecommendedResidencesWidget({
    Key? key,
    this.isLoading = false,
    this.onSeeAllPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.title = 'Résidences recommandées',
    this.subtitle = 'Sélectionnées selon vos préférences et votre historique',
    this.emptyStateMessage = 'Aucune recommandation disponible',
    this.enableAnimation = true,
    this.itemCount = 6,
  }) : super(key: key);

  @override
  State<RecommendedResidencesWidget> createState() => _RecommendedResidencesWidgetState();
}

class _RecommendedResidencesWidgetState extends State<RecommendedResidencesWidget> {
  final RecommendationService _recommendationService = RecommendationService();
  final LoggerService _logger = LoggerService();
  List<Residence> _recommendations = [];
  bool _isLoading = true;
  int _hoveredIndex = -1;
  
  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }
  
  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final recommendations = await _recommendationService.getRecommendedResidences(
        limit: widget.itemCount
      );
      
      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      _logger.error('Erreur lors du chargement des recommandations: $e');
      setState(() {
        _recommendations = [];
        _isLoading = false;
      });
    }
  }

  String _getLocationString(Map<String, dynamic> location) {
    return '${location['city'] ?? ''}, ${location['country'] ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        _isLoading || widget.isLoading
            ? _buildLoadingSkeleton(context)
            : _buildRecommendationsList(context),
      ],
    ).animate(
      target: widget.enableAnimation ? 1 : 0,
    ).fadeIn(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.thumb_up_outlined,
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
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onSeeAllPressed != null)
            TextButton(
              onPressed: widget.onSeeAllPressed,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Voir tout',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsList(BuildContext context) {
    if (_recommendations.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return SizedBox(
      height: 260,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: widget.padding.horizontal / 2),
        scrollDirection: Axis.horizontal,
        itemCount: _recommendations.length,
        itemBuilder: (context, index) {
          final residence = _recommendations[index];
          return _buildResidenceCard(context, residence, index);
        },
      ),
    );
  }

  Widget _buildResidenceCard(BuildContext context, Residence residence, int index) {
    final cardWidth = MediaQuery.of(context).size.width < 600 ? 220.0 : 260.0;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: GestureDetector(
        onTap: () {
          _recommendationService.addToViewHistory(residence.id);
          context.push('/residence/${residence.id}');
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: widget.padding.horizontal / 2),
          width: cardWidth,
          child: Card(
            elevation: _hoveredIndex == index ? 4 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image de la résidence
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: residence.images.isNotEmpty 
                            ? residence.images.first 
                            : 'assets/images/placeholders/residence_premium.jpg',
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 140,
                            width: double.infinity,
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: (context, url, error) => Image.asset(
                          AppAssets.placeholderImage,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Badge "Recommandé pour vous"
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.thumb_up,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Pour vous',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Prix
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          StringUtils.formatPrice(residence.price),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Informations sur la résidence
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        StringUtils.toTitleCase(residence.title),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getLocationString(residence.location),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildFeatureChip(
                            context,
                            Icons.bed,
                            '${residence.bedrooms} ch.',
                          ),
                          _buildFeatureChip(
                            context,
                            Icons.bathtub_outlined,
                            '${residence.bathrooms} sdb',
                          ),
                          _buildFeatureChip(
                            context,
                            Icons.square_foot,
                            '${residence.squareMeters.toInt()} m²',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate(
            target: _hoveredIndex == index ? 1 : 0,
          ).scale(
            duration: const Duration(milliseconds: 200),
            begin: const Offset(1, 1),
            end: const Offset(1.02, 1.02),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600], // Icône grise fine
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: widget.padding,
      alignment: Alignment.center,
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_outlined,
            size: 48,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            widget.emptyStateMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadRecommendations,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Actualiser'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: widget.padding.horizontal / 2),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return _buildSkeletonCard(context);
        },
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width < 600 ? 220.0 : 260.0;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: widget.padding.horizontal / 2),
      width: cardWidth,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: cardWidth * 0.7,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        3,
                        (index) => Container(
                          height: 12,
                          width: 50,
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
  }
}
