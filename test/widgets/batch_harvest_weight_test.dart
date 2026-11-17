import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/models/batch/batch_model.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/batch_edit_dialog.dart';
import 'package:farmestates_ai_dashbaord/services/superadmin_api_service.dart';

class HarvestApi extends SuperAdminApiService {
  Map<String, dynamic>? saved;
  @override
  Future<List<Map<String, dynamic>>> getBatches() async => [];
  @override
  Future<Map<String, dynamic>> updateBatch(
      {required String id, required Map<String, dynamic> data}) async {
    saved = data;
    return data;
  }
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final width in [390.0, 1200.0]) {
    testWidgets('harvest weight recalculates and saves at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = HarvestApi();
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(
              platform: width < 600
                  ? TargetPlatform.android
                  : TargetPlatform.windows),
          home: Builder(
              builder: (context) => Scaffold(
                      body: TextButton(
                    child: const Text('Edit'),
                    onPressed: () => showBatchEditDialog(
                      context: context,
                      api: api,
                      updatedBy: 'admin',
                      updatedByRole: 'admin',
                      onUpdated: () async {},
                      batch: BatchModel(
                          id: 'b',
                          batchNumber: 'BL 17-11-2026-1',
                          farmId: 'f',
                          farmName: 'Farm',
                          farmManagerId: 'm',
                          farmManagerName: 'Manager',
                          plantType: 'Lettuce',
                          plantVariety: 'Batavia',
                          startDate: DateTime(2026, 11, 17),
                          endDate: DateTime(2026, 12, 29),
                          plantMaturityDays: 42,
                          createdAt: DateTime(2026, 11, 17),
                          harvestedHeads: 10,
                          harvestedWeight: 1.2345,
                          metadata: {
                            'crop_variety_id': 'a',
                            'plant_type_ID': 'p'
                          }),
                      cropVarieties: const [
                        {
                          r'$id': 'a',
                          'plant_type_ID': 'p',
                          'variety_name': 'Batavia',
                          'harvesting_weight': 113
                        },
                        {
                          r'$id': 'e',
                          'plant_type_ID': 'p',
                          'variety_name': 'Eden',
                          'harvesting_weight': 20
                        },
                      ],
                    ),
                  )))));
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      Finder field(String label) => find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.hintText == label);
      String weight() =>
          tester.widget<TextField>(field('Weight (kg)')).controller!.text;
      expect(weight(), '1.2345',
          reason: 'Opening the modal must preserve actual saved weight');
      expect(tester.widget<TextField>(field('Weight (kg)')).readOnly, true);
      await tester.ensureVisible(field('Harvested'));
      await tester.enterText(field('Harvested'), '100');
      await tester.pump();
      expect(weight(), '11.3');
      await tester.enterText(field('Harvested'), '');
      await tester.pump();
      expect(weight(), '');
      await tester.enterText(field('Harvested'), '0');
      await tester.pump();
      expect(weight(), '0');
      await tester.enterText(field('Harvested'), '100');
      await tester.pump();
      final variety = find.byType(DropdownButtonFormField<String>).first;
      await tester.ensureVisible(variety);
      await tester.tap(variety);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eden').last);
      await tester.pumpAndSettle();
      expect(weight(), '2');
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(api.saved?['total_weight_kg'], 2);
      expect(api.saved?['calculate_harvest_weight'], true);
      expect(api.saved?['crop_variety_id'], 'e');
      expect(tester.takeException(), isNull);
    });
  }
}
