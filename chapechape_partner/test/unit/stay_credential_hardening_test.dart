import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chapechape_partner/core/models/stay_credential_preview.dart';
import 'package:chapechape_partner/core/services/api/reservation_service.dart';

void main() {
  const sentinel = 'CCSTAY1.SUPER_SECRET_SENTINEL';

  group('Stay credential log redaction — Partner', () {
    test('resolve + commit request bodies redacted', () {
      for (final raw in [
        '{"credential":"$sentinel","purpose":"checkin"}',
        '{"credential":"$sentinel"}',
      ]) {
        expect(redactStayCredentials(raw), isNot(contains(sentinel)));
      }
    });

    test('PerformPartnerCheckin diagnostic redacted', () {
      final raw = 'PerformPartnerCheckin(res-1, credential: $sentinel)';
      expect(redactStayCredentials(raw), isNot(contains(sentinel)));
    });
  });

  group('Partner commit single-flight (UI guard pattern)', () {
    test('10 rapid commit attempts → 1 PATCH /checkin', () async {
      var patchCount = 0;
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          patchCount++;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'data': {
                  '_id': 'res-1',
                  'residence': 'residence-1',
                  'user': 'client-1',
                  'checkIn': '2027-06-10T14:00:00.000Z',
                  'checkOut': '2027-06-15T11:00:00.000Z',
                  'numberOfGuests': 1,
                  'totalPrice': 50000,
                  'status': 'in_stay',
                  'paymentStatus': 'paid',
                },
              },
            ),
          );
        },
      ));

      final service = ReservationService(dio);
      var commitInFlight = false;

      Future<void> guardedCommit() async {
        if (commitInFlight) return;
        commitInFlight = true;
        try {
          await service.performCheckin('res-1', credential: sentinel);
        } finally {
          commitInFlight = false;
        }
      }

      await Future.wait(List.generate(10, (_) => guardedCommit()));
      expect(patchCount, 1);
    });

    test('10 rapid resolve attempts with scan lock → 1 POST resolve', () async {
      var resolveCount = 0;
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          resolveCount++;
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'data': {
                  'reservationId': 'res-1',
                  'status': 'confirmed',
                  'purpose': 'checkin',
                  'expiresAt': '2027-06-10T16:00:00.000Z',
                },
              },
            ),
          );
        },
      ));

      final service = ReservationService(dio);
      var scanLocked = false;
      var resolveInFlight = false;

      Future<void> guardedResolve() async {
        if (scanLocked || resolveInFlight) return;
        scanLocked = true;
        if (resolveInFlight) return;
        resolveInFlight = true;
        try {
          await service.resolveStayCredential(
            credential: sentinel,
            purpose: 'checkin',
          );
        } finally {
          resolveInFlight = false;
        }
      }

      await Future.wait(List.generate(10, (_) => guardedResolve()));
      expect(resolveCount, 1);
    });
  });
}
