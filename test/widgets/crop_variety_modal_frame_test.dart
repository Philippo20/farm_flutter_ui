import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/crop_variety_modal_frame.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/app_bottom_sheet.dart';

void main() {
  for (final keyboard in [0.0, 300.0]) {
    testWidgets('Mobile crop form keeps actions above keyboard $keyboard',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => showAppBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => CropVarietyModalFrame(
                              mobile: true,
                              isDark: false,
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Padding(
                                        padding: EdgeInsets.all(24),
                                        child: Text('Edit Crop Variety')),
                                    Flexible(
                                        child: SingleChildScrollView(
                                            child: Column(
                                                children: List.generate(
                                                    15,
                                                    (i) => Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(14),
                                                        child: TextFormField(
                                                            initialValue:
                                                                '$i')))))),
                                    Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Row(children: [
                                          Expanded(
                                              child: TextButton(
                                                  onPressed: () {},
                                                  child: const Text('Cancel'))),
                                          Expanded(
                                              child: FilledButton(
                                                  onPressed: () {},
                                                  child: const Text(
                                                      'Update Variety'))),
                                        ])),
                                  ]))),
                      child: const Text('Open'))))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(tester.getRect(find.text('Update Variety')).bottom,
          lessThanOrEqualTo(800 - keyboard));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
