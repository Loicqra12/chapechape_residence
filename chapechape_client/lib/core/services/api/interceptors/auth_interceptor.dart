import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Intercepteur pour gérer l'authentification et le rafraîchissement automatique des tokens
class AuthInterceptor extends Interceptor {
  final Dio dio;
  final FlutterSecureStorage storage;

  AuthInterceptor({
    required this.dio,
    required this.storage,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Ajouter le token d'accès à chaque requête qui le nécessite
    if (options.extra['requiresAuth'] != false) {
      final token = await storage.read(key: 'token');
      
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        
        // Log sécurisé avec masquage partiel du token
        debugPrint('🔐 Token ajouté à la requête: ${_maskToken(token)}');
      } else {
        debugPrint('⚠️ Aucun token trouvé pour authentifier la requête');
      }
    }
    
    return handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Gestion des erreurs 401 (token expiré)
    if (err.response?.statusCode == 401) {
      debugPrint('⚠️ Erreur 401: Token expiré ou invalide');
      
      // Tentative de rafraîchissement du token
      final refreshed = await refreshToken();
      
      if (refreshed) {
        // Récupérer la requête originale
        final requestOptions = err.requestOptions;
        
        // Correction: utiliser 'token' au lieu de 'access_token'
        final newToken = await storage.read(key: 'token');
        
        if (newToken != null) {
          requestOptions.headers['Authorization'] = 'Bearer $newToken';
          
          debugPrint('🔄 Requête réessayée avec un nouveau token');
          
          // Réessayer la requête originale avec le nouveau token
          try {
            final retryResponse = await dio.fetch(requestOptions);
            return handler.resolve(retryResponse);
          } catch (e) {
            debugPrint('❌ Échec de la nouvelle tentative: $e');
            return handler.reject(err);
          }
        }
      }
    }
    
    // Si le rafraîchissement a échoué ou pour les autres erreurs
    return handler.next(err);
  }

  /// Tente de rafraîchir le token d'accès en utilisant le token de rafraîchissement
  /// Cette méthode est publique pour permettre son utilisation par d'autres classes
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await storage.read(key: 'refresh_token');
      
      if (refreshToken == null) {
        debugPrint('Aucun token de rafraîchissement disponible');
        return false;
      }
      
      // Créer un nouveau Dio sans intercepteurs pour éviter une boucle infinie
      final tokenDio = Dio(BaseOptions(
        baseUrl: dio.options.baseUrl,
        headers: {'Content-Type': 'application/json'},
      ));
      
      final response = await tokenDio.post(
        '/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final raw = response.data;
        final Map<String, dynamic> data = raw is Map<String, dynamic>
            ? raw
            : Map<String, dynamic>.from(raw as Map);
        // Backend: accessToken (+ refreshToken) — aligné avec AuthService._refreshTokenIfNeeded
        final access = data['token'] ?? data['accessToken'];

        if (access != null && access is String && access.isNotEmpty) {
          await storage.write(key: 'token', value: access);

          if (data['refreshToken'] != null) {
            await storage.write(
                key: 'refresh_token', value: data['refreshToken'] as String);
          }

          debugPrint('Token rafraîchi avec succès');
          return true;
        }
      }

      debugPrint(
          'Échec du rafraîchissement du token: HTTP ${response.statusCode}, corps sans token/accessToken');
      return false;
    } catch (e) {
      debugPrint('Erreur lors du rafraîchissement du token: $e');
      return false;
    }
  }
  
  // Masquer le token pour les logs (sécurité)
  String _maskToken(String token) {
    if (token.length <= 8) return '****';
    return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
  }
}
