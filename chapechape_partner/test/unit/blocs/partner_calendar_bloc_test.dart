import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chapechape_partner/core/blocs/calendar/partner_calendar_bloc.dart';
import 'package:chapechape_partner/core/blocs/calendar/partner_calendar_event.dart';
import 'package:chapechape_partner/core/blocs/calendar/partner_calendar_state.dart';
import 'package:chapechape_partner/core/exceptions/api_exception.dart';
import 'package:chapechape_partner/core/models/calendar/partner_calendar.dart';
import 'package:chapechape_partner/core/services/api/partner_calendar_service.dart';
import 'package:chapechape_partner/core/utils/calendar_error_mapper.dart';

class MockPartnerCalendarService extends Mock implements PartnerCalendarService {}

void main() {
  late MockPartnerCalendarService service;

  final calendar = PartnerCalendar(
    residenceId: 'res1',
    timezone: 'Africa/Abidjan',
    start: DateTime.utc(2027, 8, 1),
    end: DateTime.utc(2027, 9, 1),
    occupations: const [],
    days: const [],
  );

  setUpAll(() {
    registerFallbackValue(DateTime.utc(2027, 8, 1));
  });

  setUp(() {
    service = MockPartnerCalendarService();
  });

  PartnerCalendarBloc buildBloc() => PartnerCalendarBloc(service: service);

  blocTest<PartnerCalendarBloc, PartnerCalendarState>(
    'loads partner calendar from API projection only',
    build: () {
      when(() => service.getPartnerCalendar(
            residenceId: any(named: 'residenceId'),
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => calendar);
      return buildBloc();
    },
    act: (bloc) => bloc.add(PartnerCalendarStarted(
      residenceId: 'res1',
      month: DateTime.utc(2027, 8, 1),
    )),
    expect: () => [
      isA<PartnerCalendarLoading>(),
      isA<PartnerCalendarLoaded>(),
    ],
    verify: (_) {
      verify(() => service.getPartnerCalendar(
            residenceId: 'res1',
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).called(1);
    },
  );

  blocTest<PartnerCalendarBloc, PartnerCalendarState>(
    '409 on block shows mapped message then refreshes calendar',
    build: () {
      when(() => service.getPartnerCalendar(
            residenceId: any(named: 'residenceId'),
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => calendar);
      when(() => service.createBlock(
            residenceId: any(named: 'residenceId'),
            start: any(named: 'start'),
            end: any(named: 'end'),
            bookingType: any(named: 'bookingType'),
            type: any(named: 'type'),
            reason: any(named: 'reason'),
          )).thenThrow(ApiException('x', 409, {
        'errorCode': 'INVENTORY_ALREADY_RESERVED',
      }));
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(PartnerCalendarStarted(
        residenceId: 'res1',
        month: DateTime.utc(2027, 8, 1),
      ));
      await Future<void>.delayed(Duration.zero);
      bloc.add(PartnerCalendarBlockRequested(
        start: DateTime.utc(2027, 8, 10),
        end: DateTime.utc(2027, 8, 15),
      ));
    },
    wait: const Duration(milliseconds: 50),
    expect: () => [
      isA<PartnerCalendarLoading>(),
      isA<PartnerCalendarLoaded>(),
      isA<PartnerCalendarLoaded>().having((s) => s.mutating, 'mutating', true),
      isA<PartnerCalendarLoaded>().having(
        (s) => s.bannerMessage,
        'banner',
        CalendarErrorMapper.alreadyReserved,
      ),
    ],
  );

  blocTest<PartnerCalendarBloc, PartnerCalendarState>(
    'stores [start, end) range from calendar selection without local inventory merge',
    build: () {
      when(() => service.getPartnerCalendar(
            residenceId: any(named: 'residenceId'),
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).thenAnswer((_) async => calendar);
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(PartnerCalendarStarted(
        residenceId: 'res1',
        month: DateTime.utc(2027, 8, 1),
      ));
      await Future<void>.delayed(Duration.zero);
      bloc.add(PartnerCalendarRangeSelected(
        start: DateTime.utc(2027, 8, 20),
        end: DateTime.utc(2027, 8, 25),
      ));
    },
    expect: () => [
      isA<PartnerCalendarLoading>(),
      isA<PartnerCalendarLoaded>(),
      isA<PartnerCalendarLoaded>()
          .having((s) => s.rangeStart, 'start', DateTime.utc(2027, 8, 20))
          .having((s) => s.rangeEnd, 'end', DateTime.utc(2027, 8, 25)),
    ],
    verify: (_) {
      verify(() => service.getPartnerCalendar(
            residenceId: any(named: 'residenceId'),
            start: any(named: 'start'),
            end: any(named: 'end'),
          )).called(1);
    },
  );
}
