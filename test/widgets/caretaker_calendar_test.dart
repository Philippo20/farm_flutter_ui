import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:farmestates_ai_dashbaord/screens/caretaker/calendar_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  for (final width in [320.0, 1440.0]) {
    testWidgets('Caretaker calendar navigation at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: CalendarScreen())));
      await tester.pumpAndSettle();
      final now = DateTime.now();
      expect(find.text(DateFormat('MMMM yyyy').format(now)), findsOneWidget);
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(
          find.text(DateFormat('MMMM yyyy')
              .format(DateTime(now.year, now.month + 1))),
          findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Today'));
      await tester.pumpAndSettle();
      expect(find.text(DateFormat('MMMM yyyy').format(now)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
