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
}

// Événement d'inscription
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
  final dynamic documentFile;

  const UploadDocumentRequested({
    required this.documentType,
    required this.documentFile,
  });

  @override
  List<Object?> get props => [documentType, documentFile];
}

// Événement de suppression de compte
class AuthDeleteAccountRequested extends AuthEvent {
  final String password;
  
  const AuthDeleteAccountRequested({required this.password});
  
  @override
  List<Object> get props => [password];
}
