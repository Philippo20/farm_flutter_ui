import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/create_user_modal.dart';

void main() {
  setUpAll(() { GoogleFonts.config.allowRuntimeFetching = false; });
  for (final width in [360.0, 1200.0]) {
    testWidgets('Editing assigned roles submits the selected list at $width', (tester) async {
      tester.view.physicalSize = Size(width, 900); tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      Map<String, dynamic>? saved;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (context) => TextButton(
        onPressed: () => showCreateUserModal(context,
          roles: const ['Caretaker', 'Technician', 'Farm Manager'], departments: const ['Field Work'],
          initialValues: const {'name': 'Test User', 'email': 'test@example.com',
            'role': 'Caretaker', 'roles': ['Caretaker', 'Technician'], 'department': 'Field Work', 'status': 'Active'},
          onSubmit: (values) async { saved = values; }), child: const Text('Edit'))))));
      await tester.tap(find.text('Edit')); await tester.pumpAndSettle();
      final technician = find.widgetWithText(FilterChip, 'Technician');
      expect(tester.widget<FilterChip>(technician).selected, isTrue);
      await tester.ensureVisible(technician); await tester.tap(technician); await tester.pump();
      final manager = find.widgetWithText(FilterChip, 'Farm Manager');
      await tester.ensureVisible(manager); await tester.tap(manager); await tester.pump();
      await tester.tap(find.text('Save changes')); await tester.pumpAndSettle();
      expect(saved?['roles'], ['Caretaker', 'Farm Manager']);
      expect(saved?['role'], 'Caretaker');
      expect(tester.takeException(), isNull);
    });
  }
}
