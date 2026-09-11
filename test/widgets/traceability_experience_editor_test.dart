import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/traceability_experience_editor.dart';

void main() {
  for (final width in [320.0, 800.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('experience settings at $width dark=$dark', (tester) async {
        GoogleFonts.config.allowRuntimeFetching = false;
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controllers = {
          for (final key in [
            'brand',
            'headline',
            'logo',
            'site',
            'primary',
            'secondary',
            'email',
            'privacy'
          ])
            key: TextEditingController(text: key == 'primary' ? '#4CAF50' : '')
        };
        addTearDown(() {
          for (final controller in controllers.values) {
            controller.dispose();
          }
        });
        String? changedKey;
        bool? changedValue;
        var saves = 0;
        var saving = false;
        late StateSetter update;
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
              platform: width < 1000
                  ? TargetPlatform.android
                  : TargetPlatform.windows),
          home: MediaQuery(
              data: MediaQueryData(
                  size: Size(width, 900), textScaler: TextScaler.linear(1.3)),
              child: Scaffold(
                  body: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: StatefulBuilder(builder: (context, setState) {
                        update = setState;
                        return TraceabilityExperienceEditor(
                            controllers: controllers,
                            settings: const {},
                            saving: saving,
                            onSave: () => saves++,
                            onToggle: (key, value) {
                              changedKey = key;
                              changedValue = value;
                            });
                      })))),
        ));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNWidgets(8));
        expect(find.byType(Switch), findsNWidgets(10));
        expect(tester.takeException(), isNull);
        final firstToggle = find.byType(Switch).first;
        await tester.ensureVisible(firstToggle);
        await tester.tap(firstToggle);
        expect(changedKey, 'lookup_enabled');
        expect(changedValue, false);
        final save = find.text('Save experience');
        await tester.ensureVisible(save);
        await tester.tap(save);
        expect(saves, 1);
        update(() => saving = true);
        await tester.pump();
        expect(find.text('Saving changes...'), findsOneWidget);
        expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
            isNull);
        expect(tester.widget<TextField>(find.byType(TextField).first).enabled,
            isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
