import 'package:equatable/equatable.dart';
import 'package:chapechape_client/core/models/user_model.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {
  const UserInitial();
}

class UserLoading extends UserState {
  const UserLoading();
}

class UserProfileLoaded extends UserState {
  final User user;

  const UserProfileLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class UserProfileUpdated extends UserState {
  final User user;

  const UserProfileUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

class UserPasswordChanged extends UserState {
  const UserPasswordChanged();
}

class ProfilePictureUploaded extends UserState {
  final String profilePictureUrl;

  const ProfilePictureUploaded(this.profilePictureUrl);

  @override
  List<Object?> get props => [profilePictureUrl];
}

class BookingHistoryLoaded extends UserState {
  final List<dynamic> bookings;

  const BookingHistoryLoaded(this.bookings);

  @override
  List<Object?> get props => [bookings];
}

class FavoriteResidencesLoaded extends UserState {
  final List<dynamic> favorites;

  const FavoriteResidencesLoaded(this.favorites);

  @override
  List<Object?> get props => [favorites];
}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object?> get props => [message];
}
