import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/growing_group_field.dart';
import 'package:farmestates_ai_dashbaord/services/superadmin_api_service.dart';

class GroupApi extends Fake implements SuperAdminApiService {
  @override
  Future<List<Map<String, dynamic>>> getBatches() async => [
        {
          'farmID': 'f',
          'growing_group_id': 'g',
          'growing_group_name': 'Room A'
        },
        {
          'farmID': 'other',
          'growing_group_id': 'other',
          'growing_group_name': 'Other farm room'
        },
      ];
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final width in [320.0, 500.0]) {
    testWidgets('choose existing or new farm group at $width', (tester) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey<FormState>();
      String id = '', name = '';
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Form(
                  key: key,
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: GrowingGroupField(
                          api: GroupApi(),
                          farmId: 'f',
                          onChanged: (i, n) {
                            id = i;
                            name = n;
                          }))))));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expect(find.text('Other farm room'), findsNothing);
      await tester.tap(find.text('Room A').last);
      await tester.pumpAndSettle();
      expect(id, 'g');
      expect(name, 'Room A');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create growing group').last);
      await tester.pumpAndSettle();
      expect(key.currentState!.validate(), false);
      await tester.enterText(find.byType(TextFormField), 'Room B — System 2');
      expect(key.currentState!.validate(), true);
      expect(id, 'new');
      expect(name, 'Room B — System 2');
      expect(tester.takeException(), isNull);
    });
  }
}
