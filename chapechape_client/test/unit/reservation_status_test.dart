import 'package:flutter_test/flutter_test.dart';
import 'package:chapechape_client/core/models/reservation_status.dart';
import 'package:chapechape_client/core/models/booking_model.dart';
import 'package:chapechape_client/core/utils/booking_helpers.dart';

Booking booking({
  required String status,
  DateTime? paymentDeadline,
  DateTime? hostApprovalDeadline,
  DateTime? checkIn,
  DateTime? checkOut,
}) {
  final now = DateTime.utc(2027, 8, 17, 12);
  return Booking(
    id: 'b1',
    userId: 'u1',
    residenceId: 'r1',
    residenceName: 'Villa',
    checkIn: checkIn ?? now.add(const Duration(days: 2)),
    checkOut: checkOut ?? now.add(const Duration(days: 5)),
    numberOfGuests: 2,
    totalPrice: 10000,
    status: ReservationStatusCanon.fromApi(status),
    cancellationPolicyId: 'p1',
    paymentDeadline: paymentDeadline,
    hostApprovalDeadline: hostApprovalDeadline,
  );
}

void main() {
  group('ReservationStatusCanon.fromApi', () {
    test('keeps canonical values', () {
      expect(ReservationStatusCanon.fromApi('payment_pending'), 'payment_pending');
      expect(ReservationStatusCanon.fromApi('in_stay'), 'in_stay');
      expect(ReservationStatusCanon.fromApi('completed'), 'completed');
      expect(ReservationStatusCanon.fromApi('expired'), 'expired');
    });

    test('maps legacy aliases and never keeps them', () {
      expect(ReservationStatusCanon.fromApi('pending_payment'), 'payment_pending');
      expect(ReservationStatusCanon.fromApi('checked_in'), 'in_stay');
      expect(ReservationStatusCanon.fromApi('checked_out'), 'completed');
      expect(ReservationStatusCanon.fromApi('in_progress'), 'in_stay');
    });

    test('unknown does not become confirmed or active', () {
      expect(ReservationStatusCanon.fromApi('something_new'), 'unknown');
      expect(ReservationStatusCanon.fromApi(null), 'unknown');
    });
  });

  group('Booking.fromJson', () {
    test('normalizes pending_payment from cache/API', () {
      final parsed = Booking.fromJson({
        '_id': '1',
        'user': 'u',
        'residence': 'r',
        'checkIn': '2027-08-20T10:00:00.000Z',
        'checkOut': '2027-08-22T10:00:00.000Z',
        'status': 'pending_payment',
        'totalPrice': 1,
      });
      expect(parsed.status, 'payment_pending');
    });
  });

  group('timers and labels', () {
    test('payment_pending activates payment timer when deadline exists', () {
      final b = booking(
        status: 'payment_pending',
        paymentDeadline: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(BookingHelpers.hasPaymentTimer(b), isTrue);
      expect(BookingHelpers.getStatusLabel(b.status), 'Paiement en attente');
    });

    test('confirmed is a confirmed reservation, not a timer', () {
      final b = booking(status: 'confirmed');
      expect(BookingHelpers.hasPaymentTimer(b), isFalse);
      expect(BookingHelpers.getStatusLabel(b.status), 'Confirmée');
    });

    test('in_stay is a stay in progress', () {
      final b = booking(status: 'in_stay');
      expect(BookingHelpers.getStatusLabel(b.status), 'Séjour en cours');
      expect(BookingHelpers.isActiveBooking(b), isTrue);
    });

    test('completed is a finished stay', () {
      final b = booking(status: 'completed');
      expect(BookingHelpers.getStatusLabel(b.status), 'Terminée');
      expect(BookingHelpers.isActiveBooking(b), isFalse);
    });

    test('expired is expired', () {
      final b = booking(status: 'expired');
      expect(BookingHelpers.getStatusLabel(b.status), 'Expirée');
    });
  });
}
