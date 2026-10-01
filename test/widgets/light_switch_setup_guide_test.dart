import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/light_switch_setup_guide.dart';

void main() {
  for (final mobile in [true, false]) {
    testWidgets(
        'Setup guide scrolls and copies on ${mobile ? 'mobile' : 'desktop'}',
        (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      tester.view.physicalSize = Size(mobile ? 360 : 1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? copied;
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData')
          copied = (call.arguments as Map)['text'] as String;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(
              platform:
                  mobile ? TargetPlatform.android : TargetPlatform.windows),
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                      onPressed: () =>
                          showLightSwitchSetupGuide(context, 'LIGHT-001'),
                      child: const Text('Open'))))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Switch setup guide'), findsOneWidget);
      expect(find.byType(BottomSheet), mobile ? findsOneWidget : findsNothing);
      await tester.tap(find.text('Copy guide'));
      await tester.pumpAndSettle();
      expect(copied, contains('/switches/LIGHT-001/poll'));
      expect(copied, contains('/switches/LIGHT-001/ack'));
      expect(copied, contains('YOUR_FARM_SENSOR_KEY'));
      await tester.drag(
          find.byType(SingleChildScrollView).last, const Offset(0, -1800));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Switch setup guide'), findsNothing);
    });
  }
}
