import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Intercepteur Dio spécialisé pour corriger les URLs d'images problématiques
/// avant qu'elles ne soient envoyées au serveur
class ImageUrlInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final originalUrl = options.uri.toString();
    
    // Vérifier si c'est une requête d'image avec un chemin problématique
    if (originalUrl.contains('/uploads/images-')) {
      // Corriger l'URL en remplaçant images- par profile- et en ajoutant /profiles/
      String correctedUrl = originalUrl.replaceAll('images-', 'profile-');
      correctedUrl = correctedUrl.replaceAll('/uploads/', '/uploads/profiles/');
      
      debugPrint('🔄 Redirection d\'URL d\'image: $originalUrl -> $correctedUrl');
      
      // Créer de nouvelles RequestOptions avec l'URL corrigée
      // car uri est une propriété finale dans RequestOptions
      final newOptions = RequestOptions(
        path: Uri.parse(correctedUrl).path,
        method: options.method,
        sendTimeout: options.sendTimeout,
        receiveTimeout: options.receiveTimeout,
        extra: options.extra,
        headers: options.headers,
        responseType: options.responseType,
        contentType: options.contentType,
        validateStatus: options.validateStatus,
        receiveDataWhenStatusError: options.receiveDataWhenStatusError,
        followRedirects: options.followRedirects,
        maxRedirects: options.maxRedirects,
        requestEncoder: options.requestEncoder,
        responseDecoder: options.responseDecoder,
        listFormat: options.listFormat,
        baseUrl: options.baseUrl,
      );
      
      // Utiliser les nouvelles options
      return handler.resolve(
        Response(
          requestOptions: newOptions,
          statusCode: 200,
          redirects: [],
        )
      );
    }
    
    // Continuer normalement pour les autres requêtes
    super.onRequest(options, handler);
  }
}
