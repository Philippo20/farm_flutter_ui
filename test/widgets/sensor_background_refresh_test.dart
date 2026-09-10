import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/sensor_reading_history.dart';

void main() {
  testWidgets('Automatic refresh retains chart and controls without a spinner',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final refresh = Completer<List<Map<String, dynamic>>>();
    var calls = 0;
    final rows = [
      {'value': 25, 'unit': 'C', 'timestamp': '2026-09-10T12:00:00Z'}
    ];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: SensorReadingHistory(
                    serialNumber: 'TEMP-1',
                    loadReadings: (_) async {
                      calls++;
                      return calls == 1 ? rows : refresh.future;
                    })))));
    await tester.pumpAndSettle();
    expect(find.byType(BarChart), findsOneWidget);
    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(calls, 2);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(BarChart), findsOneWidget);
    expect(
        tester
            .widget<IconButton>(find.byWidgetPredicate((widget) =>
                widget is IconButton && widget.tooltip == 'Refresh readings'))
            .onPressed,
        isNotNull);
    refresh.completeError(Exception('network interruption'));
    await tester.pumpAndSettle();
    expect(find.byType(BarChart), findsOneWidget);
    expect(find.text('Unable to refresh readings. Please try again.'),
        findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
