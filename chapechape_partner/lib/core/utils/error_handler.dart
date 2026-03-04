import 'package:dio/dio.dart';
import '../exceptions/api_exception.dart';

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
        print('🔴 Erreur API: $message (Code: $statusCode)');
        return ApiException(message, statusCode, data);
      }
      
      // Erreur réseau
      if (error.type == DioExceptionType.connectionError || 
          error.type == DioExceptionType.connectionTimeout) {
        print('🔴 Erreur réseau: ${error.message}');
        return ApiException(
          'Impossible de se connecter au serveur. Vérifiez votre connexion.',
          0,
          {'error': error.message ?? 'Network error'},
        );
      }
    }
    
    // Erreur générique
    print('🔴 Erreur non gérée: $error');
    return ApiException(
      'Une erreur inattendue est survenue',
      500,
      {'error': error.toString()},
    );
  }

  /// Récupère un message d'erreur adapté selon le code de statut
  static String _getErrorMessage(int statusCode, Map<String, dynamic> data) {
    final defaultMessage = data['message'] as String? ?? 'Une erreur est survenue';
    
    switch (statusCode) {
      case 400:
        return 'Requête invalide: $defaultMessage';
      case 401:
        return 'Session expirée: Veuillez vous reconnecter';
      case 403:
        return 'Accès refusé: Vous n\'avez pas les permissions nécessaires';
      case 404:
        return 'Ressource non trouvée: $defaultMessage';
      case 409:
        return 'Conflit: $defaultMessage';
      case 422:
        return 'Données invalides: $defaultMessage';
      case 429:
        return 'Trop de requêtes: Veuillez réessayer plus tard';
      case 500:
      case 502:
      case 503:
        return 'Erreur serveur: Veuillez réessayer plus tard';
      case 504:
        return 'Le serveur met trop de temps à répondre. Réessayez dans un instant.';
      default:
        return defaultMessage;
    }
  }
} 