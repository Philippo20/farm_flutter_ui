import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/utils/sensor_thresholds.dart';
import 'package:farmestates_ai_dashbaord/core/theme/app_colors.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/sensor_readings_chart.dart';

void main() {
  const sensor = {
    'range_min': 20,
    'range_max': 30,
    'warning_min': 15,
    'warning_max': 35,
    'unit': 'C'
  };
  test('Good range includes both boundaries; everything outside is bad', () {
    final policy = SensorThresholds(sensor, 'C');
    expect(
        [14, 15, 19, 20, 30, 31, 35, 36]
            .map((v) => policy.classify(v.toDouble())),
        ['Bad', 'Bad', 'Bad', 'Good', 'Good', 'Bad', 'Bad', 'Bad']);
    expect(SensorThresholds({}, 'C').classify(25), 'Unrated');
    expect(SensorThresholds({'range_min': 20, 'unit': 'C'}, 'C').classify(25),
        'Unrated');
    expect(
        SensorThresholds({...sensor, 'warning_min': 26, 'warning_max': 24}, 'C')
            .classify(25),
        'Good');
    expect(SensorThresholds(sensor, 'F').classify(25), 'Unrated');
    expect(SensorThresholds({...sensor, 'range_min': 40}, 'C').classify(25),
        'Unrated');
    expect(SensorThresholds({'warning_max': 35, 'unit': 'C'}, 'C').classify(25),
        'Unrated');
  });
  testWidgets('Narrow graph shows threshold band, legend and bar colors',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.physicalSize = const Size(272, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: SensorReadingsChart(sensor: sensor, readings: [
      for (var i = 0; i < 3; i++)
        {
          'value': [25, 32, 38][i],
          'unit': 'C',
          'timestamp': DateTime.utc(2026, 9, 10, 0, i).toIso8601String()
        }
    ])))));
    await tester.pumpAndSettle();
    final data = tester.widget<BarChart>(find.byType(BarChart)).data;
    expect(data.barGroups.map((group) => group.barRods.single.color),
        [AppColors.success, AppColors.error, AppColors.error]);
    expect(data.rangeAnnotations.horizontalRangeAnnotations.single.y1, 20);
    expect(data.rangeAnnotations.horizontalRangeAnnotations.single.y2, 30);
    expect(data.extraLinesData.horizontalLines.length, 2);
    expect(find.text('Good: 20.0 – 30.0 C'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
