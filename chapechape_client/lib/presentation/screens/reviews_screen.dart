import 'package:flutter/material.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/core/theme/text_styles.dart';
import 'package:chapechape_client/core/services/residence_service.dart';
import 'package:intl/intl.dart';
import 'package:chapechape_client/presentation/widgets/common/empty_state_widget.dart';

class ReviewsScreen extends StatefulWidget {
  final String residenceId;
  
  const ReviewsScreen({super.key, required this.residenceId});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  static const Color goldColor = Color(0xFFFFD700);
  static const Color darkGold = Color(0xFFCCAC00);
  static const Color orangeColor = Color(0xFFFF8C00);
  static const Color blackColor = Color(0xFF1A1A1A);

  late ResidenceService _residenceService;
  Map<String, dynamic> reviewsData = {};
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadReviews();
  }

  Future<void> _initializeAndLoadReviews() async {
    try {
      _residenceService = await ResidenceService.initialize();
      await _loadReviews();
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur d\'initialisation: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final data = await _residenceService.getResidenceReviews(widget.residenceId);
      
      setState(() {
        reviewsData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors du chargement des avis: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avis'),
        backgroundColor: goldColor,
        foregroundColor: blackColor,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(goldColor),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            AppSpacing.verticalMd,
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red[600]),
            ),
            AppSpacing.verticalMd,
            ElevatedButton(
              onPressed: _loadReviews,
              style: ElevatedButton.styleFrom(
                backgroundColor: goldColor,
                foregroundColor: blackColor,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final reviews = reviewsData['reviews'] as List<dynamic>? ?? [];
    final stats = reviewsData['stats'] as Map<String, dynamic>? ?? {};

    if (reviews.isEmpty) {
    if (reviews.isEmpty) {
      return const EmptyStateWidget(
        imagePath: 'assets/images/empty_states/empty_reviews_illustration.png',
        title: 'Aucun avis pour l\'instant',
        subtitle: 'Soyez le premier à partager votre expérience dans cette résidence',
        fallbackIcon: Icons.rate_review_outlined,
      );
    }
    }

    return RefreshIndicator(
      onRefresh: _loadReviews,
      color: goldColor,
      child: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          if (stats.isNotEmpty) _buildStatsSection(stats),
          SizedBox(height: AppSpacing.lg20), // 20px
          _buildReviewsList(reviews),
        ],
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats) {
    final averageRating = (stats['averageOverallRating'] as num?)?.toDouble() ?? 0.0;
    final numberOfReviews = stats['numberOfReviews'] as int? ?? 0;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg20), // 20px
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 48,
                  color: goldColor,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStarRating(averageRating),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    '$numberOfReviews avis',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor() ? Icons.star : 
          index < rating ? Icons.star_half : Icons.star_border,
          color: goldColor,
          size: 20,
        );
      }),
    );
  }

  Widget _buildReviewsList(List<dynamic> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Avis des clients',
          style: AppTextStyles.title.copyWith(color: blackColor),
        ),
        AppSpacing.verticalMd,
        ...reviews.map((review) => _buildReviewCard(review)).toList(),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final user = review['user'] as Map<String, dynamic>? ?? {};
    final rating = review['rating'] as Map<String, dynamic>? ?? {};
    final overallRating = (rating['overall'] as num?)?.toDouble() ?? 0.0;
    final comment = review['comment'] as String? ?? '';
    final createdAt = review['createdAt'] as String?;
    
    final userName = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    DateTime? reviewDate;
    if (createdAt != null) {
      try {
        reviewDate = DateTime.parse(createdAt);
      } catch (e) {
        // Ignore parsing errors
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: goldColor,
                child: Text(
                  userInitial,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: blackColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.smd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName.isNotEmpty ? userName : 'Utilisateur anonyme',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (reviewDate != null)
                      Text(
                        DateFormat('dd/MM/yyyy').format(reviewDate),
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStarRating(overallRating),
                  Text(
                    overallRating.toStringAsFixed(1),
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            AppSpacing.verticalSmd,
            Text(
              comment,
              style: AppTextStyles.body.copyWith(height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}