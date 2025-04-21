/// Classe générique pour standardiser les réponses d'API
/// et faciliter la gestion des erreurs
class ApiResponse<T> {
  /// Indique si la requête a réussi
  final bool success;
  
  /// Données retournées par l'API (uniquement en cas de succès)
  final T? data;
  
  /// Message d'erreur (uniquement en cas d'échec)
  final String? message;
  
  /// Code HTTP de la réponse
  final int? statusCode;
  
  /// Indique si l'erreur est liée au réseau
  final bool isNetworkError;
  
  /// Indique si l'erreur est liée à l'authentification
  final bool isAuthError;
  
  /// Indique si les données sont en cache
  final bool isFromCache;
  
  /// Indique si la requête est mise en file d'attente pour synchronisation
  final bool isQueuedForSync;
  
  /// Identifiant unique de l'erreur (pour faciliter le débogage)
  final String? errorId;
  
  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.isNetworkError = false,
    this.isAuthError = false,
    this.isFromCache = false,
    this.isQueuedForSync = false,
    this.errorId,
  });
  
  /// Crée une réponse de succès avec les données
  factory ApiResponse.success(
    T data, {
    String? message,
    int? statusCode,
    bool isFromCache = false,
  }) {
    return ApiResponse(
      success: true,
      data: data,
      message: message ?? 'Opération réussie',
      statusCode: statusCode ?? 200,
      isFromCache: isFromCache,
    );
  }
  
  /// Crée une réponse d'erreur avec un message
  factory ApiResponse.error(
    String message, {
    int? statusCode,
    bool isNetworkError = false,
    bool isAuthError = false,
    bool isQueuedForSync = false,
  }) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
      isNetworkError: isNetworkError,
      isAuthError: isAuthError,
      isQueuedForSync: isQueuedForSync,
    );
  }
  
  /// Crée une réponse d'erreur réseau
  ApiResponse.networkError(String message)
    : data = null,
      message = message,
      statusCode = 0,
      success = false,
      isNetworkError = true,
      isAuthError = false,
      isFromCache = false,
      isQueuedForSync = false,
      errorId = null;
  
  /// Crée une réponse d'erreur d'authentification
  ApiResponse.authError(String message, {this.statusCode = 401})
    : data = null,
      message = message,
      success = false,
      isNetworkError = false,
      isAuthError = true,
      isFromCache = false,
      isQueuedForSync = false,
      errorId = null;
  
  /// Vérifie si la réponse est un échec
  bool get isError => !success;
  
  /// Récupère un message utilisateur approprié selon le type d'erreur
  String get userFriendlyMessage {
    if (success) {
      if (isFromCache) {
        return '$message (données en cache - mode hors ligne)';
      }
      return message ?? 'Opération réussie';
    } else {
      if (isQueuedForSync) {
        return 'L\'opération sera effectuée quand la connexion sera rétablie';
      } else if (isNetworkError) {
        return 'Erreur de connexion. Vérifiez votre connexion Internet';
      } else if (isAuthError) {
        return 'Session expirée. Veuillez vous reconnecter';
      }
      return message ?? 'Une erreur est survenue';
    }
  }
  
  /// Méthode d'aide pour vérifier si la réponse est en cache ou mise en file d'attente
  bool get isOfflineResponse => isFromCache || isQueuedForSync;
  
  /// Convertir en JSON pour le débogage
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.toString(),
      'message': message,
      'statusCode': statusCode,
      'isNetworkError': isNetworkError,
      'isAuthError': isAuthError,
      'isFromCache': isFromCache,
      'isQueuedForSync': isQueuedForSync,
    };
  }
  
  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, statusCode: $statusCode, isFromCache: $isFromCache, isQueuedForSync: $isQueuedForSync)';
  }
}
