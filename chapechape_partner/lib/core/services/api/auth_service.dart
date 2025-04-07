import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../../models/partner/partner_model.dart';
import '../../models/auth/token_info.dart';
import '../../utils/error_handler.dart';

class AuthResult {
  final String token;
  final String? refreshToken;
  final Partner partner;

  AuthResult({
    required this.token, 
    this.refreshToken,
    required this.partner
  });
}

class AuthService {
  final Dio _dio;
  final _storage = const FlutterSecureStorage();
  
  // Clés de stockage
  static const String _tokenKey = 'token';
  static const String _tokenExpiryKey = 'token_expiry';

  AuthService(this._dio);

  // Méthodes améliorées pour la gestion des tokens

  /// Récupère le token en vérifiant sa validité
  Future<String?> getToken() async {
    try {
      final tokenInfo = await getTokenInfo();
      if (tokenInfo == null) {
        return null;
      }
      
      // Vérifier si le token est expiré
      if (tokenInfo.isExpired) {
        print('⚠️ Token expiré (expiré le ${tokenInfo.expiresAt.toLocal()})');
        await removeToken();
        return null;
      }
      
      return tokenInfo.token;
    } catch (e) {
      print('❌ Erreur lors de la récupération du token: $e');
      return null;
    }
  }

  /// Stocke le token avec sa date d'expiration
  Future<void> setToken(String token, {int expiryDays = 30}) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      
      // Définir une date d'expiration (30 jours par défaut)
      final expiryDate = DateTime.now().add(Duration(days: expiryDays));
      await _storage.write(key: _tokenExpiryKey, value: expiryDate.toIso8601String());
      
      print('✅ Token stocké (expire le ${expiryDate.toLocal()})');
    } catch (e) {
      print('❌ Erreur lors du stockage du token: $e');
    }
  }

  /// Supprime le token et les données associées
  Future<void> removeToken() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _tokenExpiryKey);
      print('🗑️ Token supprimé');
    } catch (e) {
      print('❌ Erreur lors de la suppression du token: $e');
    }
  }

  /// Récupère les informations complètes du token
  Future<TokenInfo?> getTokenInfo() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      final expiryStr = await _storage.read(key: _tokenExpiryKey);
      
      if (token == null || expiryStr == null) {
        return null;
      }
      
      final expiryDate = DateTime.parse(expiryStr);
      return TokenInfo(token: token, expiresAt: expiryDate);
    } catch (e) {
      print('❌ Erreur lors de la récupération des infos du token: $e');
      return null;
    }
  }

  /// Vérifie si un token valide existe
  Future<bool> hasToken() async {
    try {
      final tokenInfo = await getTokenInfo();
      if (tokenInfo == null) {
        return false;
      }
      return !tokenInfo.isExpired;
    } catch (e) {
      print('❌ Erreur lors de la vérification du token: $e');
      return false;
    }
  }

  // Masquer le token pour les logs
  String _maskToken(String token) {
    if (token.length <= 8) return '****';
    return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
  }

  // Méthodes d'authentification existantes - adaptées pour utiliser la nouvelle gestion de token

  /// Connecte un utilisateur avec son email et mot de passe
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final token = data['token'];
          final refreshToken = data['refreshToken'];
          final user = data['user'];
          
          // Enregistrer les tokens
          await setToken(token);
          if (refreshToken != null) {
            await _storage.write(key: 'refresh_token', value: refreshToken);
            // Stocker la date d'expiration (24h par défaut)
            final expiryDate = DateTime.now().add(Duration(hours: 24));
            await _storage.write(key: 'token_expiry', value: expiryDate.toIso8601String());
          }
          
          return AuthResult(
            token: token,
            refreshToken: refreshToken,
            partner: Partner.fromJson(user),
          );
        } else {
          throw Exception(data['message'] ?? 'Erreur de connexion');
        }
      } else {
        throw Exception(response.data['message'] ?? 'Erreur de connexion');
      }
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  /// Inscrit un nouveau partenaire
  Future<AuthResult> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phoneNumber': phoneNumber,
          'password': password,
        },
      );

      if (response.statusCode == 201) {
        final data = response.data;
        if (data['success'] == true) {
          final token = data['token'];
          final refreshToken = data['refreshToken'];
          final user = data['user'];
          
          // Enregistrer les tokens
          await setToken(token);
          if (refreshToken != null) {
            await _storage.write(key: 'refresh_token', value: refreshToken);
            // Stocker la date d'expiration (24h par défaut)
            final expiryDate = DateTime.now().add(Duration(hours: 24));
            await _storage.write(key: 'token_expiry', value: expiryDate.toIso8601String());
          }
          
          return AuthResult(
            token: token,
            refreshToken: refreshToken,
            partner: Partner.fromJson(user),
          );
        } else {
          throw Exception(data['message'] ?? 'Erreur lors de l\'inscription');
        }
      } else {
        throw Exception(response.data['message'] ?? 'Erreur lors de l\'inscription');
      }
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  /// Récupère le profil du partenaire connecté
  Future<Partner> getProfile() async {
    try {
      final response = await _dio.get('/auth/me');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final user = data['user'];
          return Partner.fromJson(user);
        } else {
          throw Exception(data['message'] ?? 'Erreur lors de la récupération du profil');
        }
      } else {
        throw Exception(response.data['message'] ?? 'Erreur lors de la récupération du profil');
      }
    } catch (e) {
      // Utiliser le gestionnaire d'erreurs centralisé
      throw ErrorHandler.handleError(e);
    }
  }

  /// Met à jour le profil du partenaire
  Future<Partner> updateProfile(Map<String, dynamic> userData) async {
    try {
      print('Mise à jour du profil avec les données: $userData');
      
      final response = await _dio.put(
        '/partners/profile',
        data: userData,
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final updatedUser = data['data'] ?? data['user'];
          print('Profil mis à jour avec succès');
          return Partner.fromJson(updatedUser);
        } else {
          throw Exception(data['message'] ?? 'Erreur lors de la mise à jour du profil');
        }
      } else {
        throw Exception(response.data['message'] ?? 'Erreur lors de la mise à jour du profil');
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du profil: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  /// Déconnecte l'utilisateur
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      print('⚠️ Erreur lors de la déconnexion: $e');
    } finally {
      // Toujours supprimer le token localement même si la déconnexion échoue
      await removeToken();
    }
  }
}
