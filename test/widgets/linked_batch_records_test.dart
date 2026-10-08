import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/providers/auth_provider.dart';
import 'package:farmestates_ai_dashbaord/screens/caretaker/record_entry_screen.dart';
import 'record_water_stage_test.dart' show RecordApi, RecordAuth;

class LinkedApi extends RecordApi {
  @override
  Future<List<Map<String, dynamic>>> getBatches() async {
    final first = (await super.getBatches()).first;
    return [
      {
        ...first,
        'growing_group_id': 'g',
        'growing_group_name': 'Room A',
        'plant_variety': 'Batavia'
      },
      {
        ...first,
        r'$id': 'b2',
        'batch_no': 'B-2',
        'growing_group_id': 'g',
        'growing_group_name': 'Room A',
        'plant_variety': 'Lollo Rosso'
      }
    ];
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final width in [390.0, 1200.0]) {
    testWidgets('shared readings preserve batch-specific issues at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = LinkedApi();
      final container = ProviderContainer(
          overrides: [authServiceProvider.overrideWithValue(RecordAuth())]);
      addTearDown(container.dispose);
      container.read(authProvider);
      await tester.pump();
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: RecordEntryScreen(api: api), routes: {
            '/caretaker_dashboard': (_) => const Scaffold(body: Text('Saved'))
          })));
      await tester.pumpAndSettle();
      final toggle = find.text('Record linked batches together');
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      Finder field(String label) => find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label);
      await tester.ensureVisible(field('pH (0–14)'));
      await tester.enterText(field('pH (0–14)'), '6.2');
      await tester.ensureVisible(field('EC (mS/cm)'));
      await tester.enterText(field('EC (mS/cm)'), '1.5');
      await tester.ensureVisible(field('Observations for this batch').first);
      await tester.enterText(
          field('Observations for this batch').first, 'Yellowing in Batavia');
      final issue = find.text('Issue affects this batch').first;
      await tester.ensureVisible(issue);
      await tester.tap(issue);
      await tester.pumpAndSettle();
      await tester.ensureVisible(field('Describe the issue for this batch'));
      await tester.enterText(
          field('Describe the issue for this batch'), 'Yellow leaves');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Yellow leaves'), findsOneWidget);
      await tester.ensureVisible(find.text('Submit Record'));
      await tester.tap(find.text('Submit Record'));
      await tester.pumpAndSettle();
      expect(api.saved, isNotNull);
      final entries = jsonDecode(api.saved!['batch_entries'] as String) as List;
      expect(entries.length, 2);
      expect(entries[0]['has_issues'], true);
      expect(entries[1]['has_issues'], false);
      expect(entries[0]['observations'], 'Yellowing in Batavia');
      expect(api.saved!['ph'], '6.2');
      expect(api.saved!['ec'], '1.5');
      expect(tester.takeException(), isNull);
    });
  }
}
