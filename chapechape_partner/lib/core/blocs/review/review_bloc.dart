import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api/review_service.dart';
import 'review_event.dart';
import 'review_state.dart';

/// BLoC pour gérer les avis
class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final ReviewService _reviewService;

  ReviewBloc({required ReviewService reviewService})
      : _reviewService = reviewService,
        super(ReviewInitial()) {
    on<LoadReviews>(_onLoadReviews);
    on<LoadMoreReviews>(_onLoadMoreReviews);
    on<RespondToReview>(_onRespondToReview);
    on<ReportReview>(_onReportReview);
    on<LoadReviewStats>(_onLoadReviewStats);
    on<LoadRecentPartnerReviews>(_onLoadRecentPartnerReviews);
    on<RefreshReviews>(_onRefreshReviews);
  }

  /// Gère l'événement pour charger les avis d'une résidence
  Future<void> _onLoadReviews(
    LoadReviews event, 
    Emitter<ReviewState> emit,
  ) async {
    emit(ReviewsLoading());
    try {
      final reviews = await _reviewService.getResidenceReviews(
        event.residenceId,
        page: event.page,
        limit: event.limit,
      );
      
      // Dans une implémentation réelle, le backend fournirait également
      // le nombre total de pages et d'autres métadonnées pour la pagination
      emit(ReviewsLoaded(
        reviews: reviews,
        page: event.page,
        totalPages: reviews.isEmpty ? 1 : 5, // Valeur par défaut pour l'exemple
        hasMore: reviews.length >= event.limit,
      ));
    } catch (e) {
      emit(ReviewsLoadFailure(error: e.toString()));
    }
  }

  /// Gère l'événement pour charger plus d'avis (pagination)
  Future<void> _onLoadMoreReviews(
    LoadMoreReviews event, 
    Emitter<ReviewState> emit,
  ) async {
    // On doit être dans l'état ReviewsLoaded pour charger plus d'avis
    final currentState = state;
    if (currentState is ReviewsLoaded) {
      emit(ReviewsLoadingMore(
        currentReviews: currentState.reviews,
        currentPage: currentState.page,
      ));
      
      try {
        final moreReviews = await _reviewService.getResidenceReviews(
          event.residenceId,
          page: event.page,
          limit: event.limit,
        );
        
        final allReviews = List.of(currentState.reviews)..addAll(moreReviews);
        
        emit(ReviewsLoaded(
          reviews: allReviews,
          page: event.page,
          totalPages: currentState.totalPages,
          hasMore: moreReviews.length >= event.limit,
        ));
      } catch (e) {
        emit(ReviewsLoadFailure(error: e.toString()));
      }
    }
  }

  /// Gère l'événement pour répondre à un avis
  Future<void> _onRespondToReview(
    RespondToReview event, 
    Emitter<ReviewState> emit,
  ) async {
    emit(RespondingToReview(reviewId: event.reviewId));
    try {
      final updatedReview = await _reviewService.respondToReview(
        event.reviewId, 
        event.response,
      );
      
      emit(ReviewResponseSuccess(review: updatedReview));
      
      // Si nous avons des avis chargés, mettons à jour l'avis dans la liste
      final currentState = state;
      if (currentState is ReviewsLoaded) {
        final updatedReviews = currentState.reviews.map((review) {
          if (review.id == updatedReview.id) {
            return updatedReview;
          }
          return review;
        }).toList();
        
        emit(ReviewsLoaded(
          reviews: updatedReviews,
          page: currentState.page,
          totalPages: currentState.totalPages,
          hasMore: currentState.hasMore,
        ));
      }
    } catch (e) {
      emit(ReviewResponseFailure(error: e.toString()));
    }
  }

  /// Gère l'événement pour signaler un avis
  Future<void> _onReportReview(
    ReportReview event, 
    Emitter<ReviewState> emit,
  ) async {
    try {
      await _reviewService.reportReview(event.reviewId, event.reason);
      // On ne change pas d'état ici, on pourrait notifier l'utilisateur via un SnackBar
    } catch (e) {
      // Gérer l'erreur
    }
  }

  /// Gère l'événement pour charger les statistiques d'avis
  Future<void> _onLoadReviewStats(
    LoadReviewStats event, 
    Emitter<ReviewState> emit,
  ) async {
    try {
      final stats = await _reviewService.getReviewStats(event.residenceId);
      emit(ReviewStatsLoaded(stats: stats));
    } catch (e) {
      // Gérer l'erreur
    }
  }

  /// Gère l'événement pour charger les avis récents du partenaire
  Future<void> _onLoadRecentPartnerReviews(
    LoadRecentPartnerReviews event, 
    Emitter<ReviewState> emit,
  ) async {
    try {
      final reviews = await _reviewService.getRecentPartnerReviews(limit: event.limit);
      emit(RecentReviewsLoaded(reviews: reviews));
    } catch (e) {
      emit(ReviewsLoadFailure(error: e.toString()));
    }
  }

  /// Gère l'événement pour rafraîchir les avis
  Future<void> _onRefreshReviews(
    RefreshReviews event, 
    Emitter<ReviewState> emit,
  ) async {
    try {
      final reviews = await _reviewService.getResidenceReviews(event.residenceId);
      
      emit(ReviewsLoaded(
        reviews: reviews,
        page: 1,
        totalPages: reviews.isEmpty ? 1 : 5,
        hasMore: reviews.length >= 10,
      ));
    } catch (e) {
      emit(ReviewsLoadFailure(error: e.toString()));
    }
  }
}
