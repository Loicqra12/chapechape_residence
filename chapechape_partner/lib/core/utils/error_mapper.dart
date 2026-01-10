import 'package:dio/dio.dart';

/// Mappe les erreurs techniques en messages utilisateurs contextuels
class ErrorMapper {
  /// Mappe les erreurs Dio en messages utilisateurs
  static String mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'La connexion est trop lente. Vérifiez votre connexion Internet et réessayez.';
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        switch (statusCode) {
          case 400:
            return 'Requête invalide. Vérifiez les informations saisies.';
          case 401:
            return 'Votre session a expiré. Veuillez vous reconnecter.';
          case 403:
            return 'Vous n\'avez pas l\'autorisation d\'effectuer cette action.';
          case 404:
            return 'Cette ressource n\'existe plus ou a été déplacée.';
          case 409:
            return 'Un conflit est survenu. Cette action n\'est peut-être plus disponible.';
          case 422:
            return 'Les données fournies ne sont pas valides. Vérifiez vos informations.';
          case 429:
            return 'Trop de tentatives. Veuillez patienter quelques instants avant de réessayer.';
          case 500:
            return 'Une erreur interne du serveur est survenue. Veuillez réessayer plus tard.';
          case 502:
            return 'Le serveur est temporairement indisponible. Veuillez réessayer.';
          case 503:
            return 'Le service est actuellement indisponible. Veuillez réessayer plus tard.';
          case 504:
            return 'Le serveur n\'a pas répondu à temps. Vérifiez votre connexion.';
          default:
            return 'Une erreur est survenue (${statusCode ?? 'inconnu'}). Veuillez réessayer.';
        }
      
      case DioExceptionType.cancel:
        return 'La requête a été annulée.';
      
      case DioExceptionType.badCertificate:
        return 'Le certificat SSL n\'est pas valide. Contactez le support.';
      
      case DioExceptionType.connectionError:
        return 'Impossible de se connecter au serveur. Vérifiez votre connexion Internet.';
      
      case DioExceptionType.unknown:
      default:
        return 'Une erreur inattendue est survenue. Veuillez réessayer.';
    }
  }

  /// Mappe une erreur générique en message utilisateur
  static String mapGenericError(dynamic error, String contextType) {
    if (error is DioException) {
      return mapDioError(error);
    } else if (error is String) {
      return error;
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  /// Retourne le titre de l'erreur en fonction du contexte
  static String getErrorTitle(String contextType) {
    switch (contextType) {
      case 'login':
        return 'Erreur de connexion';
      case 'register':
        return 'Erreur d\'inscription';
      case 'profile_update':
        return 'Erreur de mise à jour du profil';
      case 'residence_create':
        return 'Erreur de création de résidence';
      case 'residence_update':
        return 'Erreur de mise à jour de résidence';
      case 'residence_delete':
        return 'Erreur de suppression de résidence';
      case 'reservation_approve':
        return 'Erreur d\'approbation de réservation';
      case 'reservation_reject':
        return 'Erreur de rejet de réservation';
      case 'reservation_cancel':
        return 'Erreur d\'annulation de réservation';
      case 'payment':
        return 'Erreur de paiement';
      case 'payout':
        return 'Erreur de reversement';
      case 'message_send':
        return 'Erreur d\'envoi de message';
      case 'notification':
        return 'Erreur de notification';
      case 'network':
        return 'Problème de connexion';
      case 'cache_clear':
        return 'Erreur de cache';
      case 'file_upload':
        return 'Erreur d\'envoi de fichier';
      case 'availability_update':
        return 'Erreur de mise à jour de disponibilité';
      case 'pricing_update':
        return 'Erreur de mise à jour des tarifs';
      case 'promotion_create':
        return 'Erreur de création de promotion';
      case 'promotion_update':
        return 'Erreur de mise à jour de promotion';
      default:
        return 'Erreur';
    }
  }

  /// Retourne des conseils d'action en fonction du contexte et du code d'erreur
  static String? getActionAdvice(String contextType, dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      
      // Conseils spécifiques selon le contexte et le code
      if (statusCode == 401) {
        return 'Reconnectez-vous pour continuer.';
      }
      
      if (statusCode == 422) {
        switch (contextType) {
          case 'residence_create':
          case 'residence_update':
            return 'Vérifiez que tous les champs obligatoires sont remplis et que les images sont valides.';
          case 'profile_update':
            return 'Vérifiez que votre email et numéro de téléphone sont valides.';
          case 'reservation_approve':
            return 'Vérifiez que la résidence est disponible pour ces dates.';
        }
      }
      
      if (statusCode == null || statusCode >= 500) {
        return 'Nos serveurs rencontrent des difficultés. Veuillez réessayer dans quelques instants.';
      }
    }
    
    return null;
  }
}

