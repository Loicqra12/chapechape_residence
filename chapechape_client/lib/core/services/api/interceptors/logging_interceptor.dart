import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// Intercepteur pour gérer la journalisation des requêtes et réponses HTTP
/// Utilise PrettyDioLogger en développement pour une sortie formatée
class LoggingInterceptor {
  /// Crée et retourne l'intercepteur de journalisation approprié
  /// selon l'environnement (développement ou production)
  static Interceptor create({bool isProduction = false}) {
    // En production, utiliser un intercepteur minimal
    if (isProduction) {
      return _MinimalLoggingInterceptor();
    }
    
    // En développement, utiliser PrettyDioLogger pour une sortie détaillée et formatée
    return PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: true,
      error: true,
      compact: true,
    );
  }
}

/// Intercepteur minimal pour la production qui ne journalise que les informations essentielles
class _MinimalLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('🔄 Requête: ${options.method} ${options.path}');
    }
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('✅ Réponse: ${response.statusCode} pour ${response.requestOptions.path}');
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('❌ Erreur: ${err.type} pour ${err.requestOptions.path}');
      debugPrint('   Message: ${err.message}');
      if (err.response != null) {
        debugPrint('   Statut: ${err.response?.statusCode}');
      }
    }
    return handler.next(err);
  }
}
