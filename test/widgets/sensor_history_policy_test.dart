import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/utils/sensor_calibration_policy.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/sensor_reading_history.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/sensor_inspect_modal.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  test('Calibration rules normalize types and respect explicit metadata', () {
    expect(sensorRequiresCalibration({'type': 'Temperature'}), false);
    for (final type in ['pH Level', 'EC Level', 'tds', 'conductivity']) {
      expect(sensorRequiresCalibration({'type': type}), true);
    }
    expect(sensorRequiresCalibration({'type': 'humidity'}), isNull);
    expect(
        sensorRequiresCalibration(
            {'type': 'temperature', 'calibration_required': true}),
        true);
  });
  testWidgets('Temperature Inspect has no calibration action', (tester) async {
    await tester.pumpWidget(
        MaterialApp(home: SensorInspectModal(sensor: {'type': 'temperature'})));
    expect(find.text('Calibrate'), findsNothing);
    expect(
        find.text('Routine calibration is not required for this sensor type.'),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'History loads actual rows, refreshes and preserves rows on error',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pending = Completer<List<Map<String, dynamic>>>();
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: SensorReadingHistory(
                    serialNumber: 'TEMP-123',
                    loadReadings: (serial) {
                      expect(serial, 'TEMP-123');
                      calls++;
                      if (calls > 1) throw Exception('offline');
                      return pending.future;
                    })))));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete([
      {
        'value': 23.7,
        'unit': 'C',
        'timestamp': '2026-09-10T12:00:00Z',
        'status': 'Active',
        'source': 'ingest'
      }
    ]);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show reading records'));
    await tester.pumpAndSettle();
    expect(find.text('23.7 C'), findsOneWidget);
    await tester.tap(find.byTooltip('Refresh readings'));
    await tester.pumpAndSettle();
    expect(find.text('Unable to refresh readings. Please try again.'),
        findsOneWidget);
    expect(find.text('23.7 C'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 31));
    expect(calls, 2);
  });
}
