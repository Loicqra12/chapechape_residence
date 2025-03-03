import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chapechape_client/core/models/user_model.dart';
import 'package:chapechape_client/core/services/api_service.dart';

class AuthService {
  final ApiService _apiService;
  final FlutterSecureStorage _storage;

  AuthService._({
    required ApiService apiService,
    required FlutterSecureStorage storage,
  })  : _apiService = apiService,
        _storage = storage;

  static Future<AuthService> initialize() async {
    final apiService = await ApiService.initialize();
    const storage = FlutterSecureStorage();
    
    return AuthService._(
      apiService: apiService,
      storage: storage,
    );
  }

  // Inscription
  Future<User> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      // Format exact comme dans Postman, avec rôle "client"
      final response = await _apiService.post('/auth/register', data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phone,
        'role': 'client'  // Utiliser 'client' comme demandé
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
    bool rememberMe = false,
  }) async {
    try {
      // Ajouter des logs pour déboguer
      print('Tentative de connexion avec: $email');
      
      // Format exact comme dans Postman
      final Map<String, dynamic> loginData = {
        'email': email,
        'password': password,
      };
      
      // Ajouter rememberMe si nécessaire
      if (rememberMe) {
        loginData['rememberMe'] = true;
      }
      
      // Utiliser le chemin complet avec /api
      final response = await _apiService.post('/auth/login', data: loginData);

      print('Réponse du serveur: ${response.data}');
      
      final user = User.fromJson(response.data['user']);
      await _storage.write(key: 'token', value: response.data['token']);
      
      if (rememberMe) {
        await _storage.write(key: 'refresh_token', value: response.data['refreshToken']);
      }
      
      return user;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Déconnexion
  Future<void> logout() async {
    try {
      await _apiService.post('/auth/logout');
      await _storage.delete(key: 'token');
    } catch (e) {
      // Même en cas d'erreur, on supprime le token local
      await _storage.delete(key: 'token');
    }
  }

  // Récupérer l'utilisateur courant
  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiService.get('/auth/me');
      return User.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token expiré ou invalide
        await _storage.delete(key: 'token');
        return null;
      }
      throw _handleDioError(e);
    }
  }

  // Vérifier si l'utilisateur est authentifié
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: 'token');
    return token != null;
  }

  // Mettre à jour le profil
  Future<User> updateProfile(Map<String, dynamic> userData) async {
    try {
      final response = await _apiService.put('/auth/profile', data: userData);
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