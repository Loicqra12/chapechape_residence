import 'package:equatable/equatable.dart';

abstract class ResidenceEvent extends Equatable {
  const ResidenceEvent();

  @override
  List<Object?> get props => [];
}

class LoadResidences extends ResidenceEvent {
  final Map<String, dynamic>? filters;
  final int page;
  final int limit;

  const LoadResidences({
    this.filters,
    this.page = 1,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [filters, page, limit];
}

class LoadResidenceDetails extends ResidenceEvent {
  final String residenceId;

  const LoadResidenceDetails(this.residenceId);

  @override
  List<Object?> get props => [residenceId];
}

class SearchResidences extends ResidenceEvent {
  final String? query;
  final String? city;
  final double? minPrice;
  final double? maxPrice;
  final int? bedrooms;
  final int? bathrooms;
  final List<String>? amenities;
  final DateTime? checkIn;
  final DateTime? checkOut;

  const SearchResidences({
    this.query,
    this.city,
    this.minPrice,
    this.maxPrice,
    this.bedrooms,
    this.bathrooms,
    this.amenities,
    this.checkIn,
    this.checkOut,
  });

  @override
  List<Object?> get props => [
        query,
        city,
        minPrice,
        maxPrice,
        bedrooms,
        bathrooms,
        amenities,
        checkIn,
        checkOut,
      ];
}

class ToggleFavorite extends ResidenceEvent {
  final String residenceId;
  final bool isFavorite;

  const ToggleFavorite({
    required this.residenceId,
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [residenceId, isFavorite];
}

class LoadFavoriteResidences extends ResidenceEvent {
  const LoadFavoriteResidences();
}

class CheckResidenceAvailability extends ResidenceEvent {
  final String residenceId;
  final DateTime checkIn;
  final DateTime checkOut;

  const CheckResidenceAvailability({
    required this.residenceId,
    required this.checkIn,
    required this.checkOut,
  });

  @override
  List<Object?> get props => [residenceId, checkIn, checkOut];
}