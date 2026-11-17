import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/screens/fulfillment/fulfillment_manager_dashboard_redesigned.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final width in [320.0, 1200.0]) {
    testWidgets('harvest pagination and refresh remain usable at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final rows = List.generate(
          9,
          (i) => <String, dynamic>{
                r'$id': '$i',
                'batch_no': 'BATCH-${i + 1}',
                'farm_name': 'Farm One',
                'plant_name': 'Lettuce',
                'plant_variety': 'Batavia',
                'total_seeds_nursed': 100,
                'total_transplanted': 90,
                'total_harvested': 0,
              });
      Future<void> show(List<Map<String, dynamic>> batches) async {
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: AwaitingHarvestBatches(batches: batches)))));
        await tester.pumpAndSettle();
      }

      Future<void> next() async {
        await tester.ensureVisible(find.byTooltip('Next harvest page'));
        await tester.tap(find.byTooltip('Next harvest page'));
        await tester.pumpAndSettle();
      }

      await show(rows);
      expect(find.text('1–4 of 9 batches'), findsOneWidget);
      expect(find.text('BATCH-4'), findsOneWidget);
      expect(find.text('BATCH-5'), findsNothing);
      expect(
          tester
              .widget<IconButton>(find.byWidgetPredicate((w) =>
                  w is IconButton && w.tooltip == 'Previous harvest page'))
              .onPressed,
          isNull);
      await next();
      expect(find.text('5–8 of 9 batches'), findsOneWidget);
      expect(find.text('BATCH-1'), findsNothing);
      await next();
      expect(find.text('Page 3 of 3'), findsOneWidget);
      expect(find.text('BATCH-9'), findsOneWidget);
      expect(
          tester
              .widget<IconButton>(find.byWidgetPredicate(
                  (w) => w is IconButton && w.tooltip == 'Next harvest page'))
              .onPressed,
          isNull);
      await show(List.of(rows));
      expect(find.text('Page 3 of 3'), findsOneWidget,
          reason: 'Refresh preserves the selected page');
      await show(rows.take(5).toList());
      expect(find.text('5–5 of 5 batches'), findsOneWidget);
      expect(find.text('Page 2 of 2'), findsOneWidget);
      await tester.ensureVisible(find.byType(DropdownButton<int>));
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('8').last);
      await tester.pumpAndSettle();
      expect(find.text('1–5 of 5 batches'), findsOneWidget);
      expect(find.text('Page 1 of 1'), findsOneWidget);
      await show([]);
      expect(find.text('No batches are awaiting harvest'), findsOneWidget);
      expect(find.byTooltip('Next harvest page'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
