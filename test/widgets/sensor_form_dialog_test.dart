import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/app_dialog.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/sensor_form_dialog.dart';

void main() {
  for (final width in [320.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('sensor form $width dark=$dark keeps actions visible',
          (tester) async {
        GoogleFonts.config.allowRuntimeFetching = false;
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        var saving = false;
        var saves = 0;
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light,
                platform: width < 600
                    ? TargetPlatform.android
                    : TargetPlatform.windows),
            home: Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        child: const Text('Open'),
                        onPressed: () => showAppDialog<void>(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => StatefulBuilder(
                                builder: (context, setState) =>
                                    SensorFormDialog(
                                        editing: true,
                                        saving: saving,
                                        onSave: () => setState(() {
                                              saving = true;
                                              saves++;
                                            }),
                                        child: Column(
                                            children: List.generate(
                                                8,
                                                (i) => i == 0
                                                    ? SwitchListTile.adaptive(
                                                        title: const Text(
                                                            'Alerts enabled'),
                                                        value: true,
                                                        onChanged: (_) {},
                                                        contentPadding:
                                                            EdgeInsets.zero,
                                                      )
                                                    : Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                bottom: 14),
                                                        child: SensorFormRow(
                                                            children: [
                                                              Expanded(
                                                                  child: TextFormField(
                                                                      decoration:
                                                                          InputDecoration(
                                                                              labelText: 'Value $i'))),
                                                              const SizedBox(
                                                                  width: 10),
                                                              Expanded(
                                                                  child: TextFormField(
                                                                      decoration:
                                                                          InputDecoration(
                                                                              labelText: 'Unit $i'))),
                                                            ]))))))))))));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        if (width < 600) {
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pumpAndSettle();
          expect(tester.getBottomRight(find.text('Update')).dy, lessThan(600));
        }
        expect(tester.takeException(), isNull);
        final footerY = tester.getTopLeft(find.text('Update')).dy;
        await tester.drag(
            find.byType(SingleChildScrollView).first, const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('Update')).dy, footerY);
        expect(tester.getSize(find.byType(OutlinedButton)).width,
            tester.getSize(find.byType(FilledButton)).width);
        await tester.tap(find.text('Update'));
        await tester.pump();
        expect(find.text('Saving…'), findsOneWidget);
        expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
            isNull);
        expect(saves, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
