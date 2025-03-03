import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/partner/partner_model.dart';

class AuthResult {
  final String token;
  final Partner partner;

  AuthResult({required this.token, required this.partner});
}

class AuthService {
  final Dio _dio;
  final _storage = const FlutterSecureStorage();

  AuthService(this._dio);

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  Future<void> removeToken() async {
    await _storage.delete(key: 'token');
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null;
  }

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
          final user = data['user'];
          await setToken(token);
          return AuthResult(
            token: token,
            partner: Partner.fromJson(user),
          );
        } else {
          throw Exception(data['message'] ?? 'Erreur de connexion');
        }
      } else {
        throw Exception(response.data['message'] ?? 'Erreur de connexion');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Impossible de se connecter au serveur. Vérifiez votre connexion internet.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Email ou mot de passe incorrect');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Service non disponible. Veuillez réessayer plus tard.');
      } else {
        throw Exception(e.response?.data?['message'] ?? 'Une erreur est survenue');
      }
    } catch (e) {
      throw Exception('Une erreur inattendue est survenue');
    }
  }

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
          final user = data['user'];
          await setToken(token);
          return AuthResult(
            token: token,
            partner: Partner.fromJson(user),
          );
        } else {
          throw Exception(data['message'] ?? 'Erreur lors de l\'inscription');
        }
      } else {
        throw Exception(response.data['message'] ?? 'Erreur lors de l\'inscription');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Impossible de se connecter au serveur. Vérifiez votre connexion internet.');
      } else if (e.response?.statusCode == 409) {
        throw Exception('Un compte existe déjà avec cet email');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Service non disponible. Veuillez réessayer plus tard.');
      } else {
        throw Exception(e.response?.data?['message'] ?? 'Une erreur est survenue');
      }
    } catch (e) {
      throw Exception('Une erreur inattendue est survenue');
    }
  }

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
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Impossible de se connecter au serveur. Vérifiez votre connexion internet.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Service non disponible. Veuillez réessayer plus tard.');
      } else {
        throw Exception(e.response?.data?['message'] ?? 'Une erreur est survenue');
      }
    } catch (e) {
      throw Exception('Une erreur inattendue est survenue');
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      // Même si la déconnexion échoue côté serveur,
      // on supprime quand même le token localement
    } finally {
      await removeToken();
    }
  }
}
