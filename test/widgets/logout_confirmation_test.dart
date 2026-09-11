import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/adaptive_logout_confirmation.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final dark in [false, true]) {
    for (final action in ['Cancel', 'Log out', 'Close']) {
      testWidgets('desktop logout $action dark=$dark', (tester) async {
        tester.view.physicalSize = const Size(1100, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        bool? result;
        await tester.pumpWidget(MaterialApp(
          theme: (dark ? ThemeData.dark() : ThemeData.light())
              .copyWith(platform: TargetPlatform.windows),
          home: Builder(builder: (context) => Scaffold(
            body: TextButton(onPressed: () async {
              result = await showAdaptiveLogoutConfirmation(context);
            }, child: const Text('Open')),
          )),
        ));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Log out of Farm Estates?'), findsOneWidget);
        final cancel = tester.getSize(find.widgetWithText(OutlinedButton, 'Cancel'));
        final confirm = tester.getSize(find.widgetWithText(FilledButton, 'Log out'));
        expect(cancel.width, confirm.width);
        if (action == 'Close') {
          await tester.tap(find.byTooltip('Close'));
        } else {
          await tester.tap(find.text(action));
        }
        await tester.pumpAndSettle();
        expect(result, action == 'Log out');
        expect(find.text('Log out of Farm Estates?'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
