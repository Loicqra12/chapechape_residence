import 'package:dio/dio.dart';
import 'dart:io';

/// Classe gérant les erreurs d'API de manière standardisée
class ApiError implements Exception {
  final String message;
  final int statusCode;
  final String errorCode;
  final dynamic data;

  ApiError({
    required this.message,
    this.statusCode = 0,
    this.errorCode = 'UNKNOWN_ERROR',
    this.data,
  });

  /// Crée une erreur à partir d'une exception Dio
  factory ApiError.fromDioError(DioException error) {
    String message = 'Une erreur est survenue';
    int statusCode = error.response?.statusCode ?? 0;
    String errorCode = 'UNKNOWN_ERROR';
    dynamic data = error.response?.data;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Délai de connexion dépassé';
        errorCode = 'CONNECTION_TIMEOUT';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Délai de réception dépassé';
        errorCode = 'RECEIVE_TIMEOUT';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Délai d\'envoi dépassé';
        errorCode = 'SEND_TIMEOUT';
        break;
      case DioExceptionType.badResponse:
        if (error.response != null) {
          statusCode = error.response!.statusCode ?? 0;
          
          if (error.response!.data is Map<String, dynamic>) {
            final responseData = error.response!.data as Map<String, dynamic>;
            message = responseData['message'] as String? ?? 'Erreur de réponse du serveur';
            errorCode = responseData['code'] as String? ?? 'SERVER_ERROR';
          } else {
            message = 'Erreur de réponse du serveur';
            errorCode = 'SERVER_ERROR';
          }
          
          switch (statusCode) {
            case 400:
              errorCode = 'BAD_REQUEST';
              message = message.isEmpty ? 'Requête invalide' : message;
              break;
            case 401:
              errorCode = 'UNAUTHORIZED';
              message = message.isEmpty ? 'Non autorisé' : message;
              break;
            case 403:
              errorCode = 'FORBIDDEN';
              message = message.isEmpty ? 'Accès interdit' : message;
              break;
            case 404:
              errorCode = 'NOT_FOUND';
              message = message.isEmpty ? 'Ressource non trouvée' : message;
              break;
            case 500:
              errorCode = 'SERVER_ERROR';
              message = message.isEmpty ? 'Erreur serveur' : message;
              break;
          }
        }
        break;
      case DioExceptionType.cancel:
        message = 'Requête annulée';
        errorCode = 'REQUEST_CANCELLED';
        break;
      case DioExceptionType.connectionError:
        message = 'Problème de connexion réseau';
        errorCode = 'NETWORK_ERROR';
        break;
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          message = 'Problème de connexion réseau';
          errorCode = 'NETWORK_ERROR';
        } else {
          message = error.error?.toString() ?? 'Erreur inconnue';
        }
        break;
      default:
        message = error.error?.toString() ?? 'Erreur inconnue';
    }

    return ApiError(
      message: message,
      statusCode: statusCode,
      errorCode: errorCode,
      data: data,
    );
  }

  /// Crée une erreur générique
  factory ApiError.generic({
    String message = 'Une erreur est survenue',
    int statusCode = 0,
    String errorCode = 'UNKNOWN_ERROR',
    dynamic data,
  }) {
    return ApiError(
      message: message,
      statusCode: statusCode,
      errorCode: errorCode,
      data: data,
    );
  }

  @override
  String toString() {
    return 'ApiError: $message (code: $errorCode, status: $statusCode)';
  }
} 