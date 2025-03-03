import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/partner/partner_model.dart';
import '../../services/api/auth_service.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String password;

  const AuthRegisterRequested({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.password,
  });

  @override
  List<Object?> get props => [firstName, lastName, email, phoneNumber, password];
}

class AuthLogoutRequested extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String token;
  final Partner partner;

  const AuthAuthenticated({
    required this.token,
    required this.partner,
  });

  @override
  List<Object?> get props => [token, partner];
}

class AuthUnauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;
  final FlutterSecureStorage storage;

  AuthBloc({
    required this.authService,
    required this.storage,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final token = await storage.read(key: 'token');
        if (token != null) {
          final partner = await authService.getProfile();
          emit(AuthAuthenticated(token: token, partner: partner));
        } else {
          emit(AuthUnauthenticated());
        }
      } catch (e) {
        emit(AuthUnauthenticated());
      }
    });

    on<AuthLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final loginResult = await authService.login(
          email: event.email,
          password: event.password,
        );
        await storage.write(key: 'token', value: loginResult.token);
        emit(AuthAuthenticated(
          token: loginResult.token,
          partner: loginResult.partner,
        ));
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<AuthRegisterRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final registerResult = await authService.register(
          firstName: event.firstName,
          lastName: event.lastName,
          email: event.email,
          phoneNumber: event.phoneNumber,
          password: event.password,
        );
        await storage.write(key: 'token', value: registerResult.token);
        emit(AuthAuthenticated(
          token: registerResult.token,
          partner: registerResult.partner,
        ));
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    on<AuthLogoutRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await storage.delete(key: 'token');
        emit(AuthUnauthenticated());
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    // Vérifier l'état d'authentification au démarrage
    add(AuthCheckRequested());
  }
}
