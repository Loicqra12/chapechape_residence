import 'package:flutter_test/flutter_test.dart';
import 'package:chapechape_partner/core/models/stay_credential_preview.dart';
import 'package:chapechape_partner/presentation/screens/qr/qr_scanner_screen.dart';

void main() {
  group('Stay QR contract — Partner', () {
    test('QRScanType purpose is explicit, not derived from token', () {
      expect(QRScanType.checkIn.purpose, 'checkin');
      expect(QRScanType.checkOut.purpose, 'checkout');
    });

    test('resolve preview parses backend fields only', () {
      final preview = StayCredentialPreview.fromJson({
        'reservationId': '507f1f77bcf86cd799439011',
        'residence': {'title': 'Villa Test', 'city': 'Abidjan'},
        'clientDisplayName': 'Jean Dupont',
        'checkIn': '2026-08-27T14:00:00.000Z',
        'checkOut': '2026-08-29T11:00:00.000Z',
        'status': 'confirmed',
        'purpose': 'checkin',
        'expiresAt': '2026-08-27T13:30:00.000Z',
      });

      expect(preview.reservationId, '507f1f77bcf86cd799439011');
      expect(preview.residenceTitle, 'Villa Test');
      expect(preview.clientDisplayName, 'Jean Dupont');
      expect(preview.actionLabel, 'Confirmer le check-in');
    });

    test('credential error messages mapped by code', () {
      expect(
        stayCredentialErrorMessage('STAY_CREDENTIAL_EXPIRED'),
        contains('expiré'),
      );
      expect(
        stayCredentialErrorMessage('STAY_CREDENTIAL_PURPOSE_MISMATCH'),
        contains('arrivée'),
      );
    });

    test('logs redact credential values', () {
      const raw = 'CCSTAY1.secret-token-value';
      final redacted = redactStayCredentials('{"credential": "$raw"}');
      expect(redacted, isNot(contains(raw)));
      expect(redacted, contains('[REDACTED]'));
    });
  });
}
