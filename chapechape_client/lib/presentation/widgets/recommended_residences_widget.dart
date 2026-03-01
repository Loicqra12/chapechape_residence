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
      height: 168,
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
    final locationStr = _getLocationString(residence.location);
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: GestureDetector(
        onTap: () {
          _recommendationService.addToViewHistory(residence.id);
          context.push('/residence/${residence.id}');
        },
        child: Container(
          width: 176,
          margin: EdgeInsets.only(right: 10, left: widget.padding.horizontal / 2),
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
                      child: CachedNetworkImage(
                        imageUrl: residence.images.isNotEmpty
                            ? residence.images.first
                            : 'assets/images/placeholders/residence_premium.jpg',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (context, url, error) => Image.asset(
                          AppAssets.placeholderImage,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.thumb_up, size: 10, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              'Pour vous',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                        StringUtils.formatPrice(residence.price),
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
                StringUtils.toTitleCase(residence.title),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      locationStr,
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
