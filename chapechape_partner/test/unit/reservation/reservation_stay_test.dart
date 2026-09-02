import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:chapechape_partner/core/blocs/reservation/reservation_bloc.dart';
import 'package:chapechape_partner/core/models/reservation/reservation.dart';
import 'package:chapechape_partner/core/services/api/reservation_service.dart';

class MockReservationService extends Mock implements ReservationService {}

Reservation _sampleReservation({ReservationStatus status = ReservationStatus.confirmed}) {
  return Reservation(
    id: 'res-1',
    residenceId: 'residence-1',
    residenceName: 'Test',
    residenceImage: 'https://example.com/img.jpg',
    clientName: 'Client Test',
    clientPhone: '+2250700000000',
    checkIn: DateTime.utc(2027, 6, 10, 14),
    checkOut: DateTime.utc(2027, 6, 15, 11),
    totalAmount: 50000,
    status: status,
    createdAt: DateTime.utc(2027, 6, 1),
    guestsCount: 1,
  );
}

void main() {
  late MockReservationService reservationService;
  late ReservationBloc bloc;

  setUpAll(() {
    registerFallbackValue(ReservationStatus.confirmed);
  });

  setUp(() {
    reservationService = MockReservationService();
    bloc = ReservationBloc(reservationService);
  });

  tearDown(() => bloc.close());

  group('ReservationService stay paths', () {
    test('performCheckin uses PATCH .../checkin', () async {
      String? method;
      String? path;

      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          method = options.method;
          path = options.path;
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
      final result = await service.performCheckin('res-1');

      expect(method, 'PATCH');
      expect(path, contains('/checkin'));
      expect(result?.status, ReservationStatus.inStay);
    });

    test('performCheckout uses PATCH .../checkout', () async {
      String? path;

      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          path = options.path;
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
                  'status': 'completed',
                  'paymentStatus': 'paid',
                },
              },
            ),
          );
        },
      ));

      final service = ReservationService(dio);
      final result = await service.performCheckout('res-1');

      expect(path, contains('/checkout'));
      expect(result?.status, ReservationStatus.completed);
    });

    test('performCheckin surfaces backend error code', () async {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 400,
              data: {
                'code': 'RESERVATION_CHECKIN_TOO_EARLY',
                'message': 'Trop tôt',
              },
            ),
          );
        },
      ));

      final service = ReservationService(dio);
      expect(
        () => service.performCheckin('res-1'),
        throwsA(
          predicate(
            (e) =>
                e.toString().contains('RESERVATION_CHECKIN_TOO_EARLY') &&
                e.toString().contains('Trop tôt'),
          ),
        ),
      );
    });
  });

  group('ReservationBloc stay actions', () {
    blocTest<ReservationBloc, ReservationState>(
      'PerformPartnerCheckin calls performCheckin not updateReservationStatus',
      build: () {
        when(() => reservationService.performCheckin('res-1'))
            .thenAnswer((_) async => _sampleReservation(status: ReservationStatus.inStay));
        when(() => reservationService.getPartnerReservationsDirect())
            .thenAnswer((_) async => []);
        return bloc;
      },
      act: (b) => b.add(PerformPartnerCheckin('res-1')),
      verify: (_) {
        verify(() => reservationService.performCheckin('res-1')).called(1);
        verifyNever(
          () => reservationService.updateReservationStatus(any(), any()),
        );
      },
    );

    blocTest<ReservationBloc, ReservationState>(
      'PerformPartnerCheckout calls performCheckout not updateReservationStatus',
      build: () {
        when(() => reservationService.performCheckout('res-1'))
            .thenAnswer((_) async => _sampleReservation(status: ReservationStatus.completed));
        when(() => reservationService.getPartnerReservationsDirect())
            .thenAnswer((_) async => []);
        return bloc;
      },
      act: (b) => b.add(PerformPartnerCheckout('res-1')),
      verify: (_) {
        verify(() => reservationService.performCheckout('res-1')).called(1);
        verifyNever(
          () => reservationService.updateReservationStatus(any(), any()),
        );
      },
    );

    blocTest<ReservationBloc, ReservationState>(
      'UpdateReservationStatus rejects in_stay bypass',
      build: () => bloc,
      act: (b) => b.add(UpdateReservationStatus('res-1', ReservationStatus.inStay)),
      expect: () => [
        isA<ReservationError>().having(
          (s) => s.message,
          'message',
          contains('CHECK-IN / CHECK-OUT'),
        ),
      ],
      verify: (_) {
        verifyNever(
          () => reservationService.updateReservationStatus(any(), any()),
        );
      },
    );
  });
}
