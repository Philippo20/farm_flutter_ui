import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/app_bottom_sheet.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
        'Sheet colors the gesture inset and removes its style on close, dark=$dark',
        (tester) async {
      final color = dark ? const Color(0xFF182820) : Colors.white;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.green,
                    brightness: dark ? Brightness.dark : Brightness.light)
                .copyWith(surface: color)),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(bottom: 24),
                viewPadding: const EdgeInsets.only(bottom: 24)),
            child: child!),
        home: Builder(
            builder: (context) => Scaffold(
                  body: TextButton(
                      child: const Text('Open'),
                      onPressed: () => showAppBottomSheet<void>(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (context) => SafeArea(
                                top: false,
                                child: SizedBox(
                                    height: 150,
                                    child: Center(
                                        child: TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Close'))))),
                          )),
                )),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final region = find.byWidgetPredicate((widget) =>
          widget is AnnotatedRegion<SystemUiOverlayStyle> &&
          widget.value.systemNavigationBarColor == color &&
          widget.value.systemNavigationBarContrastEnforced == false);
      expect(region, findsOneWidget);
      final style =
          tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(region).value;
      expect(style.systemNavigationBarIconBrightness,
          dark ? Brightness.light : Brightness.dark);
      final surface = find.descendant(
          of: region,
          matching: find.byWidgetPredicate((widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == color &&
              (widget.decoration as BoxDecoration).borderRadius ==
                  const BorderRadius.vertical(top: Radius.circular(24))));
      expect(surface, findsOneWidget);
      // The existing 24px safe area is colored, with no second inset added.
      expect(tester.getSize(surface).height, 174);
      expect(tester.getBottomLeft(surface).dy,
          tester.view.physicalSize.height / tester.view.devicePixelRatio);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(region, findsNothing);
    });
  }
}
