/// Exception personnalisée pour la gestion des erreurs API
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic> data;

  /// Crée une nouvelle exception API
  ///
  /// [message] - Message d'erreur lisible par l'utilisateur
  /// [statusCode] - Code de statut HTTP associé à l'erreur
  /// [data] - Données supplémentaires associées à l'erreur
  ApiException(this.message, this.statusCode, this.data);

  /// Indique si l'erreur est liée à un problème réseau
  bool get isNetworkError => statusCode == 0;

  /// Indique si l'erreur est liée à l'authentification
  bool get isAuthError => statusCode == 401 || statusCode == 403;

  /// Indique si l'erreur est liée au serveur
  bool get isServerError => statusCode >= 500;

  /// Indique si l'erreur est liée à une demande invalide
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// Indique si l'erreur implique que la ressource n'existe pas
  bool get isNotFoundError => statusCode == 404;

  @override
  String toString() {
    return message;
  }
}
