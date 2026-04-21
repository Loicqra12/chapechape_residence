import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Intercepteur Dio pour les tentatives automatiques en cas d'échec de requête
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration initialDelay;
  final double backoffFactor;
  final Duration maxDelay;

  int _retryCount = 0;
  
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.backoffFactor = 1.5,
    this.maxDelay = const Duration(seconds: 30),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Ne pas retenter si l'erreur n'est pas récupérable
    if (!_isRecoverableError(err) || _retryCount >= maxRetries) {
      if (_retryCount > 0) {
        debugPrint('❌ RetryInterceptor: Nombre maximum de tentatives atteint (${_retryCount}/${maxRetries})');
        _retryCount = 0; // Réinitialiser pour les futures requêtes
      }
      return handler.next(err);
    }
    
    _retryCount++;
    
    // Calculer le délai avant de réessayer avec backoff exponentiel
    final delayMs = initialDelay.inMilliseconds * (backoffFactor * (_retryCount - 1)).round();
    final currentDelay = Duration(milliseconds: delayMs > maxDelay.inMilliseconds ? maxDelay.inMilliseconds : delayMs);
    
    debugPrint('🔄 RetryInterceptor: Tentative #$_retryCount/$maxRetries - Attente de ${currentDelay.inMilliseconds}ms');
    
    // Attendre avant de réessayer
    await Future.delayed(currentDelay);
    
    try {
      // Tenter une nouvelle requête avec les mêmes options
      final response = await dio.fetch(err.requestOptions);
      
      // En cas de succès, réinitialiser le compteur et résoudre avec la réponse
      _retryCount = 0;
      handler.resolve(response);
    } catch (e) {
      // Si la nouvelle tentative échoue, continuer avec l'erreur
      handler.next(err);
    }
  }
  
  /// Détermine si une erreur est récupérable (peut être résolue par une nouvelle tentative)
  bool _isRecoverableError(DioException err) {
    // Erreurs réseau - généralement récupérables
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return true;
    }
    
    // Erreurs serveur potentiellement récupérables
    if (err.response != null) {
      final statusCode = err.response!.statusCode ?? 0;
      
      // 429 : ne pas retenter (multiplie les hits sur le rate limit serveur)
      if (statusCode == 429) return false;

      // 500, 502, 503, 504 - erreurs serveur récupérables
      if (statusCode == 500 || statusCode == 502 || 
          statusCode == 503 || statusCode == 504) return true;
    }
    
    // Par défaut, considérer comme non récupérable
    return false;
  }
} 