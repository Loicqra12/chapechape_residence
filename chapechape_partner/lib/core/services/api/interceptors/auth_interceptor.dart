import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_event.dart';
import 'package:chapechape_partner/core/utils/app_logger.dart';

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
    // Exclure les endpoints qui n'ont pas besoin d'authentification
    final excludedPaths = [
      '/auth/login',
      '/auth/register',
      '/auth/register-partner',
      '/auth/forgot-password',
      '/auth/reset-password',
      '/auth/refresh-token',
    ];
    
    final isExcluded = excludedPaths.any((path) => options.path.contains(path));

    if (!isExcluded) {
      final token = await storage.read(key: 'token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Détecter les erreurs d'authentification (token expiré)
    if (err.response?.statusCode == 401) {
      AppLogger.d('⚠️ Erreur 401: Token expiré ou invalide');
      
      // Supprimer le token invalide
      await storage.delete(key: 'token');
      
      // Si un bloc d'authentification est fourni, déclencher la déconnexion
      if (authBloc != null) {
        AppLogger.d('🔄 Déconnexion automatique suite à un token expiré');
        authBloc!.add(AuthLogoutRequested());
      }
    }
    
    // Continuer avec la gestion d'erreur standard
    return handler.next(err);
  }
}
