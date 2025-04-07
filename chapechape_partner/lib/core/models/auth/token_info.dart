/// Modèle pour représenter un token d'authentification avec sa date d'expiration
class TokenInfo {
  /// Le token d'authentification
  final String token;
  
  /// La date d'expiration du token
  final DateTime expiresAt;

  /// Crée une nouvelle instance de TokenInfo
  TokenInfo({
    required this.token,
    required this.expiresAt,
  });

  /// Vérifie si le token est expiré
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Crée une instance TokenInfo à partir d'un JSON
  factory TokenInfo.fromJson(Map<String, dynamic> json) {
    return TokenInfo(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  /// Convertit l'instance en JSON
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
} 