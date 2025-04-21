import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

/// Repository pour gérer l'authentification
class AuthRepository {
  final AuthService _authService;

  AuthRepository({
    required AuthService authService,
  }) : _authService = authService;

  /// Connecte l'utilisateur
  Future<User?> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final user = await _authService.login(
        email: email, 
        password: password,
        rememberMe: rememberMe,
      );
      return user;
    } catch (e) {
      debugPrint('Erreur lors de la connexion: $e');
      return null;
    }
  }

  /// Déconnecte l'utilisateur
  Future<bool> logout() async {
    try {
      await _authService.logout();
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
      return false;
    }
  }

  /// Inscrit un nouvel utilisateur
  Future<User?> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      final user = await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      return user;
    } catch (e) {
      debugPrint('Erreur lors de l\'inscription: $e');
      return null;
    }
  }

  /// Vérifie si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    try {
      return await _authService.isAuthenticated();
    } catch (e) {
      debugPrint('Erreur lors de la vérification d\'authentification: $e');
      return false;
    }
  }
  
  /// Récupère l'utilisateur courant
  Future<User?> getCurrentUser() async {
    try {
      return await _authService.getCurrentUser();
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }
  
  /// Met à jour le profil de l'utilisateur
  Future<User?> updateProfile(Map<String, dynamic> userData) async {
    try {
      return await _authService.updateProfile(userData);
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du profil: $e');
      return null;
    }
  }
  
  /// Change le mot de passe de l'utilisateur
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      debugPrint('Erreur lors du changement de mot de passe: $e');
      return false;
    }
  }
}