import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/app_dialog.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/device_telemetry_details_modal.dart';

void main() {
  for (final width in [320.0, 800.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('telemetry details at $width dark=$dark', (tester) async {
        GoogleFonts.config.allowRuntimeFetching = false;
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light,
                platform: width < 1000
                    ? TargetPlatform.android
                    : TargetPlatform.windows),
            home: Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () => showAppDialog<void>(
                            context: context,
                            builder: (_) => DeviceTelemetryDetailsModal(
                                loadReadings: (_) async => [],
                                currentDetails: () =>
                                    const DeviceTelemetryDetails(
                                        name:
                                            'North greenhouse temperature and environmental monitoring device',
                                        serial:
                                            'FARM-EXTENSION-NORTH-TEMP-001-LONG-SERIAL',
                                        reading: '25.5 °C',
                                        readingStatus: 'Within normal range',
                                        color: Colors.green,
                                        location: {
                                          'Farm':
                                              'North farm greenhouse and propagation extension',
                                          'Zone': 'Propagation area',
                                          'Online state': 'Online'
                                        },
                                        configuration: {
                                          'Protocol': 'MQTT',
                                          'Normal range': '20–30 °C',
                                          'Maintenance': 'Not configured'
                                        },
                                        sensor: {}))),
                        child: const Text('Open'))))));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Device details'), findsOneWidget);
        expect(find.text('Close'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final closeY = tester.getTopLeft(find.text('Close')).dy;
        await tester.drag(
            find.byType(SingleChildScrollView).first, const Offset(0, -900));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('Close')).dy, closeY);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
        expect(find.text('Device details'), findsNothing);
        await tester.pump(const Duration(seconds: 6));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
