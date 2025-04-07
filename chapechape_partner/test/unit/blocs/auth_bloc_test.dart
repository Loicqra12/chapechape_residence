import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chapechape_partner/core/blocs/auth/auth_bloc.dart';
import 'package:chapechape_partner/core/services/api/auth_service.dart';
import 'package:chapechape_partner/core/models/partner/partner_model.dart';

// Mocks
class MockAuthService extends Mock implements AuthService {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}
class MockPartner extends Mock implements Partner {}

void main() {
  late MockAuthService authService;
  late MockSecureStorage secureStorage;
  late AuthBloc authBloc;
  final partner = MockPartner();

  setUp(() {
    authService = MockAuthService();
    secureStorage = MockSecureStorage();
    authBloc = AuthBloc(
      authService: authService,
      storage: secureStorage,
    );

    // Configuration de base des mocks
    when(() => partner.id).thenReturn('test_id');
    when(() => partner.email).thenReturn('test@example.com');
    when(() => partner.firstName).thenReturn('Test');
    when(() => partner.lastName).thenReturn('User');
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    group('AuthCheckRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when no token exists',
        build: () {
          when(() => secureStorage.read(key: any(named: 'key')))
              .thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthCheckRequested()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthUnauthenticated>(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when token exists',
        build: () {
          when(() => secureStorage.read(key: 'token'))
              .thenAnswer((_) async => 'test_token');
          when(() => authService.getProfile())
              .thenAnswer((_) async => partner);
          when(() => secureStorage.write(
                key: any(named: 'key'),
                value: any(named: 'value'),
              )).thenAnswer((_) async => {});
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthCheckRequested()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthAuthenticated>(),
        ],
        verify: (_) {
          verify(() => secureStorage.read(key: 'token')).called(1);
          verify(() => authService.getProfile()).called(1);
          verify(() => secureStorage.write(
                key: 'userId',
                value: any(named: 'value'),
              )).called(1);
        },
      );
    });

    group('AuthLoginRequested', () {
      final loginEvent = AuthLoginRequested(
        email: 'test@example.com',
        password: 'password123',
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when login is successful',
        build: () {
          when(() => authService.login(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => AuthResult(
                token: 'test_token',
                refreshToken: 'refresh_token',
                partner: partner,
              ));
          when(() => secureStorage.write(
                key: any(named: 'key'),
                value: any(named: 'value'),
              )).thenAnswer((_) async => {});
          return authBloc;
        },
        act: (bloc) => bloc.add(loginEvent),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthAuthenticated>(),
        ],
        verify: (_) {
          verify(() => authService.login(
                email: loginEvent.email,
                password: loginEvent.password,
              )).called(1);
          verify(() => secureStorage.write(
                key: 'token',
                value: 'test_token',
              )).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthFailure] when login fails',
        build: () {
          when(() => authService.login(
                email: any(named: 'email'),
                password: any(named: 'password'),
              )).thenThrow(Exception('Login failed'));
          return authBloc;
        },
        act: (bloc) => bloc.add(loginEvent),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthFailure>(),
        ],
        verify: (_) {
          verify(() => authService.login(
                email: loginEvent.email,
                password: loginEvent.password,
              )).called(1);
        },
      );
    });

    group('AuthRegisterRequested', () {
      final registerEvent = AuthRegisterRequested(
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        phoneNumber: '+1234567890',
        password: 'password123',
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when registration is successful',
        build: () {
          when(() => authService.register(
                firstName: any(named: 'firstName'),
                lastName: any(named: 'lastName'),
                email: any(named: 'email'),
                phoneNumber: any(named: 'phoneNumber'),
                password: any(named: 'password'),
              )).thenAnswer((_) async => AuthResult(
                token: 'test_token',
                refreshToken: 'refresh_token',
                partner: partner,
              ));
          when(() => secureStorage.write(
                key: any(named: 'key'),
                value: any(named: 'value'),
              )).thenAnswer((_) async => {});
          return authBloc;
        },
        act: (bloc) => bloc.add(registerEvent),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthAuthenticated>(),
        ],
        verify: (_) {
          verify(() => authService.register(
                firstName: registerEvent.firstName,
                lastName: registerEvent.lastName,
                email: registerEvent.email,
                phoneNumber: registerEvent.phoneNumber,
                password: registerEvent.password,
              )).called(1);
          verify(() => secureStorage.write(
                key: 'token',
                value: 'test_token',
              )).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthFailure] when registration fails',
        build: () {
          when(() => authService.register(
                firstName: any(named: 'firstName'),
                lastName: any(named: 'lastName'),
                email: any(named: 'email'),
                phoneNumber: any(named: 'phoneNumber'),
                password: any(named: 'password'),
              )).thenThrow(Exception('Registration failed'));
          return authBloc;
        },
        act: (bloc) => bloc.add(registerEvent),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthFailure>(),
        ],
        verify: (_) {
          verify(() => authService.register(
                firstName: registerEvent.firstName,
                lastName: registerEvent.lastName,
                email: registerEvent.email,
                phoneNumber: registerEvent.phoneNumber,
                password: registerEvent.password,
              )).called(1);
        },
      );
    });

    group('AuthLogoutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when logout is called',
        build: () {
          when(() => secureStorage.delete(key: any(named: 'key')))
              .thenAnswer((_) async => {});
          return authBloc;
        },
        act: (bloc) => bloc.add(AuthLogoutRequested()),
        expect: () => [
          isA<AuthLoading>(),
          isA<AuthUnauthenticated>(),
        ],
        verify: (_) {
          verify(() => secureStorage.delete(key: 'token')).called(1);
          verify(() => secureStorage.delete(key: 'refresh_token')).called(1);
          verify(() => secureStorage.delete(key: 'token_expiry')).called(1);
          verify(() => secureStorage.delete(key: 'userId')).called(1);
        },
      );
    });
  });
} 