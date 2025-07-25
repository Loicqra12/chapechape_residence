import 'reservation.dart';

/// Modèle pour représenter des réservations paginées
class PaginatedReservations {
  final List<Reservation> reservations;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool hasNextPage;
  final bool hasPreviousPage;
  
  const PaginatedReservations({
    required this.reservations,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });
  
  /// Constructeur par défaut avec des valeurs vides
  factory PaginatedReservations.empty() {
    return const PaginatedReservations(
      reservations: [],
      currentPage: 1,
      totalPages: 0,
      totalCount: 0,
      hasNextPage: false,
      hasPreviousPage: false,
    );
  }
  
  /// Constructeur à partir d'une liste non paginée
  factory PaginatedReservations.fromList(List<Reservation> list) {
    return PaginatedReservations(
      reservations: list,
      currentPage: 1,
      totalPages: 1,
      totalCount: list.length,
      hasNextPage: false,
      hasPreviousPage: false,
    );
  }
}
