import 'package:equatable/equatable.dart';
import '../../models/residence_model.dart';

abstract class FavoriteState extends Equatable {
  const FavoriteState();

  @override
  List<Object?> get props => [];
}

class FavoriteInitial extends FavoriteState {
  const FavoriteInitial();
}

class FavoriteLoading extends FavoriteState {
  const FavoriteLoading();
}

class FavoriteLoaded extends FavoriteState {
  final List<Residence> favorites;

  const FavoriteLoaded(this.favorites);

  @override
  List<Object?> get props => [favorites];
}

class FavoriteChecked extends FavoriteState {
  final String residenceId;
  final bool isFavorite;

  const FavoriteChecked(this.residenceId, this.isFavorite);

  @override
  List<Object?> get props => [residenceId, isFavorite];
}

class FavoriteError extends FavoriteState {
  final String message;

  const FavoriteError(this.message);

  @override
  List<Object?> get props => [message];
}
