import 'package:equatable/equatable.dart';
import 'package:chapechape_client/core/models/residence_model.dart';

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