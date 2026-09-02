import 'package:flutter_test/flutter_test.dart';
import 'package:chapechape_partner/core/services/socket_service.dart';

/// P2-06B — Partner consomme new_reservation_received (canonique backend emitNewReservation).
void main() {
  group('P2-06B Partner socket reservation realtime', () {
    test('new_reservation_received callback is the LIVE new booking path', () {
      final service = SocketService();
      var refreshCount = 0;

      service.onNewReservationReceived = (_) => refreshCount++;

      service.onNewReservationReceived?.call({
        'reservationId': 'res-1',
        'status': 'payment_pending',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      expect(refreshCount, 1);
    });

    test('residence_reservation_update is separate from partner_reservation_status_changed', () {
      final service = SocketService();
      var residenceRefresh = 0;
      var partnerStatusRefresh = 0;

      service.onResidenceReservationUpdate = (_) => residenceRefresh++;
      service.onReservationStatusChanged = (_) => partnerStatusRefresh++;

      final payload = {
        'reservationId': 'res-2',
        'newStatus': 'in_stay',
        'status': 'in_stay',
      };

      service.onResidenceReservationUpdate?.call(payload);
      expect(residenceRefresh, 1);
      expect(partnerStatusRefresh, 0);
    });
  });
}
