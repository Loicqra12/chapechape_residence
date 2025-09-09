import 'package:flutter/material.dart';
import 'package:chapechape_client/core/services/residence_service.dart';
import 'package:intl/intl.dart';

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
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[600]),
            ),
            const SizedBox(height: 16),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun avis pour cette résidence',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Soyez le premier à laisser un avis !',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReviews,
      color: goldColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (stats.isNotEmpty) _buildStatsSection(stats),
          const SizedBox(height: 20),
          _buildReviewsList(reviews),
        ],
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats) {
    final averageRating = (stats['averageOverallRating'] as num?)?.toDouble() ?? 0.0;
    final numberOfReviews = stats['numberOfReviews'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: goldColor,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStarRating(averageRating),
                  const SizedBox(height: 4),
                  Text(
                    '$numberOfReviews avis',
                    style: TextStyle(
                      fontSize: 14,
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
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: blackColor,
          ),
        ),
        const SizedBox(height: 16),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
                  style: const TextStyle(
                    color: blackColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName.isNotEmpty ? userName : 'Utilisateur anonyme',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (reviewDate != null)
                      Text(
                        DateFormat('dd/MM/yyyy').format(reviewDate),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
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
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}