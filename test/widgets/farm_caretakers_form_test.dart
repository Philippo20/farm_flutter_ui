import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/farm_form_modal.dart';
import 'package:farmestates_ai_dashbaord/core/utils/farm_team_assignment.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  test('Both caretakers match their farm, unrelated users do not', () {
    final farm = {
      'caretakerID': 'a',
      'caretaker_ids': ['a', 'b']
    };
    expect(isAssignedFarmCaretaker(farm, id: 'b', email: ''), isTrue);
    expect(isAssignedFarmCaretaker(farm, id: 'other', email: ''), isFalse);
    expect(isAssignedFarmCaretaker({'caretakerID': 'a'}, id: 'a', email: ''),
        isTrue);
    expect(
        isAssignedFarmCaretaker(
            {'caretakerID': 'Unassigned', 'caretaker_ids': []},
            id: 'a', email: ''),
        isFalse);
    expect(
        farmCaretakerIds({
          'caretakerID': 'a',
          'caretaker_ids': ['b']
        }),
        ['b']);
  });
  for (final width in [320.0, 1200.0]) {
    for (final dark in [false, true]) {
      testWidgets('Farm multi-select saves two caretakers at $width dark=$dark',
          (tester) async {
        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final submit = Completer<void>();
        Map<String, dynamic>? values;
        var count = 0;
        await tester.pumpWidget(MaterialApp(
            theme: dark ? ThemeData.dark() : ThemeData.light(),
            home: Scaffold(
                body: Builder(
                    builder: (context) => TextButton(
                        onPressed: () => showFarmFormModal(context,
                            farm: const {
                              'name': 'Farm 1',
                              'location': 'Accra',
                              'ownerID': 'o',
                              'farmManagerId': 'm',
                              'technicianId': 't',
                              'caretakerID': 'a',
                              'plantType': 'Lettuce',
                              'plantVariety': 'Green',
                              'tier': 'Basic',
                              'status': 'Active'
                            },
                            teamOptions: const {
                              'ownerID': [
                                {'id': 'o', 'name': 'Owner'}
                              ],
                              'farmManagerId': [
                                {'id': 'm', 'name': 'Manager'}
                              ],
                              'technicianId': [
                                {'id': 't', 'name': 'Technician'}
                              ],
                              'caretaker_ids': [
                                {'id': 'a', 'name': 'Caretaker A'},
                                {'id': 'b', 'name': 'Caretaker B'}
                              ]
                            },
                            plantTypes: const ['Lettuce'],
                            varietiesForPlant: (_) => ['Green'],
                            onSubmit: (data) async {
                              count++;
                              values = data;
                              await submit.future;
                            }),
                        child: const Text('Edit'))))));
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();
        final second = find.widgetWithText(CheckboxListTile, 'Caretaker B');
        await tester.ensureVisible(second);
        await tester.tap(second);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Save changes'));
        await tester.pump();
        expect(find.text('Saving...'), findsOneWidget);
        expect(values?['caretaker_ids'], ['a', 'b']);
        expect(count, 1);
        submit.completeError(Exception('Unable to save assignment'));
        await tester.pumpAndSettle();
        expect(find.text('Unable to save assignment'), findsOneWidget);
        expect(
            tester
                .widget<CheckboxListTile>(
                    find.widgetWithText(CheckboxListTile, 'Caretaker B'))
                .value,
            isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
