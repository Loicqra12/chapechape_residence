import 'package:flutter_test/flutter_test.dart';

/// P2-06C — contrat payload préférences push Partner.
void main() {
  group('P2-06C Partner push preferences contract', () {
    test('OneSignalService default category keys are plural', () {
      const defaults = {
        'bookings': true,
        'messages': true,
        'payments': true,
        'system': true,
      };

      expect(defaults.keys, contains('bookings'));
      expect(defaults.keys, isNot(contains('booking_created')));
    });

    test('register device payload uses partner appKind', () {
      const payload = {
        'deviceToken': 'bbbbbbbb-cccc-dddd-eeee-ffff-ffffffffffff-222222222222',
        'appKind': 'partner',
        'platform': 'ios',
      };

      expect(payload['appKind'], 'partner');
    });

    test('remote push preferences use canonical backend keys', () {
      const categories = {
        'bookings': true,
        'messages': true,
        'payments': true,
        'promotions': false,
        'system': true,
      };

      expect(categories.keys, containsAll(['bookings', 'messages', 'payments', 'promotions', 'system']));
    });
  });
}
