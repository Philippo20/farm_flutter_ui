import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/batch_date_picker.dart';

void main() {
  for (final width in [320.0, 800.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('batch date selection at $width dark=$dark', (tester) async {
        GoogleFonts.config.allowRuntimeFetching = false;
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        DateTime? selected;
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
              platform: width < 1000
                  ? TargetPlatform.android
                  : TargetPlatform.windows),
          home: Builder(
              builder: (context) => Scaffold(
                      body: TextButton(
                    onPressed: () async {
                      selected = await showBatchDatePicker(
                          context: context,
                          initialDate: DateTime(2026, 9, 11),
                          firstDate: DateTime(2026, 9, 1),
                          lastDate: DateTime(2027));
                    },
                    child: const Text('Open'),
                  ))),
        ));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Fri, 11 Sep 2026'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final picker =
            tester.widget<SfDateRangePicker>(find.byType(SfDateRangePicker));
        picker.onSelectionChanged!(
            DateRangePickerSelectionChangedArgs(DateTime(2026, 9, 18)));
        await tester.pumpAndSettle();
        expect(find.text('Fri, 18 Sep 2026'), findsOneWidget);
        await tester.tap(find.text('Apply date'));
        await tester.pumpAndSettle();
        expect(selected, DateTime(2026, 9, 18));
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(selected, isNull);
      });
    }
  }
}
