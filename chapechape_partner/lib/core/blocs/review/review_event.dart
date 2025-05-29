import 'package:equatable/equatable.dart';

/// Événements liés aux avis
abstract class ReviewEvent extends Equatable {
  const ReviewEvent();

  @override
  List<Object?> get props => [];
}

/// Charge les avis pour une résidence spécifique
class LoadReviews extends ReviewEvent {
  final String residenceId;
  final int page;
  final int limit;

  const LoadReviews(this.residenceId, {this.page = 1, this.limit = 10});

  @override
  List<Object?> get props => [residenceId, page, limit];
}

/// Charge plus d'avis (pagination)
class LoadMoreReviews extends ReviewEvent {
  final String residenceId;
  final int page;
  final int limit;

  const LoadMoreReviews(this.residenceId, {required this.page, this.limit = 10});

  @override
  List<Object?> get props => [residenceId, page, limit];
}

/// Répond à un avis
class RespondToReview extends ReviewEvent {
  final String reviewId;
  final String response;

  const RespondToReview({
    required this.reviewId,
    required this.response,
  });

  @override
  List<Object?> get props => [reviewId, response];
}

/// Signale un avis inapproprié
class ReportReview extends ReviewEvent {
  final String reviewId;
  final String reason;

  const ReportReview({
    required this.reviewId,
    required this.reason,
  });

  @override
  List<Object?> get props => [reviewId, reason];
}

/// Charge les statistiques d'avis pour une résidence
class LoadReviewStats extends ReviewEvent {
  final String residenceId;

  const LoadReviewStats(this.residenceId);

  @override
  List<Object?> get props => [residenceId];
}

/// Charge les avis récents du partenaire
class LoadRecentPartnerReviews extends ReviewEvent {
  final int limit;

  const LoadRecentPartnerReviews({this.limit = 5});

  @override
  List<Object?> get props => [limit];
}

/// Rafraîchit les avis
class RefreshReviews extends ReviewEvent {
  final String residenceId;

  const RefreshReviews(this.residenceId);

  @override
  List<Object?> get props => [residenceId];
}
