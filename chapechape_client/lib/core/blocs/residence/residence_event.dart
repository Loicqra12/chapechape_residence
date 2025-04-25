part of 'residence_bloc.dart';

abstract class ResidenceEvent extends Equatable {
  const ResidenceEvent();

  @override
  List<Object?> get props => [];
}

class LoadResidencesEvent extends ResidenceEvent {
  final bool forceRefresh;

  const LoadResidencesEvent({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class LoadMoreResidencesEvent extends ResidenceEvent {}

class SearchResidencesEvent extends ResidenceEvent {
  final Map<String, dynamic> filters;
  final int page;
  final int limit;

  const SearchResidencesEvent({
    required this.filters,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [filters, page, limit];
}

class LoadResidenceDetails extends ResidenceEvent {
  final String residenceId;

  const LoadResidenceDetails({required this.residenceId});

  @override
  List<Object?> get props => [residenceId];
}

class ToggleFavorite extends ResidenceEvent {
  final String residenceId;

  const ToggleFavorite({required this.residenceId});

  @override
  List<Object?> get props => [residenceId];
}

class AddToFavorites extends ResidenceEvent {
  final String residenceId;

  const AddToFavorites({required this.residenceId});

  @override
  List<Object?> get props => [residenceId];
}

class RemoveFromFavorites extends ResidenceEvent {
  final String residenceId;

  const RemoveFromFavorites({required this.residenceId});

  @override
  List<Object?> get props => [residenceId];
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

class LoadResidencesByType extends ResidenceEvent {
  final String type;
  
  const LoadResidencesByType(this.type);
  
  @override
  List<Object?> get props => [type];
}

class LoadFeaturedResidences extends ResidenceEvent {
  const LoadFeaturedResidences();
}

class LoadSpecialResidences extends ResidenceEvent {
  const LoadSpecialResidences();
}

class LoadPopularResidences extends ResidenceEvent {
  const LoadPopularResidences();
}

class SearchResidences extends ResidenceEvent {
  final String query;
  final Map<String, dynamic>? filters;
  
  const SearchResidences({
    required this.query,
    this.filters,
  });
  
  @override
  List<Object?> get props => [query, filters];
}

class FilterResidences extends ResidenceEvent {
  final Map<String, dynamic> filters;
  
  const FilterResidences({
    required this.filters,
  });
  
  @override
  List<Object?> get props => [filters];
}

class FilterResidencesByTypeEvent extends ResidenceEvent {
  final ResidenceType type;
  final String? categoryLabel;

  const FilterResidencesByTypeEvent(this.type, {this.categoryLabel});

  @override
  List<Object?> get props => [type, categoryLabel];
}

class FilterResidencesByLocation extends ResidenceEvent {
  final String? cityId;
  final String? region;
  final String? countryCode;
  final String? neighborhood;

  FilterResidencesByLocation({
    this.cityId,
    this.region,
    this.countryCode,
    this.neighborhood,
  });

  @override
  List<Object?> get props => [cityId, region, countryCode, neighborhood];
}

class ClearFiltersEvent extends ResidenceEvent {}

class RefreshResidencesEvent extends ResidenceEvent {}

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