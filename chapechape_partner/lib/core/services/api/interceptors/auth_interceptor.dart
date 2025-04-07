import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/auth/auth_bloc.dart';

/// Intercepteur pour gérer les tokens d'authentification et leur expiration
class AuthInterceptor extends Interceptor {
  final Dio dio;
  final FlutterSecureStorage storage;
  final AuthBloc? authBloc;

  AuthInterceptor({
    required this.dio, 
    required this.storage, 
    this.authBloc,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Ajouter le token s'il existe
    final token = await storage.read(key: 'token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
      
      // Log sécurisé: ne montre que le début et la fin du token
      final maskedToken = _maskToken(token);
      print('🔐 Token ajouté à la requête: $maskedToken');
    }
    
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Détecter les erreurs d'authentification (token expiré)
    if (err.response?.statusCode == 401) {
      print('⚠️ Erreur 401: Token expiré ou invalide');
      
      // Supprimer le token invalide
      await storage.delete(key: 'token');
      
      // Si un bloc d'authentification est fourni, déclencher la déconnexion
      if (authBloc != null) {
        print('🔄 Déconnexion automatique suite à un token expiré');
        authBloc!.add(AuthLogoutRequested());
      }
    }
    
    // Continuer avec la gestion d'erreur standard
    return handler.next(err);
  }
  
  // Masquer le token pour les logs (sécurité)
  String _maskToken(String token) {
    if (token.length <= 8) return '****';
    return '${token.substring(0, 4)}...${token.substring(token.length - 4)}';
  }
} 