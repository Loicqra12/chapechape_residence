/// Classe générique pour standardiser les réponses d'API
class ApiResponse<T> {
  final T? data;
  final String? message;
  final bool success;
  final int? statusCode;
  final bool isNetworkError;
  final bool isAuthError;
  final bool isFromCache;
  final bool isQueuedForSync;

  ApiResponse({
    this.data,
    this.message,
    required this.success,
    this.statusCode,
    this.isNetworkError = false,
    this.isAuthError = false,
    this.isFromCache = false,
    this.isQueuedForSync = false,
  });

  /// Crée une réponse de succès avec des données
  factory ApiResponse.success(T data, {bool isFromCache = false}) {
    return ApiResponse<T>(
      data: data,
      success: true,
      statusCode: 200,
      isFromCache: isFromCache,
    );
  }

  /// Crée une réponse d'erreur
  factory ApiResponse.error(
    String message, {
    int? statusCode,
    bool isNetworkError = false,
    bool isAuthError = false,
    bool isQueuedForSync = false,
  }) {
    return ApiResponse<T>(
      message: message,
      success: false,
      statusCode: statusCode,
      isNetworkError: isNetworkError,
      isAuthError: isAuthError,
      isQueuedForSync: isQueuedForSync,
    );
  }

  /// Vérifie si la réponse est un succès
  bool get isSuccess => success;

  /// Vérifie si la réponse est une erreur
  bool get isError => !success;

  /// Crée une copie de cette réponse avec des modifications
  ApiResponse<T> copyWith({
    T? data,
    String? message,
    bool? success,
    int? statusCode,
    bool? isNetworkError,
    bool? isAuthError,
    bool? isFromCache,
    bool? isQueuedForSync,
  }) {
    return ApiResponse<T>(
      data: data ?? this.data,
      message: message ?? this.message,
      success: success ?? this.success,
      statusCode: statusCode ?? this.statusCode,
      isNetworkError: isNetworkError ?? this.isNetworkError,
      isAuthError: isAuthError ?? this.isAuthError,
      isFromCache: isFromCache ?? this.isFromCache,
      isQueuedForSync: isQueuedForSync ?? this.isQueuedForSync,
    );
  }

  @override
  String toString() {
    return 'ApiResponse{success: $success, statusCode: $statusCode, message: $message, isFromCache: $isFromCache, isQueuedForSync: $isQueuedForSync}';
  }
} 