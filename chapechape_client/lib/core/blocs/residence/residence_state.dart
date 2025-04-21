part of 'residence_bloc.dart';

@immutable
abstract class ResidenceState extends Equatable {
  const ResidenceState();

  @override
  List<Object?> get props => [];
}

class ResidenceInitial extends ResidenceState {
  const ResidenceInitial();
}

class ResidenceLoading extends ResidenceState {
  const ResidenceLoading();
}

class ResidencesLoaded extends ResidenceState {
  final List<Residence> residences;

  const ResidencesLoaded(this.residences);

  @override
  List<Object?> get props => [residences];
}

class ResidenceDetailsLoaded extends ResidenceState {
  final Residence residence;

  const ResidenceDetailsLoaded(this.residence);

  @override
  List<Object?> get props => [residence];
}

class ResidenceAvailabilityChecked extends ResidenceState {
  final bool isAvailable;

  const ResidenceAvailabilityChecked(this.isAvailable);

  @override
  List<Object?> get props => [isAvailable];
}

class ResidenceError extends ResidenceState {
  final String message;

  const ResidenceError(this.message);

  @override
  List<Object?> get props => [message];
}

class ResidencesLoading extends ResidenceState {}

class ResidencesByTypeLoaded extends ResidenceState {
  final List<Residence> residences;
  final String type;
  
  const ResidencesByTypeLoaded({
    required this.residences,
    required this.type,
  });
  
  @override
  List<Object?> get props => [residences, type];
}

class FeaturedResidencesLoading extends ResidenceState {}

class FeaturedResidencesLoaded extends ResidenceState {
  final List<Residence> residences;
  
  const FeaturedResidencesLoaded({
    required this.residences,
  });
  
  @override
  List<Object?> get props => [residences];
}

class SpecialResidencesLoading extends ResidenceState {}

class SpecialResidencesLoaded extends ResidenceState {
  final List<Residence> residences;
  
  const SpecialResidencesLoaded({
    required this.residences,
  });
  
  @override
  List<Object?> get props => [residences];
}

class PopularResidencesLoading extends ResidenceState {}

class PopularResidencesLoaded extends ResidenceState {
  final List<Residence> residences;
  
  const PopularResidencesLoaded({
    required this.residences,
  });
  
  @override
  List<Object?> get props => [residences];
}

class FavoriteResidencesLoading extends ResidenceState {}

class FavoriteResidencesLoaded extends ResidenceState {
  final List<Residence> residences;
  
  const FavoriteResidencesLoaded({
    required this.residences,
  });
  
  @override
  List<Object?> get props => [residences];
}

class ResidencesSearching extends ResidenceState {}

class ResidencesSearchResult extends ResidenceState {
  final List<Residence> residences;
  final String query;
  final Map<String, dynamic>? filters;
  
  const ResidencesSearchResult({
    required this.residences,
    required this.query,
    this.filters,
  });
  
  @override
  List<Object?> get props => [residences, query, filters];
}

class ResidencesFiltering extends ResidenceState {}

class ResidencesFilterResult extends ResidenceState {
  final List<Residence> residences;
  final Map<String, dynamic> filters;
  
  const ResidencesFilterResult({
    required this.residences,
    required this.filters,
  });
  
  @override
  List<Object?> get props => [residences, filters];
}