import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:farmestates_ai_dashbaord/widgets/cards/farm/second_row.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets(
      'Three temperature sensors form a pair and a single with separate chart data',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: SizedBox(
                    width: 320,
                    child: SecondRow(
                      isDark: false,
                      sensors: [
                        for (var i = 0; i < 3; i++)
                          {
                            'id': 's$i',
                            'serial_number': 'TEMP-$i',
                            'sensortype': 'temperature',
                            'unit': 'C'
                          }
                      ],
                      readings: [
                        for (var i = 0; i < 3; i++)
                          for (var sample = 0; sample < 5; sample++) {
                            'sensor_id': 's$i',
                            'value': 20 + i,
                            'unit': 'C',
                            'timestamp': '2026-09-15T12:00:0${sample}Z'
                          }
                      ],
                    ))))));
    final charts =
        tester.widgetList<LineChart>(find.byType(LineChart)).toList();
    expect(charts.length, 2);
    expect(charts[0].data.lineBarsData.length, 2);
    expect(charts[0].data.lineBarsData[0].spots.last.y, .5);
    expect(charts[0].data.lineBarsData[1].spots.last.y, .5);
    expect(charts[1].data.lineBarsData.single.spots.last.y, 22);
    expect(find.text('Serial: P-0'), findsOneWidget);
    expect(find.text('Serial: P-1'), findsOneWidget);
    expect(find.text('Serial: P-2'), findsOneWidget);
    for (final chart in charts) {
      for (final bar in chart.data.lineBarsData) {
        final painter = bar.dotData.getDotPainter(bar.spots.last, 100, bar, 4) as FlDotCirclePainter;
        expect(painter.color, bar.color);
      }
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
