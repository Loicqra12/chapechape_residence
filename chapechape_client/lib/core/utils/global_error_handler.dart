import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:chapechape_client/core/errors/api_error.dart';
import 'package:chapechape_client/core/utils/logger.dart';

/// Gestionnaire d'erreurs global pour l'application
class GlobalErrorHandler {
  static final GlobalErrorHandler _instance = GlobalErrorHandler._internal();
  factory GlobalErrorHandler() => _instance;
  GlobalErrorHandler._internal();

  // Logger pour enregistrer les erreurs
  final logger = AppLogger('GlobalErrorHandler');

  /// Traite une erreur et renvoie un message d'erreur convivial
  String handleError(dynamic error) {
    // Enregistrer l'erreur dans les logs
    logger.error('Erreur capturée', error);

    // Si c'est déjà une ApiError, utiliser son message
    if (error is ApiError) {
      return error.message;
    }

    // Traiter les erreurs Dio
    if (error is DioException) {
      return _handleDioError(error);
    }

    // Traiter les erreurs génériques
    if (error is Exception || error is Error) {
      return _handleGenericError(error);
    }

    // Message par défaut
    return 'Une erreur inattendue est survenue';
  }

  /// Traite une erreur Dio et renvoie un message d'erreur approprié
  String _handleDioError(DioException error) {
    // Utiliser la classe ApiError qui sait déjà comment traiter les erreurs Dio
    final apiError = ApiError.fromDioError(error);
    return apiError.message;
  }

  /// Traite une erreur générique et renvoie un message d'erreur
  String _handleGenericError(dynamic error) {
    String message;

    if (error.toString().contains('SocketException')) {
      message = 'Problème de connexion réseau. Vérifiez votre connexion internet.';
    } else if (error.toString().contains('timeout')) {
      message = 'La connexion a expiré. Veuillez réessayer.';
    } else {
      message = 'Une erreur est survenue: ${error.toString()}';
    }

    return message;
  }

  /// Affiche une boîte de dialogue d'erreur
  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Affiche un snackbar d'erreur
  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
} 