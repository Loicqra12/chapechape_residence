import 'package:flutter_test/flutter_test.dart';
import 'package:chapechape_partner/core/models/calendar/partner_calendar.dart';
import 'package:chapechape_partner/core/utils/calendar_error_mapper.dart';
import 'package:chapechape_partner/core/exceptions/api_exception.dart';

PartnerOccupation occupation({
  required CalendarSourceType source,
  String id = '1',
  String? reservationStatus,
}) {
  return PartnerOccupation(
    id: id,
    sourceType: source,
    status: CalendarOccupationStatus.reserved,
    start: DateTime.utc(2027, 8, 10, 14),
    end: DateTime.utc(2027, 8, 15, 11),
    bookingType: 'day',
    reservationStatus: reservationStatus,
  );
}

void main() {
  group('PartnerCalendarActionPolicy', () {
    test('empty selection offers block + external only', () {
      expect(
        PartnerCalendarActionPolicy.forEmptySelection(),
        [PartnerCalendarAction.createBlock, PartnerCalendarAction.createExternal],
      );
    });

    test('ChapeChape reservation cannot be unblocked', () {
      final occ = occupation(source: CalendarSourceType.reservation, reservationStatus: 'confirmed');
      final actions = PartnerCalendarActionPolicy.forOccupation(occ);
      expect(actions, [PartnerCalendarAction.viewReservation]);
      expect(actions.contains(PartnerCalendarAction.unblock), isFalse);
      expect(PartnerCalendarActionPolicy.canUnblock(occ), isFalse);
    });

    test('manual block can be unblocked', () {
      final occ = occupation(source: CalendarSourceType.manualBlock);
      expect(PartnerCalendarActionPolicy.canUnblock(occ), isTrue);
      expect(
        PartnerCalendarActionPolicy.forOccupation(occ),
        contains(PartnerCalendarAction.unblock),
      );
    });

    test('external offers view/edit/cancel/complete, not unblock', () {
      final occ = occupation(source: CalendarSourceType.externalReservation);
      final actions = PartnerCalendarActionPolicy.forOccupation(occ);
      expect(actions.contains(PartnerCalendarAction.unblock), isFalse);
      expect(actions, contains(PartnerCalendarAction.completeExternal));
    });
  });

  group('PartnerCalendarDay.available', () {
    test('means full-day occupancy, not empty minutes', () {
      final day = PartnerCalendarDay.fromJson({
        'date': '2027-08-10',
        'available': false,
        'availableMeaning': 'full_day',
        'slots': [
          {
            'id': 'b1',
            'sourceType': 'manual_block',
            'status': 'blocked',
            'start': '2027-08-10T13:00:00.000Z',
            'end': '2027-08-10T15:00:00.000Z',
            'bookingType': 'hour',
            'blockType': 'maintenance',
          }
        ],
      });
      expect(day.available, isFalse);
      expect(day.availableMeaning, 'full_day');
      expect(day.slots, isNotEmpty);
    });
  });

  group('CalendarErrorMapper', () {
    test('maps INVENTORY_ALREADY_RESERVED for block', () {
      final error = ApiException('conflict', 409, {
        'errorCode': 'INVENTORY_ALREADY_RESERVED',
      });
      expect(
        CalendarErrorMapper.messageFor(error, action: 'block'),
        CalendarErrorMapper.alreadyReserved,
      );
    });

    test('maps EXTERNAL_RESERVATION_CONFLICT', () {
      final error = ApiException('conflict', 409, {
        'errorCode': 'EXTERNAL_RESERVATION_CONFLICT',
      });
      expect(
        CalendarErrorMapper.messageFor(error, action: 'external'),
        CalendarErrorMapper.externalConflict,
      );
    });

    test('409 without code still not unknown error', () {
      final error = ApiException('x', 409, {});
      expect(
        CalendarErrorMapper.messageFor(error),
        isNot(contains('inconnue')),
      );
    });
  });
}
