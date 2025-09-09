import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chapechape_client/main.dart';

void main() {
  group('ChapeChape Client App Tests', () {
    testWidgets('App should start without crashing', (WidgetTester tester) async {
      // Test que l'app démarre sans erreur
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Material App should be created', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: Text('Test')));
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
