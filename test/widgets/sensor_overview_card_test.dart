import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/sensor_overview_card.dart';

void main() {
  for (final width in [280.0, 400.0]) {
    for (final dark in [false, true]) {
      testWidgets('Sensor card fits $width, dark=$dark and large text',
          (tester) async {
        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var inspected = 0;
        var calibrated = 0;
        await tester.pumpWidget(MaterialApp(
          theme:
              ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
          home: MediaQuery(
            data: MediaQueryData(
                size: Size(width, 1200),
                textScaler: const TextScaler.linear(1.5)),
            child: Scaffold(
                body: SingleChildScrollView(
                    child: Padding(
              padding: const EdgeInsets.all(16),
              child: SensorOverviewCard(
                sensor: {
                  'id': 'SENSOR-VERY-LONG-SERIAL-12345678901234567890',
                  'name': 'North greenhouse nutrient monitoring sensor',
                  'type': 'conductivity',
                  'status': 'offline',
                  'color': Colors.grey,
                  'value': 1234.56,
                  'unit': 'microsiemens/cm',
                  'location': 'North growing farm and greenhouse extension',
                },
                onInspect: () => inspected++,
                onCalibrate: () => calibrated++,
              ),
            ))),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Last recorded reading'), findsOneWidget);
        expect(find.text('Updated Not available'), findsOneWidget);
        expect(find.text('LIVE'), findsNothing);
        await tester.ensureVisible(find.text('Calibrate'));
        await tester.tap(find.text('Calibrate'));
        expect(calibrated, 1);
        expect(inspected, 0);
        await tester.tap(find.text('Inspect'));
        expect(inspected, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
