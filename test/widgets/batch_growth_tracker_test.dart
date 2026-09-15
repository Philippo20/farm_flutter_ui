import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/widgets/cards/farm/batch_growth_tracker.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets('Selecting a batch updates the recorded growth stage',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: SizedBox(
                    width: 280,
                    child: BatchGrowthTracker(batches: [
                      {
                        'id': 'a',
                        'batch_no': 'BATCH-001',
                        'production_status': 'Growing'
                      },
                      {
                        'id': 'b',
                        'batch_no': 'BATCH-002',
                        'production_status': 'Harvested'
                      },
                    ], records: [
                      {
                        'batch_id': 'a',
                        'growth_stage': 'Vegetative',
                        'record_date': '2026-09-15'
                      },
                      {
                        'batch_id': 'other',
                        'growth_stage': 'Wrong stage',
                        'record_date': '2026-09-16'
                      },
                    ]))))));
    expect(find.text('Vegetative'), findsOneWidget);
    expect(find.text('Wrong stage'), findsNothing);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BATCH-002').last);
    await tester.pumpAndSettle();
    expect(find.text('Harvested'), findsOneWidget);
    expect(find.text('Vegetative'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
