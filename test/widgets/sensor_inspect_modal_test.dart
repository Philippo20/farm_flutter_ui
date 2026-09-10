import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/app_dialog.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/sensor_inspect_modal.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final config in [
    (320.0, TargetPlatform.iOS),
    (800.0, TargetPlatform.android),
    (1200.0, TargetPlatform.windows)
  ]) {
    testWidgets('Inspect modal scrolls with fixed actions at ${config.$1}',
        (tester) async {
      tester.view.physicalSize = Size(config.$1, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      bool? result;
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(platform: config.$2),
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                      onPressed: () async {
                        result = await showAppDialog<bool>(
                            context: context,
                            builder: (_) => SensorInspectModal(sensor: {
                                  'name':
                                      'North greenhouse nutrient monitoring sensor with a long name',
                                  'id': 'SENSOR-123456789012345678901234567890',
                                  'status': 'offline',
                                  'color': Colors.grey,
                                  'type': 'conductivity',
                                  'value': 1234.56,
                                  'unit': 'microsiemens/cm',
                                  'location':
                                      'Northern farm greenhouse and growing extension',
                                }));
                      },
                      child: const Text('Open'))))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(BottomSheet),
          config.$2 == TargetPlatform.windows ? findsNothing : findsOneWidget);
      final action = find.widgetWithText(FilledButton, 'Calibrate');
      final before = tester.getRect(action);
      expect(before.bottom, lessThanOrEqualTo(700));
      await tester.drag(
          find.byType(SingleChildScrollView).last, const Offset(0, -1200));
      await tester.pumpAndSettle();
      expect(tester.getRect(action), before);
      expect(find.text('Recommended checks'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(find.byType(SensorInspectModal), findsNothing);
    });
  }
}
