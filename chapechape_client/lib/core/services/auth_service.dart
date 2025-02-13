import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chapechape_client/core/models/user_model.dart';
import 'package:chapechape_client/core/services/api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Inscription
  Future<User> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    try {
      final response = await _apiService.post('/auth/register', data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
      });

      final user = User.fromJson(response.data['user']);
      await _storage.write(key: 'token', value: response.data['token']);
      return user;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Connexion
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final user = User.fromJson(response.data['user']);
      await _storage.write(key: 'token', value: response.data['token']);
      return user;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Déconnexion
  Future<void> logout() async {
    try {
      await _storage.delete(key: 'token');
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion');
    }
  }

  // Récupérer l'utilisateur actuel
  Future<User> getCurrentUser() async {
    try {
      final response = await _apiService.get('/auth/me');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Mettre à jour le profil
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profilePicture,
  }) async {
    try {
      final response = await _apiService.put('/auth/profile', data: {
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (profilePicture != null) 'profilePicture': profilePicture,
      });

      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Changer le mot de passe
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiService.put('/auth/password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Réinitialiser le mot de passe
  Future<void> resetPassword({required String email}) async {
    try {
      await _apiService.post('/auth/reset-password', data: {
        'email': email,
      });
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Vérifier l'email
  Future<void> verifyEmail({required String token}) async {
    try {
      await _apiService.post('/auth/verify-email', data: {
        'token': token,
      });
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Gérer les erreurs Dio
  Exception _handleDioError(DioException e) {
    switch (e.response?.statusCode) {
      case 400:
        return Exception(e.response?.data['message'] ?? 'Requête invalide');
      case 401:
        return Exception('Non autorisé');
      case 404:
        return Exception('Ressource non trouvée');
      case 409:
        return Exception('Conflit - Email déjà utilisé');
      case 422:
        return Exception('Données invalides');
      case 500:
        return Exception('Erreur serveur');
      default:
        return Exception('Une erreur est survenue');
    }
  }
}