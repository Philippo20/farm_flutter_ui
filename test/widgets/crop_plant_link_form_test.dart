import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/providers/auth_provider.dart';
import 'package:farmestates_ai_dashbaord/services/superadmin_api_service.dart';
import 'package:farmestates_ai_dashbaord/screens/shared/crop_varieties_screen.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/plant_type_selection_field.dart';
import 'record_water_stage_test.dart' show RecordAuth;

class CropLinkApi extends Fake implements SuperAdminApiService {
  Map<Symbol, dynamic>? saved;
  @override
  Future<List<Map<String, dynamic>>> getPlantTypes() async => [
        {r'$id': 'p', 'name': 'Lettuce', 'status': 'active'},
        {
          r'$id': 'cat',
          'name': 'Leafy crops',
          'is_category': true,
          'status': 'active'
        },
      ];
  @override
  Future<List<Map<String, dynamic>>> getCrops() async => [
        {
          r'$id': 'c',
          'crop_name': 'Lettuce',
          'variety_name': 'Batavia',
          'crop_image': 'crop.png',
          'plant_duration_value': 30,
          'plant_duration_unit': 'days',
          'company': 'Seed Co',
          'harvesting_weight': 1,
          'sprouting_ratio': 90,
          'ec_level_min': 1,
          'ec_level_max': 2,
          'ph_level_min': 5,
          'ph_level_max': 7,
          'temp_min': 18,
          'temp_max': 25,
          'humidity_min': 40,
          'humidity_max': 70
        }
      ];
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #updateCropVariety) {
      saved = invocation.namedArguments;
      return Future<Map<String, dynamic>>.value({});
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final width in [390.0, 1200.0]) {
    testWidgets('edit legacy variety links selected plant on width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = CropLinkApi();
      final container = ProviderContainer(
          overrides: [authServiceProvider.overrideWithValue(RecordAuth())]);
      addTearDown(container.dispose);
      container.read(authProvider);
      await tester.pump();
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
              theme: ThemeData(
                  platform: width > 600
                      ? TargetPlatform.windows
                      : TargetPlatform.android),
              home: CropVarietiesScreen(isSuperAdmin: true, api: api))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'Screen before opening the modal');
      final edit = width < 600
          ? find.text('Edit variety')
          : find.byTooltip('Edit crop variety');
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      final selector = find.descendant(
          of: find.byType(PlantTypeSelectionField),
          matching: find.byType(DropdownButtonFormField<String>));
      await tester.tap(selector);
      await tester.pumpAndSettle();
      expect(find.text('Leafy crops'), findsNothing);
      await tester.tap(find.text('Lettuce').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Update Variety'));
      await tester.tap(find.text('Update Variety'));
      await tester.pumpAndSettle();
      expect(api.saved?[#plantTypeId], 'p');
      expect(api.saved?[#cropName], 'Lettuce');
      expect(api.saved?[#varietyName], 'Batavia');
      expect(api.saved?[#imageBytes], isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
