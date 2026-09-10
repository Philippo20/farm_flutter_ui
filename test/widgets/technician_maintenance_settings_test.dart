import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmestates_ai_dashbaord/core/theme/app_theme.dart';
import 'package:farmestates_ai_dashbaord/screens/technician/maintenance_schedule_screen.dart';
import 'package:farmestates_ai_dashbaord/screens/technician/technician_settings_screen.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });
  for (final width in [320.0, 800.0, 1440.0]) {
    for (final settings in [false, true]) {
      testWidgets(
          '${settings ? 'Settings' : 'Maintenance'} at $width supports dark mode and long content',
          (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(ProviderScope(
            child: MaterialApp(
                theme: AppTheme.darkTheme,
                home: settings
                    ? const TechnicianSettingsScreen()
                    : MaintenanceScheduleScreen(
                        loadData: () async => [
                              [
                                {
                                  'title':
                                      'Inspect and repair the north greenhouse nutrient delivery equipment',
                                  'description':
                                      'Check the complete system and verify every connection before returning the equipment to service.',
                                  'farm_name':
                                      'North greenhouse extension and propagation area',
                                  'status': 'Completed',
                                  'priority': 'High',
                                  'assigned_to_name':
                                      'Assigned technician with a long name',
                                  'due_date': '2026-09-10'
                                }
                              ],
                              [
                                {
                                  'message':
                                      'Temperature probe needs inspection',
                                  'severity': 'High',
                                  'status': 'Reported',
                                  'farm_name': 'North greenhouse'
                                }
                              ]
                            ]))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (settings) {
          expect(find.text('Appearance'), findsOneWidget);
          expect(find.text('Alerts'), findsOneWidget);
          await tester.drag(
              find.byType(SingleChildScrollView).first, const Offset(0, -1500));
          await tester.pumpAndSettle();
          expect(find.text('Biometric unlock'), findsOneWidget);
        } else {
          expect(find.text('Maintenance overview'), findsOneWidget);
          await tester
              .tap(find.text(width < 768 ? 'Issues' : 'Technical Issues'));
          await tester.pumpAndSettle();
          expect(
              find.text('Temperature probe needs inspection'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
