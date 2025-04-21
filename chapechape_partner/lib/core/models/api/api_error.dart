import 'package:dio/dio.dart';

/// Classe représentant une erreur standardisée de l'API
class ApiError implements Exception {
  /// Code d'erreur HTTP (ex: 400, 401, 404, 500)
  final int? statusCode;
  
  /// Message d'erreur lisible
  final String message;
  
  /// Code d'erreur spécifique fourni par l'API
  final String? errorCode;
  
  /// Données supplémentaires associées à l'erreur
  final Map<String, dynamic>? data;
  
  /// Erreur d'origine qui a causé cette API Error
  final dynamic originalError;

  ApiError({
    this.statusCode,
    required this.message,
    this.errorCode,
    this.data,
    this.originalError,
  });

  /// Crée une instance ApiError à partir d'une DioException
  factory ApiError.fromDioError(DioException error) {
    int? statusCode = error.response?.statusCode;
    String message;
    String? errorCode;
    Map<String, dynamic>? data;

    // Extraire les informations détaillées de la réponse (si disponible)
    if (error.response != null && error.response!.data != null) {
      final responseData = error.response!.data;
      
      if (responseData is Map<String, dynamic>) {
        // Format attendu du backend: { "message": "...", "errorCode": "...", "data": {...} }
        message = responseData['message'] as String? ?? 
                 responseData['error'] as String? ?? 
                 'Une erreur est survenue';
        
        errorCode = responseData['errorCode'] as String?;
        
        // Extraire les données supplémentaires
        if (responseData['data'] != null && responseData['data'] is Map<String, dynamic>) {
          data = responseData['data'] as Map<String, dynamic>;
        }
      } else if (responseData is String) {
        message = responseData;
      } else {
        message = 'Erreur réseau non identifiée';
      }
    } else {
      // Messages d'erreur spécifiques par type d'erreur Dio
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          message = 'Délai de connexion dépassé';
          errorCode = 'CONNECTION_TIMEOUT';
          break;
        case DioExceptionType.sendTimeout:
          message = 'Délai d\'envoi dépassé';
          errorCode = 'SEND_TIMEOUT';
          break;
        case DioExceptionType.receiveTimeout:
          message = 'Délai de réception dépassé';
          errorCode = 'RECEIVE_TIMEOUT';
          break;
        case DioExceptionType.badCertificate:
          message = 'Certificat non valide';
          errorCode = 'BAD_CERTIFICATE';
          break;
        case DioExceptionType.badResponse:
          message = 'Réponse serveur invalide';
          errorCode = 'BAD_RESPONSE';
          break;
        case DioExceptionType.cancel:
          message = 'Requête annulée';
          errorCode = 'REQUEST_CANCELLED';
          break;
        case DioExceptionType.connectionError:
          message = 'Erreur de connexion réseau';
          errorCode = 'CONNECTION_ERROR';
          break;
        case DioExceptionType.unknown:
        default:
          if (error.message?.contains('SocketException') ?? false) {
            message = 'Aucune connexion internet';
            errorCode = 'NO_INTERNET';
          } else {
            message = error.message ?? 'Erreur réseau inconnue';
            errorCode = 'UNKNOWN_ERROR';
          }
          break;
      }
    }

    return ApiError(
      statusCode: statusCode,
      message: message,
      errorCode: errorCode,
      data: data,
      originalError: error,
    );
  }

  /// Crée une instance d'erreur générique
  factory ApiError.generic({String? message}) {
    return ApiError(
      statusCode: 500,
      message: message ?? 'Une erreur inattendue est survenue',
      errorCode: 'GENERIC_ERROR',
    );
  }

  /// Crée une instance pour une erreur d'authentification
  factory ApiError.unauthorized({String? message}) {
    return ApiError(
      statusCode: 401,
      message: message ?? 'Authentification requise',
      errorCode: 'UNAUTHORIZED',
    );
  }

  /// Crée une instance pour une erreur de permission
  factory ApiError.forbidden({String? message}) {
    return ApiError(
      statusCode: 403,
      message: message ?? 'Accès refusé',
      errorCode: 'FORBIDDEN',
    );
  }

  /// Crée une instance pour une ressource non trouvée
  factory ApiError.notFound({String? message}) {
    return ApiError(
      statusCode: 404,
      message: message ?? 'Ressource non trouvée',
      errorCode: 'NOT_FOUND',
    );
  }

  /// Crée une instance pour une erreur de validation
  factory ApiError.validationError({String? message, Map<String, dynamic>? validationErrors}) {
    return ApiError(
      statusCode: 422,
      message: message ?? 'Validation échouée',
      errorCode: 'VALIDATION_ERROR',
      data: validationErrors,
    );
  }

  /// Crée une instance pour une erreur de serveur
  factory ApiError.serverError({String? message}) {
    return ApiError(
      statusCode: 500,
      message: message ?? 'Erreur serveur',
      errorCode: 'SERVER_ERROR',
    );
  }

  /// Crée une instance pour une erreur de connectivité
  factory ApiError.networkError({String? message}) {
    return ApiError(
      statusCode: null,
      message: message ?? 'Erreur de connexion réseau',
      errorCode: 'NETWORK_ERROR',
    );
  }

  @override
  String toString() {
    return 'ApiError[$statusCode]: $message${errorCode != null ? ' (Code: $errorCode)' : ''}';
  }
}
