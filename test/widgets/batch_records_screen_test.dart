import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/screens/farm_manager/batch_records_screen.dart';

void main() {
  for (final width in [360.0, 1200.0]) {
    testWidgets('Caretaker records and details at $width', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          home: BatchRecordsScreen(
              batchId: 'a',
              batchNumber: 'BATCH-001',
              farmName: 'Farm A',
              loadRecords: () async => [
                    {
                      'record_id': 'FR-001',
                      'record_date': '2026-10-01T10:00:00Z',
                      'created_by_name': 'Caretaker A',
                      'record_type': 'daily',
                      'growth_stage': 'Vegetative',
                      'temperature': 0,
                      'observations': 'Healthy plants',
                      'has_issues': false
                    },
                    {
                      'record_id': 'FR-002',
                      'record_date': '2026-10-01T11:00:00Z',
                      'created_by_name': 'Caretaker B',
                      'record_type': 'inspection',
                      'has_issues': true,
                      'issue_severity': 'high',
                      'issue_description': 'Pump needs repair'
                    },
                  ])));
      await tester.pumpAndSettle();
      expect(find.text('BATCH-001'), findsOneWidget);
      expect(
          find.byType(DataTable), width > 900 ? findsOneWidget : findsNothing);
      await tester.tap(find.text('View record').first);
      await tester.pumpAndSettle();
      expect(find.text('Record details'), findsOneWidget);
      expect(find.text('Healthy plants'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      await tester.tap(find.byTooltip('Close details'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Issues only'));
      await tester.pumpAndSettle();
      expect(find.text('View record'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'missing');
      await tester.pumpAndSettle();
      expect(find.text('No records match your filters.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
