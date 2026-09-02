import 'package:equatable/equatable.dart';

/// Credential éphémère émis par POST /reservations/:id/stay-credentials.
/// Ne jamais persister [credential] hors mémoire runtime.
class StayCredential extends Equatable {
  final String credential;
  final String purpose;
  final DateTime expiresAt;
  final int version;

  const StayCredential({
    required this.credential,
    required this.purpose,
    required this.expiresAt,
    required this.version,
  });

  factory StayCredential.fromJson(Map<String, dynamic> json) {
    return StayCredential(
      credential: json['credential'] as String,
      purpose: json['purpose'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String).toLocal(),
      version: (json['version'] as num).toInt(),
    );
  }

  bool get isCheckin => purpose == 'checkin';
  bool get isCheckout => purpose == 'checkout';

  @override
  List<Object?> get props => [purpose, expiresAt, version];

  @override
  String toString() => 'StayCredential(purpose: $purpose, version: $version)';
}

/// Erreur API stay-credential mappée par code backend (jamais par message texte).
class StayCredentialException implements Exception {
  final String code;
  final String? message;

  const StayCredentialException(this.code, {this.message});

  static StayCredentialException? fromResponseData(dynamic data) {
    if (data is! Map) return null;
    final code = data['code'] ?? data['errorCode'];
    if (code is! String || code.isEmpty) return null;
    final message = data['message'] as String?;
    return StayCredentialException(code, message: message);
  }

  @override
  String toString() => 'StayCredentialException($code)';
}
