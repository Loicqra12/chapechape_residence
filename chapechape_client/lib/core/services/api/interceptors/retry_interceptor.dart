import 'dart:io';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor qui implémente une stratégie de retry avec backoff exponentiel
/// pour les erreurs réseau, en particulier les erreurs 429 (rate limit).
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration initialDelay;
  final Duration maxDelay;
  final List<int> retryStatusCodes;

  /// Constructeur avec des valeurs par défaut
  /// [dio] : Instance Dio pour réexécuter les requêtes
  /// [maxRetries] : Nombre maximum de tentatives (3 par défaut)
  /// [initialDelay] : Délai initial entre les tentatives (500ms par défaut)
  /// [maxDelay] : Délai maximum entre les tentatives (30s par défaut)
  /// [retryStatusCodes] : Codes de statut HTTP qui déclenchent un retry
  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 30),
    this.retryStatusCodes = const [408, 429, 500, 502, 503, 504],
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Récupérer les retries déjà effectués via l'en-tête personnalisé
    final options = err.requestOptions;
    final retriesHeader = options.headers['x-retries'];
    final int retries = retriesHeader != null ? int.parse(retriesHeader.toString()) : 0;

    // Vérifier si la requête peut être retentée
    if (_shouldRetry(err, retries)) {
      try {
        // Calculer le délai avec backoff exponentiel
        final delay = _calculateBackoffDelay(retries);
        
        debugPrint('🔄 Retry ${retries + 1}/$maxRetries pour ${options.path} après ${delay.inMilliseconds}ms (erreur: ${err.type})');
        
        // Attendre le délai calculé
        await Future.delayed(delay);
        
        // Incrémenter le compteur de retries
        options.headers['x-retries'] = (retries + 1).toString();
        
        // Réexécuter la requête
        final response = await dio.fetch(options);
        
        // En cas de succès, passer la réponse au handler
        debugPrint('✅ Retry réussi pour ${options.path} après ${retries + 1} tentative(s)');
        return handler.resolve(response);
      } catch (e) {
        // En cas d'échec, continuer avec l'erreur
        debugPrint('❌ Retry échoué pour ${options.path}: $e');
        return handler.next(err);
      }
    }
    
    // Si on ne peut pas retry, passer l'erreur au handler suivant
    return handler.next(err);
  }

  /// Détermine si la requête doit être retentée en fonction de l'erreur et du nombre de tentatives
  bool _shouldRetry(DioException err, int retries) {
    // Ne pas dépasser le nombre maximum de tentatives
    if (retries >= maxRetries) {
      return false;
    }
    
    // Vérifier si l'erreur est due à une connexion réseau
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return true;
    }
    
    // Vérifier si l'erreur est due à une perte de connexion
    if (err.error is SocketException) {
      return true;
    }
    
    // Vérifier les codes de statut HTTP spécifiques
    if (err.response != null) {
      return retryStatusCodes.contains(err.response!.statusCode);
    }
    
    return false;
  }

  /// Calcule le délai de backoff exponentiel avec jitter
  Duration _calculateBackoffDelay(int retries) {
    // Formule de backoff exponentiel: délai = délai_initial * (2^tentative)
    final exponentialDelay = initialDelay.inMilliseconds * math.pow(2, retries);
    
    // Ajouter un jitter (± 20%) pour éviter les tempêtes de requêtes
    final random = math.Random();
    final jitterFactor = 0.8 + (random.nextDouble() * 0.4); // Entre 0.8 et 1.2
    
    // Calculer le délai final avec jitter, en respectant le délai maximum
    final delayWithJitter = (exponentialDelay * jitterFactor).toInt();
    final finalDelay = math.min(delayWithJitter, maxDelay.inMilliseconds);
    
    return Duration(milliseconds: finalDelay);
  }
}
