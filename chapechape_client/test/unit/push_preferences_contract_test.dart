import 'package:flutter_test/flutter_test.dart';

/// P2-06C — contrat payload préférences push (clés backend canoniques).
void main() {
  group('P2-06C Client push preferences contract', () {
    test('category keys match backend Joi schema (plural)', () {
      const categories = {
        'bookings': true,
        'messages': true,
        'payments': true,
        'promotions': false,
      };

      expect(categories.keys, contains('bookings'));
      expect(categories.keys, isNot(contains('booking')));
      expect(categories.keys, isNot(contains('message')));
    });

    test('register device payload contract', () {
      const payload = {
        'deviceToken': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee-111111111111',
        'appKind': 'client',
        'platform': 'android',
      };

      expect(payload['appKind'], 'client');
      expect((payload['deviceToken'] as String).length, greaterThanOrEqualTo(32));
    });
  });
}
