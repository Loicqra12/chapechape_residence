import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:chapechape_client/core/services/connectivity_service.dart';
import 'package:chapechape_client/core/services/cache_service.dart';

/// Intercepteur Dio pour gérer les problèmes de connectivité
class ConnectivityInterceptor extends Interceptor {
  final ConnectivityService connectivityService;
  final CacheService cacheService;
  final Function(String, String, Map<String, dynamic>?, Map<String, dynamic>?)? onOfflineRequest;

  ConnectivityInterceptor({
    required this.connectivityService,
    required this.cacheService,
    this.onOfflineRequest,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Vérifier si l'appareil est connecté
    final isConnected = connectivityService.isConnected;
    
    if (!isConnected) {
      debugPrint('📱 Intercepteur de connectivité: appareil hors ligne');
      
      // Si c'est une requête GET, vérifier si nous avons des données en cache
      if (options.method == 'GET') {
        final cachedData = await cacheService.get('GET_${options.path}');
        
        if (cachedData != null) {
          debugPrint('📦 Intercepteur de connectivité: utilisation du cache pour ${options.path}');
          
          return handler.resolve(
            Response(
              requestOptions: options,
              data: cachedData,
              statusCode: 200,
              extra: {'cached': true, 'offline': true},
            ),
          );
        }
      }
      
      // Si ce n'est pas une requête GET ou pas de cache disponible,
      // ajouter à la file d'attente si une fonction de callback est fournie
      if (onOfflineRequest != null) {
        await onOfflineRequest!(
          options.method,
          options.path,
          options.data as Map<String, dynamic>?,
          options.queryParameters,
        );
        
        // Résoudre avec une réponse factice indiquant que la requête a été mise en file d'attente
        return handler.resolve(
          Response(
            requestOptions: options,
            data: {
              'message': 'Requête mise en file d\'attente pour synchronisation ultérieure',
              'queued': true,
            },
            statusCode: 200,
            extra: {'queued': true, 'offline': true},
          ),
        );
      }
      
      // Si aucune fonction de callback n'est fournie, échouer avec une erreur
      return handler.reject(
        DioException(
          requestOptions: options,
          error: 'Appareil hors ligne',
          type: DioExceptionType.connectionError,
        ),
      );
    }
    
    // Si l'appareil est connecté, continuer normalement
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // Pour les requêtes GET, mettre en cache la réponse
    if (response.requestOptions.method == 'GET' && response.statusCode == 200) {
      final path = response.requestOptions.path;
      await cacheService.put('GET_$path', response.data);
      debugPrint('💾 ConnectivityInterceptor: Mise en cache de la réponse pour $path');
    }
    
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Si l'erreur est liée à la connectivité, vérifier si nous avons des données en cache
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout) {
      
      final options = err.requestOptions;
      
      // Pour les requêtes GET, essayer de récupérer depuis le cache
      if (options.method == 'GET') {
        final cachedData = await cacheService.get('GET_${options.path}');
        if (cachedData != null) {
          debugPrint('📦 ConnectivityInterceptor: Utilisation du cache pour erreur sur ${options.path}');
          
          return handler.resolve(
            Response(
              requestOptions: options,
              data: cachedData,
              statusCode: 200,
              extra: {'cached': true, 'offline': true},
            ),
          );
        }
      }
    }
    
    // Si pas de données en cache ou autre type d'erreur, poursuivre avec l'erreur
    return handler.next(err);
  }
} 