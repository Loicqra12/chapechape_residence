import 'package:equatable/equatable.dart';
import '../../models/review/review_model.dart';

/// États liés aux avis
abstract class ReviewState extends Equatable {
  const ReviewState();

  @override
  List<Object?> get props => [];
}

/// État initial
class ReviewInitial extends ReviewState {}

/// Chargement des avis en cours
class ReviewsLoading extends ReviewState {}

/// Chargement des avis supplémentaires en cours (pagination)
class ReviewsLoadingMore extends ReviewState {
  final List<ReviewModel> currentReviews;
  final int currentPage;

  const ReviewsLoadingMore({
    required this.currentReviews,
    required this.currentPage,
  });

  @override
  List<Object?> get props => [currentReviews, currentPage];
}

/// Avis chargés avec succès
class ReviewsLoaded extends ReviewState {
  final List<ReviewModel> reviews;
  final int page;
  final int totalPages;
  final bool hasMore;

  const ReviewsLoaded({
    required this.reviews,
    required this.page,
    required this.totalPages,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [reviews, page, totalPages, hasMore];
}

/// Échec du chargement des avis
class ReviewsLoadFailure extends ReviewState {
  final String error;

  const ReviewsLoadFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

/// Statistiques d'avis chargées avec succès
class ReviewStatsLoaded extends ReviewState {
  final Map<String, dynamic> stats;

  const ReviewStatsLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

/// Avis récents du partenaire chargés avec succès
class RecentReviewsLoaded extends ReviewState {
  final List<ReviewModel> reviews;

  const RecentReviewsLoaded({required this.reviews});

  @override
  List<Object?> get props => [reviews];
}

/// Réponse à un avis en cours
class RespondingToReview extends ReviewState {
  final String reviewId;

  const RespondingToReview({required this.reviewId});

  @override
  List<Object?> get props => [reviewId];
}

/// Réponse à un avis réussie
class ReviewResponseSuccess extends ReviewState {
  final ReviewModel review;

  const ReviewResponseSuccess({required this.review});

  @override
  List<Object?> get props => [review];
}

/// Échec de la réponse à un avis
class ReviewResponseFailure extends ReviewState {
  final String error;

  const ReviewResponseFailure({required this.error});

  @override
  List<Object?> get props => [error];
}
