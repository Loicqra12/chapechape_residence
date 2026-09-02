import 'package:flutter_test/flutter_test.dart';
import 'package:chapechape_partner/core/models/reservation/reservation.dart';

void main() {
  group('ReservationStatus.fromBackendFormat', () {
    test('keeps canonical values', () {
      expect(ReservationStatus.fromBackendFormat('awaiting_approval'), ReservationStatus.awaitingApproval);
      expect(ReservationStatus.fromBackendFormat('payment_pending'), ReservationStatus.paymentPending);
      expect(ReservationStatus.fromBackendFormat('confirmed'), ReservationStatus.confirmed);
      expect(ReservationStatus.fromBackendFormat('in_stay'), ReservationStatus.inStay);
      expect(ReservationStatus.fromBackendFormat('completed'), ReservationStatus.completed);
    });

    test('maps aliases without persisting them', () {
      expect(ReservationStatus.fromBackendFormat('pending_payment'), ReservationStatus.paymentPending);
      expect(ReservationStatus.fromBackendFormat('checked_in'), ReservationStatus.inStay);
      expect(ReservationStatus.fromBackendFormat('checked_out'), ReservationStatus.completed);
      expect(ReservationStatus.fromBackendFormat('in_progress'), ReservationStatus.inStay);
      expect(ReservationStatus.paymentPending.toBackendFormat(), 'payment_pending');
      expect(ReservationStatus.inStay.toBackendFormat(), 'in_stay');
      expect(ReservationStatus.completed.toBackendFormat(), 'completed');
    });

    test('unknown does not become pending or confirmed', () {
      expect(ReservationStatus.fromBackendFormat('brand_new_status'), ReservationStatus.unknown);
      expect(ReservationStatus.unknown.toBackendFormat(), isNot('pending'));
      expect(ReservationStatus.unknown.toBackendFormat(), isNot('confirmed'));
    });
  });

  group('ReservationStatusPolicy', () {
    test('awaiting_approval exposes approve/reject, not unblock-style dumps', () {
      expect(
        ReservationStatusPolicy.partnerTransitionsFrom(ReservationStatus.awaitingApproval),
        [ReservationStatus.confirmed, ReservationStatus.rejected],
      );
    });

    test('confirmed and in_stay use dedicated check-in/out endpoints, not status sheet', () {
      expect(
        ReservationStatusPolicy.partnerTransitionsFrom(ReservationStatus.confirmed),
        isEmpty,
      );
      expect(
        ReservationStatusPolicy.partnerTransitionsFrom(ReservationStatus.inStay),
        isEmpty,
      );
    });

    test('payment_pending is not treated as pending_payment and has no fake approve', () {
      expect(ReservationStatus.paymentPending.canBeApproved, isFalse);
      expect(ReservationStatus.paymentPending.toBackendFormat(), 'payment_pending');
      expect(
        ReservationStatusPolicy.partnerTransitionsFrom(ReservationStatus.paymentPending),
        isEmpty,
      );
    });

    test('completed is terminal', () {
      expect(
        ReservationStatusPolicy.partnerTransitionsFrom(ReservationStatus.completed),
        isEmpty,
      );
    });
  });
}
