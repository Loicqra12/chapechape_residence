/// Classe générique pour standardiser les réponses d'API
/// et faciliter la gestion des erreurs
class ApiResponse<T> {
  /// Données retournées par l'API (uniquement en cas de succès)
  final T? data;
  
  /// Message d'erreur (uniquement en cas d'échec)
  final String? errorMessage;
  
  /// Code HTTP de la réponse
  final int? statusCode;
  
  /// Indique si la requête a réussi
  final bool isSuccess;
  
  /// Indique si l'erreur est liée au réseau
  final bool isNetworkError;
  
  /// Indique si l'erreur est liée à l'authentification
  final bool isAuthError;
  
  /// Identifiant unique de l'erreur (pour faciliter le débogage)
  final String? errorId;
  
  /// Crée une réponse de succès avec les données
  ApiResponse.success(this.data)
    : errorMessage = null,
      statusCode = 200,
      isSuccess = true,
      isNetworkError = false,
      isAuthError = false,
      errorId = null;
  
  /// Crée une réponse d'erreur avec un message
  ApiResponse.error(
    this.errorMessage, {
    this.statusCode,
    this.isNetworkError = false,
    this.isAuthError = false,
    this.errorId,
  }) : data = null,
       isSuccess = false;
  
  /// Crée une réponse d'erreur réseau
  ApiResponse.networkError(String message)
    : data = null,
      errorMessage = message,
      statusCode = 0,
      isSuccess = false,
      isNetworkError = true,
      isAuthError = false,
      errorId = null;
  
  /// Crée une réponse d'erreur d'authentification
  ApiResponse.authError(String message, {this.statusCode = 401})
    : data = null,
      errorMessage = message,
      isSuccess = false,
      isNetworkError = false,
      isAuthError = true,
      errorId = null;
  
  /// Vérifie si la réponse est un échec
  bool get isError => !isSuccess;
  
  /// Récupère un message utilisateur approprié selon le type d'erreur
  String get userFriendlyMessage {
    if (isSuccess) return '';
    
    if (isNetworkError) {
      return 'Problème de connexion. Vérifiez votre réseau et réessayez.';
    }
    
    if (isAuthError) {
      return 'Session expirée. Veuillez vous reconnecter.';
    }
    
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return errorMessage!;
    }
    
    return 'Une erreur inattendue s\'est produite${errorId != null ? ' (Ref: #$errorId)' : ''}.';
  }
} 