import 'package:flutter_test/flutter_test.dart';
import 'package:chapechape_client/core/services/api/interceptors/logging_interceptor.dart';

void main() {
  const sentinel = 'CCSTAY1.SUPER_SECRET_SENTINEL';

  group('Stay credential log redaction — Client', () {
    test('issuance success response body', () {
      final raw =
          '{"success":true,"data":{"credential":"$sentinel","purpose":"checkin","expiresAt":"2026-08-28T12:00:00.000Z","version":1}}';
      final redacted = redactStayCredentials(raw);
      expect(redacted, isNot(contains(sentinel)));
      expect(redacted, contains('"credential": "[REDACTED]"'));
    });

    test('resolve request body', () {
      final raw = '{"credential":"$sentinel","purpose":"checkin"}';
      expect(redactStayCredentials(raw), isNot(contains(sentinel)));
    });

    test('checkin commit request body', () {
      final raw = '{"credential":"$sentinel"}';
      expect(redactStayCredentials(raw), isNot(contains(sentinel)));
    });

    test('DioException-style error payload', () {
      final raw =
          'DioException [400]: credential invalid body={"credential":"$sentinel","code":"STAY_CREDENTIAL_INVALID"}';
      expect(redactStayCredentials(raw), isNot(contains(sentinel)));
    });

    test('StayCredentialState diagnostic string', () {
      final raw =
          'StayCredentialState(hasCredential: true, credential: $sentinel, version: 2)';
      expect(redactStayCredentials(raw), isNot(contains(sentinel)));
    });
  });
}
