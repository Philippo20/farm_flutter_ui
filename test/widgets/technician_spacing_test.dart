import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/screens/technician/repair_history_screen.dart';
import 'package:farmestates_ai_dashbaord/screens/technician/technician_settings_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  for (final page in [
    RepairHistoryScreen(
        loadRecords: () async => List.generate(
            8,
            (i) => {
                  'title': 'Repair task $i',
                  'status': 'Completed',
                  'description': 'Recorded maintenance task',
                  'farm_name': 'North farm'
                })),
    const TechnicianSettingsScreen()
  ]) {
    testWidgets('${page.runtimeType} ends with a 16px mobile gap',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ProviderScope(child: MaterialApp(home: page)));
      await tester.pumpAndSettle();
      final finder = find.byType(SingleChildScrollView).last;
      final scroll = tester.widget<SingleChildScrollView>(finder);
      await tester.drag(finder, const Offset(0, -4000));
      await tester.pumpAndSettle();
      final gap = tester.getRect(finder).bottom -
          tester.getRect(find.byWidget(scroll.child!)).bottom;
      expect(gap, closeTo(16, .1));
      expect(tester.takeException(), isNull);
    });
  }
}
