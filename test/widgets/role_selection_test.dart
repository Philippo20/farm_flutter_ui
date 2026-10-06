import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/models/enums.dart';
import 'package:farmestates_ai_dashbaord/models/user_model.dart';
import 'package:farmestates_ai_dashbaord/providers/auth_provider.dart';
import 'package:farmestates_ai_dashbaord/services/auth_service.dart';
import 'package:farmestates_ai_dashbaord/screens/auth/role_selection_screen.dart';

class FakeAuth extends Fake implements AuthService {
  @override
  final currentUser = UserModel(
      id: 'u',
      name: 'Team Member',
      email: 'test@example.com',
      role: UserRole.caretaker,
      roles: UserRole.values,
      address: '',
      createdAt: DateTime(2026));
  @override
  bool get isLoggedIn => true;
  @override
  Future<void> initialize() async {}
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  for (final width in [320.0, 768.0, 1366.0]) {
    for (final dark in [false, true]) {
      testWidgets('Role cards fit $width, dark=$dark', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(FakeAuth())],
            child: MaterialApp(
                theme: dark ? ThemeData.dark() : ThemeData.light(),
                home: const RoleSelectionScreen())));
        await tester.pumpAndSettle();
        expect(find.text('Super Admin'), findsOneWidget);
        expect(find.text('Caretaker'), findsOneWidget);
        expect(find.text('Choose your workspace'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.drag(
            find.byType(SingleChildScrollView), const Offset(0, -2000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
