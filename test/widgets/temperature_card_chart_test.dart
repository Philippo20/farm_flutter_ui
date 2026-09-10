import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/sensor_overview_card.dart';
import 'package:farmestates_ai_dashbaord/core/theme/app_colors.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final width in [280.0, 420.0]) {
    testWidgets(
        'Temperature card graph at $width uses saved readings and thresholds',
        (tester) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var inspected = 0;
      var loads = 0;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SensorOverviewCard(
                        sensor: {
                          'name': 'Greenhouse temperature',
                          'type': 'temperature',
                          'id': 'TEMP-1',
                          'serialNumber': 'TEMP-1',
                          'status': 'normal',
                          'color': AppColors.success,
                          'value': 32,
                          'unit': 'C',
                          'location': 'North greenhouse',
                          'range_min': 20,
                          'range_max': 30
                        },
                        onInspect: () => inspected++,
                        onCalibrate: () {},
                        loadReadings: (serial) async {
                          expect(serial, 'TEMP-1');
                          loads++;
                          return [
                            for (var i = 0; i < 3; i++)
                              {
                                'value': [19, 25, 32][i],
                                'unit': 'C',
                                'timestamp': DateTime.utc(2026, 9, 10, 12, i)
                                    .toIso8601String()
                              }
                          ];
                        },
                      ))))));
      await tester.pumpAndSettle();
      expect(find.text('Recent trend'), findsOneWidget);
      expect(find.text('Calibrate'), findsNothing);
      expect(find.text('Latest reading'), findsNothing);
      expect(find.text('32'), findsNothing);
      expect(find.text('Show reading records'), findsNothing);
      final bars =
          tester.widget<BarChart>(find.byType(BarChart)).data.barGroups;
      expect(bars.map((b) => b.barRods.single.color),
          [AppColors.error, AppColors.success, AppColors.error]);
      expect(bars.last.showingTooltipIndicators, [0]);
      expect(bars.first.showingTooltipIndicators, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Inspect'));
      await tester.tap(find.text('Inspect'));
      expect(inspected, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 31));
      expect(loads, 1);
    });
  }
}
