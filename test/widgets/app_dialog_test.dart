import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/app_dialog.dart';

void main() {
  for (final scenario in [
    (320.0, TargetPlatform.iOS, true),
    (800.0, TargetPlatform.android, true),
    (1200.0, TargetPlatform.windows, false),
  ]) {
    testWidgets('Responsive modal ${scenario.$1} ${scenario.$2}',
        (tester) async {
      tester.view.physicalSize = Size(scenario.$1, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      int? result;
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(platform: scenario.$2),
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      child: const Text('Open'),
                      onPressed: () async {
                        result = await showAppDialog<int>(
                            context: context,
                            builder: (modalContext) => StatefulBuilder(
                                builder: (_, setState) => AppDialog(
                                        child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                          const Padding(
                                              padding: EdgeInsets.all(24),
                                              child: Text('Delivery')),
                                          Flexible(
                                              child: SingleChildScrollView(
                                                  child: Column(
                                                      children: List.generate(
                                                          12,
                                                          (i) => Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(14),
                                                              child: TextFormField(
                                                                  initialValue:
                                                                      '$i')))))),
                                          Padding(
                                              padding: const EdgeInsets.all(24),
                                              child: FilledButton(
                                                  onPressed: () =>
                                                      Navigator.of(modalContext)
                                                          .pop(7),
                                                  child: const Text('Save'))),
                                        ]))));
                      })))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet),
          scenario.$3 ? findsOneWidget : findsNothing);
      expect(tester.takeException(), isNull);
      if (scenario.$3) {
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        expect(tester.getRect(find.text('Save')).bottom, lessThan(500));
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(result, 7);
      expect(find.text('Delivery'), findsNothing);
    });
  }
  testWidgets('Alert content scrolls while actions remain visible',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showAppDialog<void>(
                        context: context,
                        builder: (context) => AppAlertDialog(
                                title: const Text('Settings'),
                                content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                        20,
                                        (i) => Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Text('Setting $i')))),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Done'))
                                ])),
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(tester.getRect(find.text('Done')).bottom, lessThan(640));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
  });
}
