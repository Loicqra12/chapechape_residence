import 'dart:io';
import 'package:dio/dio.dart';

/// Mappe les erreurs techniques vers des messages utilisateur compréhensibles
class ErrorMapper {
  /// Convertit une erreur Dio en message utilisateur
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
          case 502:
          case 503:
          case 504:
            return 'Le serveur rencontre des difficultés. Veuillez réessayer plus tard.';
          default:
            return 'Une erreur est survenue. Veuillez réessayer.';
        }
      
      case DioExceptionType.cancel:
        return 'La requête a été annulée.';
      
      case DioExceptionType.unknown:
      default:
        if (error.error is SocketException || error.message?.contains('SocketException') == true) {
          return 'Problème de connexion Internet. Vérifiez votre connexion réseau.';
        }
        return 'Une erreur de connexion est survenue. Vérifiez votre Internet et réessayez.';
    }
  }

  /// Convertit une erreur générique en message contextuel
  static String mapGenericError(dynamic error, String context) {
    if (error is DioException) {
      return mapDioError(error);
    }

    // Messages contextuels selon le contexte de l'erreur
    final errorMessage = error.toString().toLowerCase();
    
    switch (context) {
      case 'login':
        if (errorMessage.contains('password') || errorMessage.contains('mot de passe')) {
          return 'Email ou mot de passe incorrect. Vérifiez vos identifiants.';
        }
        if (errorMessage.contains('email') || errorMessage.contains('utilisateur')) {
          return 'Cet email n\'est pas enregistré. Vérifiez votre adresse email.';
        }
        return 'Impossible de se connecter. Vérifiez vos identifiants et réessayez.';
      
      case 'register':
        if (errorMessage.contains('email') && errorMessage.contains('existe')) {
          return 'Cet email est déjà utilisé. Connectez-vous ou utilisez un autre email.';
        }
        if (errorMessage.contains('password') || errorMessage.contains('mot de passe')) {
          return 'Le mot de passe ne respecte pas les critères requis.';
        }
        return 'Impossible de créer le compte. Vérifiez vos informations et réessayez.';
      
      case 'booking':
        if (errorMessage.contains('disponible') || errorMessage.contains('available')) {
          return 'Ces dates ne sont pas disponibles. Essayez d\'autres dates.';
        }
        if (errorMessage.contains('date') || errorMessage.contains('passé')) {
          return 'Les dates sélectionnées ne sont pas valides.';
        }
        return 'Impossible de créer la réservation. Vérifiez les dates et réessayez.';
      
      case 'payment':
        if (errorMessage.contains('expiré') || errorMessage.contains('expired')) {
          return 'Le délai de paiement a expiré. Veuillez créer une nouvelle réservation.';
        }
        if (errorMessage.contains('solde') || errorMessage.contains('insufficient')) {
          return 'Solde insuffisant. Vérifiez votre compte.';
        }
        return 'Le paiement a échoué. Vérifiez vos informations de paiement et réessayez.';
      
      case 'cache_clear':
        return 'Impossible de vider le cache. Réessayez plus tard.';
      
      case 'profile_update':
        if (errorMessage.contains('email')) {
          return 'Cet email est déjà utilisé par un autre compte.';
        }
        return 'Impossible de mettre à jour le profil. Vérifiez vos informations et réessayez.';
      
      case 'network':
        return 'Problème de connexion Internet. Vérifiez votre connexion réseau.';
      
      default:
        return 'Une erreur est survenue. Veuillez réessayer.';
    }
  }

  /// Obtient un titre d'erreur selon le type
  static String getErrorTitle(String context) {
    switch (context) {
      case 'login':
        return 'Erreur de connexion';
      case 'register':
        return 'Erreur d\'inscription';
      case 'booking':
        return 'Erreur de réservation';
      case 'payment':
        return 'Erreur de paiement';
      case 'profile_update':
        return 'Erreur de mise à jour';
      default:
        return 'Erreur';
    }
  }
}

