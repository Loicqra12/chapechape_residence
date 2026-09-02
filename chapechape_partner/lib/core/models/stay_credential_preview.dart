import 'package:equatable/equatable.dart';

/// Preview non-mutating retourné par POST /stay-credentials/resolve.
class StayCredentialPreview extends Equatable {
  final String reservationId;
  final String? residenceTitle;
  final String? residenceCity;
  final String? clientDisplayName;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String status;
  final String purpose;
  final DateTime expiresAt;

  const StayCredentialPreview({
    required this.reservationId,
    this.residenceTitle,
    this.residenceCity,
    this.clientDisplayName,
    this.checkIn,
    this.checkOut,
    required this.status,
    required this.purpose,
    required this.expiresAt,
  });

  factory StayCredentialPreview.fromJson(Map<String, dynamic> json) {
    final residence = json['residence'];
    return StayCredentialPreview(
      reservationId: json['reservationId'] as String,
      residenceTitle: residence is Map ? residence['title'] as String? : null,
      residenceCity: residence is Map ? residence['city'] as String? : null,
      clientDisplayName: json['clientDisplayName'] as String?,
      checkIn: json['checkIn'] != null
          ? DateTime.parse(json['checkIn'] as String).toLocal()
          : null,
      checkOut: json['checkOut'] != null
          ? DateTime.parse(json['checkOut'] as String).toLocal()
          : null,
      status: json['status'] as String,
      purpose: json['purpose'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String).toLocal(),
    );
  }

  String get actionLabel =>
      purpose == 'checkout' ? 'Confirmer le check-out' : 'Confirmer le check-in';

  @override
  List<Object?> get props => [reservationId, purpose, status];
}

class StayCredentialApiException implements Exception {
  final String code;
  final String? message;

  const StayCredentialApiException(this.code, {this.message});

  static StayCredentialApiException? fromResponse(dynamic data) {
    if (data is! Map) return null;
    final code = data['code'] ?? data['errorCode'];
    if (code is! String) return null;
    return StayCredentialApiException(code, message: data['message'] as String?);
  }

  @override
  String toString() => 'StayCredentialApiException($code)';
}

String stayCredentialErrorMessage(String code) {
  switch (code) {
    case 'STAY_CREDENTIAL_EXPIRED':
      return 'QR expiré — demandez au client de régénérer son QR.';
    case 'STAY_CREDENTIAL_INVALID':
      return 'QR invalide — scannez à nouveau.';
    case 'STAY_CREDENTIAL_CONSUMED':
      return 'Ce QR a déjà été utilisé.';
    case 'STAY_CREDENTIAL_PURPOSE_MISMATCH':
      return 'Mauvais type de QR (arrivée / départ).';
    case 'STAY_CREDENTIAL_NOT_ELIGIBLE':
      return 'Réservation non éligible — actualisez la page.';
    case 'RESERVATION_CHECKIN_TOO_EARLY':
      return 'Check-in trop tôt — autorisé 2 h avant l\'heure prévue.';
    case 'NETWORK_ERROR':
      return 'Connexion impossible. Vérifiez votre réseau.';
    default:
      return 'Impossible de valider ce QR.';
  }
}

/// Redacte les credentials stay des logs réseau (DEV).
String redactStayCredentials(String text) {
  var redacted = text.replaceAllMapped(
    RegExp(r'CCSTAY1\.[A-Za-z0-9_-]+'),
    (_) => 'CCSTAY1.[REDACTED]',
  );
  redacted = redacted.replaceAllMapped(
    RegExp(r'"credential"\s*:\s*"[^"]*"'),
    (_) => '"credential": "[REDACTED]"',
  );
  return redacted;
}
