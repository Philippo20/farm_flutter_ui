import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/models/batch/batch_model.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/batch_edit_dialog.dart';
import 'package:farmestates_ai_dashbaord/services/superadmin_api_service.dart';

class _BatchApi extends SuperAdminApiService {
  Map<String, dynamic>? saved;

  @override
  Future<List<Map<String, dynamic>>> getBatches() async => [];

  @override
  Future<Map<String, dynamic>> updateBatch({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    saved = data;
    return {'id': id, ...data};
  }
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final scenario in [
    (size: const Size(320, 800), keyboard: 300.0),
    (size: const Size(390, 844), keyboard: 340.0),
    (size: const Size(800, 600), keyboard: 240.0),
  ]) {
    testWidgets(
        'batch notes and actions stay above keyboard at ${scenario.size}',
        (tester) async {
      tester.view.physicalSize = scenario.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final api = _BatchApi();
      var refreshed = false;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showBatchEditDialog(
                context: context,
                api: api,
                batch: BatchModel(
                  id: 'batch-1',
                  batchNumber: 'FARM-20261001',
                  farmId: 'farm-1',
                  farmName: 'Farm One',
                  farmManagerId: 'manager-1',
                  farmManagerName: 'Manager',
                  plantType: 'Lettuce',
                  plantVariety: 'Batavia',
                  startDate: DateTime(2026, 10, 1),
                  endDate: DateTime(2026, 11, 12),
                  plantMaturityDays: 42,
                  createdAt: DateTime(2026, 10, 1),
                ),
                cropVarieties: const [],
                updatedBy: 'admin-1',
                updatedByRole: 'Admin',
                onUpdated: () async => refreshed = true,
              ),
              child: const Text('Edit batch'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Edit batch'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      final notes = find.byWidgetPredicate(
          (widget) => widget is TextField && widget.maxLines == 3);
      await tester.ensureVisible(notes);
      await tester.tap(notes);
      tester.view.viewInsets = FakeViewPadding(bottom: scenario.keyboard);
      await tester.pumpAndSettle();
      await tester.enterText(
          notes, 'Check irrigation pressure\nInspect the pump');
      await tester.pumpAndSettle();

      final keyboardTop = scenario.size.height - scenario.keyboard;
      final notesRect = tester.getRect(notes);
      final saveRect =
          tester.getRect(find.widgetWithText(FilledButton, 'Save Changes'));
      expect(notesRect.top,
          greaterThan(tester.getBottomLeft(find.text('Edit Batch')).dy));
      expect(notesRect.bottom, lessThanOrEqualTo(saveRect.top));
      expect(saveRect.bottom, lessThanOrEqualTo(keyboardTop));
      expect(
          tester.getBottomRight(find.text('Cancel')).dy, lessThan(keyboardTop));
      expect(tester.takeException(), isNull);

      // Save directly while the keyboard is still visible.
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(api.saved?['technical_issues'],
          'Check irrigation pressure\nInspect the pump');
      expect(refreshed, isTrue);
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
