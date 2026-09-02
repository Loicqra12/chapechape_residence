// Auth Events will be defined here

import 'package:equatable/equatable.dart';

/// Classe de base pour tous les événements d'authentification
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// Événement de vérification de l'authentification
class AuthCheckRequested extends AuthEvent {}

/// Rafraîchit /auth/me sans écran de chargement (après OTP).
class AuthProfileRefreshRequested extends AuthEvent {}

// Événement de connexion
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];

  @override
  String toString() => 'AuthLoginRequested($email, ***)';
}

// Événement d'inscription
class AuthRegisterRequested extends AuthEvent {
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String password;
  final String? countryCode;

  const AuthRegisterRequested({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    this.countryCode,
  });

  @override
  List<Object?> get props => [firstName, lastName, email, phoneNumber, password, countryCode];

  @override
  String toString() =>
      'AuthRegisterRequested($firstName, $lastName, $email, $phoneNumber, ***, $countryCode)';
}

// Événement de déconnexion
class AuthLogoutRequested extends AuthEvent {}

// Événement de mise à jour du profil
class UpdateProfileRequested extends AuthEvent {
  final Map<String, dynamic> userData;

  const UpdateProfileRequested({required this.userData});

  @override
  List<Object?> get props => [userData];
}

// Événement de téléchargement de la photo de profil
class UploadProfilePictureRequested extends AuthEvent {
  final dynamic imageFile;

  const UploadProfilePictureRequested(this.imageFile);

  @override
  List<Object?> get props => [imageFile];
}

// Événement de téléchargement de document
class UploadDocumentRequested extends AuthEvent {
  final String documentType;
  final dynamic documentFile; // Pour mobile (File)
  final dynamic documentBytes; // Pour web (Uint8List)
  final String? fileName;

  const UploadDocumentRequested({
    required this.documentType,
    this.documentFile,
    this.documentBytes,
    this.fileName,
  }) : assert(documentFile != null || documentBytes != null, 'Soit documentFile soit documentBytes doit être fourni');

  @override
  List<Object?> get props => [documentType, documentFile, documentBytes, fileName];
}

// Événement de suppression de compte
class AuthDeleteAccountRequested extends AuthEvent {
  final String password;
  
  const AuthDeleteAccountRequested({required this.password});
  
  @override
  List<Object> get props => [password];

  @override
  String toString() => 'AuthDeleteAccountRequested(***)';
}

// Événement de demande de réinitialisation de mot de passe
class ForgotPasswordRequested extends AuthEvent {
  final String email;
  
  const ForgotPasswordRequested({required this.email});
  
  @override
  List<Object> get props => [email];
}

// Événement de réinitialisation de mot de passe
class ResetPasswordRequested extends AuthEvent {
  final String token;
  final String newPassword;
  
  const ResetPasswordRequested({
    required this.token,
    required this.newPassword,
  });
  
  @override
  List<Object> get props => [token, newPassword];

  @override
  String toString() => 'ResetPasswordRequested(***, ***)';
}
