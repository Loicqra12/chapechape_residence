import 'package:equatable/equatable.dart';
import 'package:chapechape_client/core/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class RegisterSuccess extends AuthState {
  const RegisterSuccess();
}

class ForgotPasswordSuccess extends AuthState {
  const ForgotPasswordSuccess();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProfileUpdateSuccess extends AuthState {
  final User user;

  const ProfileUpdateSuccess(this.user);

  @override
  List<Object?> get props => [user];
}