import 'package:equatable/equatable.dart';

abstract class FavoriteEvent extends Equatable {
  const FavoriteEvent();

  @override
  List<Object?> get props => [];
}

class LoadFavorites extends FavoriteEvent {
  const LoadFavorites();
}

class AddToFavorites extends FavoriteEvent {
  final String residenceId;

  const AddToFavorites(this.residenceId);

  @override
  List<Object?> get props => [residenceId];
}

class RemoveFromFavorites extends FavoriteEvent {
  final String residenceId;

  const RemoveFromFavorites(this.residenceId);

  @override
  List<Object?> get props => [residenceId];
}

class CheckFavorite extends FavoriteEvent {
  final String residenceId;

  const CheckFavorite(this.residenceId);

  @override
  List<Object?> get props => [residenceId];
}
