import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/screens/admin/modern_analytics_screen.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final width in [320.0, 800.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('analytics charts $width dark=$dark', (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
          theme: dark ? ThemeData.dark() : ThemeData.light(),
          home: Scaffold(body: SingleChildScrollView(child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: Column(children: [
              AnalyticsTrendChart(title: 'Revenue and production',
                revenueSpots: const [FlSpot(0, 0), FlSpot(1, 100), FlSpot(5, 50)],
                productionSpots: const [FlSpot(0, 25), FlSpot(1, 50), FlSpot(5, 80)],
                isDark: dark),
              AnalyticsSensorReliabilityChart(isDark: dark, bars: const [
                AnalyticsBarMetric('Temperature', 95, Colors.green),
                AnalyticsBarMetric('Humidity', 60, Colors.orange),
                AnalyticsBarMetric('Vapor pressure deficit', 20, Colors.red),
                AnalyticsBarMetric('Electrical conductivity', 80, Colors.green),
              ]),
            ]),
          ))),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final line = tester.widget<LineChart>(find.byType(LineChart)).data;
        expect(line.lineBarsData[0].color, isNot(line.lineBarsData[1].color));
        final bars = tester.widget<BarChart>(find.byType(BarChart)).data;
        expect(bars.barGroups.length, 4);
        final tip = bars.barTouchData.touchTooltipData.getTooltipItem(
          bars.barGroups[0], 0, bars.barGroups[0].barRods[0], 0);
        expect(tip!.text, contains('95% telemetry health'));
      });
    }
  }
}
