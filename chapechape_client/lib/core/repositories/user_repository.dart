import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserRepository {
  final UserService _userService;

  UserRepository({
    required UserService userService,
  }) : _userService = userService;

  /// Récupère les informations de l'utilisateur actuel
  Future<User?> getCurrentUser() async {
    try {
      return await _userService.getUserProfile();
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'utilisateur: $e');
      return null;
    }
  }

  /// Met à jour les informations de l'utilisateur
  Future<bool> updateUser({
    required Map<String, dynamic> userData,
  }) async {
    try {
      // Extraire les données correctes pour updateProfile
      await _userService.updateProfile(
        firstName: userData['firstName'] as String?,
        lastName: userData['lastName'] as String?,
        phoneNumber: userData['phoneNumber'] as String?,
        profilePicture: userData['profilePicture'] as String?,
      );
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de l\'utilisateur: $e');
      return false;
    }
  }

  /// Met à jour le mot de passe de l'utilisateur
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _userService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du mot de passe: $e');
      return false;
    }
  }

  /// Met à jour la photo de profil de l'utilisateur
  Future<bool> updateProfilePicture({
    required String imagePath,
  }) async {
    try {
      final newImageUrl = await _userService.uploadProfilePicture(imagePath);
      return newImageUrl.isNotEmpty;
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la photo de profil: $e');
      return false;
    }
  }

  /// Supprime le compte de l'utilisateur
  Future<bool> deleteAccount() async {
    try {
      // Cette méthode n'existe pas dans le service, nous devons l'implémenter
      // Pour l'instant, on renvoie un message d'erreur
      debugPrint('Méthode deleteAccount non implémentée dans UserService');
      return false;
    } catch (e) {
      debugPrint('Erreur lors de la suppression du compte: $e');
      return false;
    }
  }
} 