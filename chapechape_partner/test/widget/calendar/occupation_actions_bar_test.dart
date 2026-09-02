import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chapechape_partner/core/models/calendar/partner_calendar.dart';
import 'package:chapechape_partner/presentation/widgets/calendar/occupation_actions_bar.dart';

void main() {
  PartnerOccupation occ(CalendarSourceType source) => PartnerOccupation(
        id: 'abc',
        sourceType: source,
        status: CalendarOccupationStatus.reserved,
        start: DateTime.utc(2027, 8, 10),
        end: DateTime.utc(2027, 8, 15),
        bookingType: 'day',
        reservationStatus: 'confirmed',
      );

  testWidgets('does not show Débloquer for a ChapeChape reservation', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OccupationActionsBar(
          occupation: occ(CalendarSourceType.reservation),
          hasRange: false,
          onViewReservation: () {},
          onUnblock: () {},
        ),
      ),
    ));
    expect(find.text('Voir la réservation'), findsOneWidget);
    expect(find.text('Débloquer'), findsNothing);
  });

  testWidgets('shows Débloquer only for manual block', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OccupationActionsBar(
          occupation: occ(CalendarSourceType.manualBlock),
          hasRange: false,
          onUnblock: () {},
          onViewBlock: () {},
        ),
      ),
    ));
    expect(find.text('Débloquer'), findsOneWidget);
  });
}
