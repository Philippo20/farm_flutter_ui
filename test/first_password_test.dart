import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/screens/auth/first_password_screen.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/create_user_modal.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final width in [390.0, 1280.0]) {
    testWidgets('First-password form validates without overflow at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(
          home: FirstPasswordScreen(
              token: 'challenge', temporaryPassword: 'Temp123!')));
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.first, 'Temp123!');
      await tester.enterText(fields.last, 'Different123!');
      await tester.tap(find.text('Update password'));
      await tester.pump();
      expect(find.text('Choose a different password'), findsOneWidget);
      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Create-user form explains email instead of password input at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => showCreateUserModal(context,
                          roles: const ['Caretaker'],
                          departments: const ['Field Work'],
                          onSubmit: (_) async {}),
                      child: const Text('Open'))))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.textContaining('8-character temporary password'),
          findsOneWidget);
      expect(find.text('Password'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
