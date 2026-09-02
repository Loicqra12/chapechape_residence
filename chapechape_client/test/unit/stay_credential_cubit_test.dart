import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chapechape_client/core/cubits/stay_credential_cubit.dart';
import 'package:chapechape_client/core/models/stay_credential.dart';
import 'package:chapechape_client/core/services/booking_service.dart';

class MockBookingService extends Mock implements BookingService {}

void main() {
  late MockBookingService bookingService;

  setUp(() {
    bookingService = MockBookingService();
  });

  StayCredential fakeCredential({int version = 1, String purpose = 'checkin'}) =>
      StayCredential(
        credential: 'CCSTAY1.test-token-$version',
        purpose: purpose,
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        version: version,
      );

  group('StayCredentialCubit single-flight', () {
    test('double tap generate → 1 request', () async {
      when(() => bookingService.issueStayCredential(
            reservationId: any(named: 'reservationId'),
            purpose: any(named: 'purpose'),
          )).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return fakeCredential();
      });

      final cubit = StayCredentialCubit(bookingService);
      cubit.issue(reservationId: 'r1', purpose: 'checkin');
      cubit.issue(reservationId: 'r1', purpose: 'checkin');

      await Future<void>.delayed(const Duration(milliseconds: 100));
      verify(() => bookingService.issueStayCredential(
            reservationId: 'r1',
            purpose: 'checkin',
          )).called(1);
      await cubit.close();
    });

    test('stale response A does not overwrite newer B', () async {
      when(() => bookingService.issueStayCredential(
            reservationId: any(named: 'reservationId'),
            purpose: any(named: 'purpose'),
          )).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return fakeCredential(version: 1, purpose: 'checkin');
      });

      final cubit = StayCredentialCubit(bookingService);
      final future = cubit.issue(reservationId: 'r1', purpose: 'checkin');
      cubit.invalidateInFlightGenerationForTest();
      await future;
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(cubit.state.credential, isNull);
      expect(cubit.state.isIssuing, isFalse);
      await cubit.close();
    });

    test('dispose during request → no throw after close', () async {
      when(() => bookingService.issueStayCredential(
            reservationId: any(named: 'reservationId'),
            purpose: any(named: 'purpose'),
          )).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return fakeCredential();
      });

      final cubit = StayCredentialCubit(bookingService);
      cubit.issue(reservationId: 'r1', purpose: 'checkin');
      await cubit.close();
      expect(cubit.isClosed, isTrue);
    });

    test('double tap regenerate → 1 request while in flight', () async {
      when(() => bookingService.issueStayCredential(
            reservationId: any(named: 'reservationId'),
            purpose: any(named: 'purpose'),
          )).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return fakeCredential(version: 2, purpose: 'checkout');
      });

      final cubit = StayCredentialCubit(bookingService);
      cubit.issue(reservationId: 'r1', purpose: 'checkout');
      for (var i = 0; i < 9; i++) {
        cubit.issue(reservationId: 'r1', purpose: 'checkout');
      }

      await Future<void>.delayed(const Duration(milliseconds: 80));
      verify(() => bookingService.issueStayCredential(
            reservationId: 'r1',
            purpose: 'checkout',
          )).called(1);
      await cubit.close();
    });

    test('markExpired disables QR display state', () async {
      when(() => bookingService.issueStayCredential(
            reservationId: any(named: 'reservationId'),
            purpose: any(named: 'purpose'),
          )).thenAnswer((_) async => fakeCredential());

      final cubit = StayCredentialCubit(bookingService);
      await cubit.issue(reservationId: 'r1', purpose: 'checkin');
      await Future<void>.delayed(const Duration(milliseconds: 10));

      cubit.markExpired();
      expect(cubit.state.isExpired, isTrue);
      expect(cubit.state.credential, isNotNull);
      await cubit.close();
    });
  });
}
