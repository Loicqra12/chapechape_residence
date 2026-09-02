import 'package:flutter_test/flutter_test.dart';
import 'package:chapechape_client/core/models/reservation_status.dart';
import 'package:chapechape_client/core/models/stay_credential.dart';

void main() {
  group('Stay QR contract — Client', () {
    test('confirmed → checkin issuance path', () {
      expect(
        ReservationStatusCanon.stayQrPurpose(ReservationStatusCanon.confirmed),
        'checkin',
      );
      expect(
        ReservationStatusCanon.isQrEligible(ReservationStatusCanon.confirmed),
        isTrue,
      );
    });

    test('in_stay → checkout issuance', () {
      expect(
        ReservationStatusCanon.stayQrPurpose(ReservationStatusCanon.inStay),
        'checkout',
      );
    });

    test('completed / cancelled / payment_pending → no QR action', () {
      for (final status in [
        ReservationStatusCanon.completed,
        ReservationStatusCanon.cancelled,
        ReservationStatusCanon.paymentPending,
        ReservationStatusCanon.pending,
        ReservationStatusCanon.awaitingApproval,
      ]) {
        expect(ReservationStatusCanon.stayQrPurpose(status), isNull);
        expect(ReservationStatusCanon.isQrEligible(status), isFalse);
      }
    });

    test('credential raw encoded exactly in QR payload concept', () {
      const raw = 'CCSTAY1.AbCdEfGhIjKlMnOp';
      final cred = StayCredential(
        credential: raw,
        purpose: 'checkin',
        expiresAt: DateTime.parse('2026-08-27T12:00:00.000Z'),
        version: 3,
      );
      expect(cred.credential, raw);
      expect(cred.credential.startsWith('CCSTAY1.'), isTrue);
      expect(cred.toString(), isNot(contains(raw)));
    });
  });
}
