import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Intercepteur Dio spécialisé pour corriger les URLs d'images problématiques
/// avant qu'elles ne soient envoyées au serveur
class ImageUrlInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final originalUrl = options.uri.toString();
    
    // Corriger les URLs malformées avec https:/.domain au lieu de https://domain
    String correctedUrl = originalUrl;
    if (originalUrl.contains('https:/.') && !originalUrl.contains('https://')) {
      correctedUrl = originalUrl.replaceAll('https:/.', 'https://');
      debugPrint('🔧 Correction URL malformée: $originalUrl -> $correctedUrl');
    }
    
    // Vérifier si c'est une requête d'image avec un chemin problématique
    if (correctedUrl.contains('/uploads/images-')) {
      // Corriger l'URL en remplaçant images- par profile- et en ajoutant /profiles/
      correctedUrl = correctedUrl.replaceAll('images-', 'profile-');
      correctedUrl = correctedUrl.replaceAll('/uploads/', '/uploads/profiles/');
      
      debugPrint('🔄 Redirection d\'URL d\'image: $originalUrl -> $correctedUrl');
    }
    
    // Si l'URL a été modifiée, créer de nouvelles RequestOptions
    if (correctedUrl != originalUrl) {
      try {
        final correctedUri = Uri.parse(correctedUrl);
        final newOptions = RequestOptions(
          path: correctedUri.path,
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
          baseUrl: '${correctedUri.scheme}://${correctedUri.host}${correctedUri.port != 80 && correctedUri.port != 443 ? ':${correctedUri.port}' : ''}',
        );
        
        // Modifier les options de la requête
        options.path = correctedUri.path;
        options.baseUrl = '${correctedUri.scheme}://${correctedUri.host}${correctedUri.port != 80 && correctedUri.port != 443 ? ':${correctedUri.port}' : ''}';
        
      } catch (e) {
        debugPrint('❌ Erreur lors de la correction d\'URL: $e');
      }
    }
    
    // Continuer normalement avec les options (potentiellement modifiées)
    super.onRequest(options, handler);
  }
}
