import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/app_dialog.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/sensor_date_range_modal.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final width in [320.0, 1200.0]) {
    testWidgets(
        'Range picker at $width keeps actions fixed and applies presets',
        (tester) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      DateTimeRange? selected;
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(
              platform: TargetPlatform.windows,
              brightness: width == 320 ? Brightness.dark : Brightness.light),
          home: Scaffold(
              body: Builder(
                  builder: (context) => TextButton(
                      onPressed: () async {
                        selected = await showAppDialog<DateTimeRange>(
                            context: context,
                            builder: (_) => const SensorDateRangeModal());
                      },
                      child: const Text('Open'))))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet),
          width == 320 ? findsOneWidget : findsNothing);
      final apply = find.widgetWithText(FilledButton, 'Apply range');
      expect(tester.widget<FilledButton>(apply).onPressed, isNull);
      final before = tester.getRect(apply);
      await tester.tap(find.text('Last 7 days'));
      await tester.pumpAndSettle();
      final calendar =
          tester.widget<SfDateRangePicker>(find.byType(SfDateRangePicker));
      expect(
          calendar.controller!.selectedRange!.startDate,
          DateTime(DateTime.now().year, DateTime.now().month,
              DateTime.now().day - 6));
      await tester.drag(
          find.byType(SingleChildScrollView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.getRect(apply), before);
      expect(tester.takeException(), isNull);
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(selected!.end, DateUtils.dateOnly(DateTime.now()));
      expect(find.byType(SensorDateRangeModal), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
