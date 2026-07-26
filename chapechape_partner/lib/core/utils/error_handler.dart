import 'package:dio/dio.dart';
import '../exceptions/api_exception.dart';
import 'package:chapechape_partner/core/utils/app_logger.dart';

/// Gestionnaire d'erreurs centralisé pour traiter les erreurs API
class ErrorHandler {
  /// Traite une erreur et la convertit en ApiException
  static ApiException handleError(dynamic error) {
    // Si c'est déjà une ApiException, la retourner directement
    if (error is ApiException) {
      return error;
    }
    
    // Traiter les erreurs Dio
    if (error is DioException) {
      final response = error.response;
      
      // Erreur avec réponse du serveur
      if (response != null) {
        final statusCode = response.statusCode ?? 0;
        Map<String, dynamic> data;
        
        try {
          data = response.data is Map<String, dynamic> 
              ? response.data as Map<String, dynamic> 
              : {'message': 'Erreur inconnue'};
        } catch (e) {
          data = {'message': 'Erreur inconnue', 'error': e.toString()};
        }
        
        final message = _getErrorMessage(statusCode, data);
        AppLogger.d('🔴 Erreur API: $message (Code: $statusCode)');
        return ApiException(message, statusCode, data);
      }
      
      // Erreur réseau
      if (error.type == DioExceptionType.connectionError || 
          error.type == DioExceptionType.connectionTimeout) {
        AppLogger.d('🔴 Erreur réseau: ${error.message}');
        return ApiException(
          'Impossible de se connecter au serveur. Vérifiez votre connexion.',
          0,
          {'error': error.message ?? 'Network error'},
        );
      }
    }
    
    // Erreur générique (message sobre, pas technique)
    AppLogger.d('🔴 Erreur non gérée: $error');
    return ApiException(
      'Un problème est survenu. Réessayez.',
      500,
      {'error': error.toString()},
    );
  }

  /// Récupère un message d'erreur adapté selon le code de statut (UX type grandes apps)
  static String _getErrorMessage(int statusCode, Map<String, dynamic> data) {
    final defaultMessage = data['message'] as String? ?? 'Une erreur est survenue';
    final hasCustomMessage = defaultMessage.isNotEmpty && defaultMessage != 'Une erreur est survenue';

    switch (statusCode) {
      case 400:
        return hasCustomMessage ? defaultMessage : 'Requête invalide';
      case 401:
        // Connexion : afficher le message du serveur (ex. "Email ou mot de passe incorrect")
        return hasCustomMessage ? defaultMessage : 'Session expirée. Reconnectez-vous.';
      case 403:
        return hasCustomMessage ? defaultMessage : 'Accès refusé';
      case 404:
        return hasCustomMessage ? defaultMessage : 'Ressource non trouvée';
      case 409:
        return hasCustomMessage ? defaultMessage : 'Conflit';
      case 422:
        return hasCustomMessage ? defaultMessage : 'Données invalides';
      case 429:
        return 'Trop de requêtes. Réessayez dans un moment.';
      case 500:
      case 502:
      case 503:
        return 'Connexion impossible pour le moment. Réessayez dans un instant.';
      case 504:
        return 'Réponse trop lente. Réessayez dans un instant.';
      default:
        return defaultMessage;
    }
  }
} 