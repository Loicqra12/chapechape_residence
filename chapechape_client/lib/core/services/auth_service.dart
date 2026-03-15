import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:chapechape_client/core/config/app_config_manager.dart';
import 'package:chapechape_client/core/config/google_auth_config.dart';
import 'package:chapechape_client/core/config/environment.dart';
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
      
      // Sauvegarder le refresh token pour la persistance
      if (response.data['refreshToken'] != null) {
        await _storage.write(key: 'refresh_token', value: response.data['refreshToken']);
      }
      
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
      // Logs limités au debug (pas en prod)
      debugPrint('Tentative de connexion');
      
      // Format attendu par l'API : email + password uniquement.
      // Ne pas envoyer rememberMe : le backend ne l'utilise pas et ça peut faire
      // échouer la connexion (validation stricte). La case reste pour usage local futur.
      final Map<String, dynamic> loginData = {
        'email': email,
        'password': password,
      };

      // Utiliser le chemin complet avec /api
      final response = await _apiService.post('/auth/login', data: loginData);

      debugPrint('Connexion réussie');
      
      final user = User.fromJson(response.data['user']);
      await _storage.write(key: 'token', value: response.data['token']);
      
      // Toujours sauvegarder le refresh token pour la persistance
      if (response.data['refreshToken'] != null) {
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
      await _storage.delete(key: 'refresh_token');
    } catch (e) {
      // Même en cas d'erreur, on supprime tous les tokens locaux
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'refresh_token');
    }
  }

  // Récupérer l'utilisateur courant
  Future<User?> getCurrentUser() async {
    try {
      final response = await _apiService.get('/auth/me');
      // ✅ CORRECTION: Utiliser response.data['user'] au lieu de response.data
      return User.fromJson(response.data['user']);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token expiré ou invalide
        await _storage.delete(key: 'token');
        return null;
      }
      throw _handleDioError(e);
    }
  }

  // Refresh automatique des tokens
  Future<bool> _refreshTokenIfNeeded() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) return false;
    
    try {
      final response = await _apiService.post('/auth/refresh-token', data: {
        'refreshToken': refreshToken,
      });
      
      // Sauvegarder les nouveaux tokens - utiliser 'token' au lieu de 'accessToken' pour cohérence
      await _storage.write(key: 'token', value: response.data['token'] ?? response.data['accessToken']);
      if (response.data['refreshToken'] != null) {
        await _storage.write(key: 'refresh_token', value: response.data['refreshToken']);
      }
      
      return true;
    } catch (e) {
      // Refresh token invalide, supprimer tous les tokens
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'refresh_token');
      return false;
    }
  }

  // Vérifier si l'utilisateur est authentifié
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: 'token');
    if (token == null) return false;
    
    try {
      // Vérifier la validité du token en appelant l'API
      final response = await _apiService.get('/auth/me');
      return response.statusCode == 200;
    } catch (e) {
      // Token expiré, essayer de le rafraîchir
      final refreshed = await _refreshTokenIfNeeded();
      if (refreshed) {
        // Réessayer avec le nouveau token
        try {
          final response = await _apiService.get('/auth/me');
          return response.statusCode == 200;
        } catch (e) {
          // Même avec le nouveau token, ça ne marche pas
          await _storage.delete(key: 'token');
          await _storage.delete(key: 'refresh_token');
          return false;
        }
      }
      
      // Pas de refresh token ou refresh échoué
      await _storage.delete(key: 'token');
      await _storage.delete(key: 'refresh_token');
      return false;
    }
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

  /// Demande d'envoi de l'email « mot de passe oublié » (backend: POST /auth/forgot-password)
  Future<void> resetPassword({required String email}) async {
    try {
      await _apiService.post('/auth/forgot-password', data: {
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
  // Connexion avec Google
  Future<User> signInWithGoogle() async {
    try {
      // En dev : Web Client ID du projet google-services.json (certificat debug).
      // En prod : Web Client ID du projet Firebase de production.
      final isProd = AppConfigManager.environment == Environment.prod;
      final serverClientId = isProd
          ? GoogleAuthConfig.webClientIdProd
          : GoogleAuthConfig.webClientIdDev;
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: serverClientId,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Connexion Google annulée par l\'utilisateur');
      }
      
      // Obtenir les détails d'authentification de la demande Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Tokens Google : ne pas logger en production (debugPrint uniquement)
      debugPrint('Google Sign-In: tokens reçus');
      
      // Créer un nouvel identifiant d'authentification Firebase à partir du token
      final firebase_auth.AuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Connecter l'utilisateur avec Firebase
      final firebase_auth.UserCredential userCredential = 
          await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);
      
      final firebase_auth.User? firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        throw Exception('Échec de l\'authentification avec Google');
      }
      
      // ✅ CORRECTION: Utiliser le token Google direct, pas Firebase
      // Le token Google original est dans googleAuth.idToken
      final String? googleIdToken = googleAuth.idToken;
      
      if (googleIdToken == null) {
        throw Exception('Token Google ID manquant');
      }
      
      // Envoyer les informations Google à notre API pour authentifier/enregistrer l'utilisateur
      final response = await _apiService.post('/auth/google', data: {
        'idToken': googleIdToken, // ← Token Google direct !
        'email': firebaseUser.email,
        'displayName': firebaseUser.displayName,
        'photoUrl': firebaseUser.photoURL,
        'uid': firebaseUser.uid
      });
      
      // Sauvegarder le token JWT de notre backend
      await _storage.write(key: 'token', value: response.data['token']);
      
      // ✅ CORRECTION: Sauvegarder aussi le refresh token pour la persistance
      if (response.data['refreshToken'] != null) {
        await _storage.write(key: 'refresh_token', value: response.data['refreshToken']);
      }
      
      return User.fromJson(response.data['user']);
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e);
      }
      rethrow;
    }
  }

  // Connexion avec Facebook
  Future<User> signInWithFacebook() async {
    try {
      // Démarrer le processus de connexion avec Facebook
      final LoginResult loginResult = await FacebookAuth.instance.login(permissions: ['email', 'public_profile']);
      
      if (loginResult.status != LoginStatus.success) {
        throw Exception('Connexion Facebook annulée ou échouée');
      }
      
      // Obtenir les informations de l'utilisateur
      final userData = await FacebookAuth.instance.getUserData(fields: 'name,email,picture');
      
      // Obtenir les crédentials pour Firebase
      final firebase_auth.OAuthCredential facebookAuthCredential = 
          firebase_auth.FacebookAuthProvider.credential(loginResult.accessToken!.token);
      
      // Connexion avec Firebase
      final firebase_auth.UserCredential userCredential = 
          await firebase_auth.FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
      
      final firebase_auth.User? firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        throw Exception('Échec de l\'authentification avec Facebook');
      }
      
      // Envoyer les informations Facebook à notre API
      final response = await _apiService.post('/auth/facebook', data: {
        'accessToken': loginResult.accessToken!.token,
        'email': firebaseUser.email ?? userData['email'],
        'displayName': firebaseUser.displayName ?? userData['name'],
        'photoUrl': firebaseUser.photoURL ?? userData['picture']['data']['url'],
        'uid': firebaseUser.uid
      });
      
      // Sauvegarder le token JWT de notre backend
      await _storage.write(key: 'token', value: response.data['token']);
      
      // ✅ CORRECTION: Sauvegarder aussi le refresh token pour la persistance
      if (response.data['refreshToken'] != null) {
        await _storage.write(key: 'refresh_token', value: response.data['refreshToken']);
      }
      
      return User.fromJson(response.data['user']);
    } catch (e) {
      if (e is DioException) {
        throw _handleDioError(e);
      }
      rethrow;
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