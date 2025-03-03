// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:chapechape_partner/core/services/api/api_service.dart';
import 'package:chapechape_partner/core/services/api/auth_service.dart';
import 'package:chapechape_partner/core/services/api/residence_service.dart';
import 'package:chapechape_partner/core/blocs/auth/auth_bloc.dart';
import 'package:chapechape_partner/core/config/app_config.dart';
import 'package:chapechape_partner/router/app_router.dart';

void main() {
  late FlutterSecureStorage storage;
  late ApiService apiService;
  late AuthService authService;
  late ResidenceService residenceService;
  late AuthBloc authBloc;
  late AppRouter appRouter;

  setUp(() {
    storage = const FlutterSecureStorage();
    apiService = ApiService();
    authService = AuthService(apiService.dio);
    residenceService = ResidenceService(baseUrl: AppConfig.apiUrl);
    authBloc = AuthBloc(
      storage: storage,
      authService: authService,
    );
    appRouter = AppRouter(authBloc);
  });

  testWidgets('App should start with MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: appRouter.router,
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
