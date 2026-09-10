import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/sensor_readings_chart.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final width in [272.0, 452.0]) {
    testWidgets(
        'Chart at $width supports negative, zero, mixed units and long history',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final rows = [
        for (var i = 0; i < 25; i++)
          {
            'value': i - 20,
            'unit': 'C',
            'timestamp': DateTime.utc(2026, 9, 10, 0, i).toIso8601String(),
            'status': 'Active'
          },
        {'value': 'invalid', 'timestamp': 'bad'},
        {'value': 0, 'unit': 'F', 'timestamp': '2026-09-10T00:25:00Z'}
      ];
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(
              brightness: width < 300 ? Brightness.dark : Brightness.light),
          home: Scaffold(
              body: SingleChildScrollView(
                  child: SensorReadingsChart(readings: rows)))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final charts =
          tester.widgetList<BarChart>(find.byType(BarChart)).toList();
      expect(charts.length, 2);
      final celsius = charts.first.data;
      expect(celsius.barGroups.length, 19);
      expect(celsius.barGroups.first.barRods.single.toY, -14);
      expect(celsius.barGroups.last.barRods.single.toY, 4);
      expect(celsius.minY, lessThan(-14));
      expect(celsius.maxY, greaterThan(4));
      final tooltip = celsius.barTouchData.touchTooltipData.getTooltipItem(
          celsius.barGroups.first,
          0,
          celsius.barGroups.first.barRods.single,
          0);
      expect(tooltip!.text, contains('-14 C'));
      expect(tooltip.text, contains('00:06:00'));
      expect(charts.last.data.minY, 0);
      expect(charts.last.data.maxY, greaterThan(0));
      await tester.drag(
          find.byType(SingleChildScrollView).at(1), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Missing readings are not fabricated', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: SensorReadingsChart(readings: [
      {'value': 'NaN', 'timestamp': '2026-09-10'}
    ]))));
    expect(find.byType(BarChart), findsNothing);
    expect(find.text('No numeric readings with valid timestamps to chart.'),
        findsOneWidget);
  });
}
