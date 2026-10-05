import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmestates_ai_dashbaord/screens/auth/modern_login_screen.dart';
import 'package:farmestates_ai_dashbaord/providers/auth_provider.dart';
import 'package:farmestates_ai_dashbaord/services/auth_service.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  Future<void> mount(WidgetTester tester,
      {double width = 390,
      bool dark = false,
      double keyboard = 0,
      http.Client? client}) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = Size(width, 850);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(AuthService.forTesting(
              client ?? MockClient((_) async => http.Response('{}', 401)))),
        ],
        child: MaterialApp(
          theme:
              ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
          home: const ModernLoginScreen(),
          routes: {
            '/forgot-password': (_) =>
                const Scaffold(body: Text('Recovery page'))
          },
        )));
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 768.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('Responsive login at $width dark=$dark', (tester) async {
        await mount(tester,
            width: width, dark: dark, keyboard: width == 320 ? 300 : 0);
        await tester.ensureVisible(find.text('Sign in'));
        await tester.tap(find.text('Sign in'));
        await tester.pumpAndSettle();
        expect(find.text('Enter your email address'), findsOneWidget);
        expect(find.text('Enter your password'), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('Forgot password?'));
        await tester.tap(find.text('Forgot password?'));
        await tester.pumpAndSettle();
        expect(find.text('Recovery page'), findsOneWidget);
      });
    }
  }
  testWidgets('Password toggle, loading guard and inline server error',
      (tester) async {
    final response = Completer<http.Response>();
    var requests = 0;
    await mount(tester, client: MockClient((_) {
      requests++;
      return response.future;
    }));
    await tester.enterText(
        find.byKey(const ValueKey('login-email')), 'user@example.com');
    await tester.enterText(
        find.byKey(const ValueKey('login-password')), 'Password123!');
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('login-password')))
            .controller!
            .text,
        'Password123!');
    expect(find.byTooltip('Hide password'), findsOneWidget);
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Signing in...'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    response
        .complete(http.Response('{"detail":"Account pending approval"}', 403));
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(find.text('Account pending approval'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
  });
  testWidgets('Temporary credentials open required password setup',
      (tester) async {
    await mount(tester,
        client: MockClient((_) async => http.Response(
            '{"must_change_password":true,"password_change_token":"challenge"}',
            200)));
    await tester.enterText(
        find.byKey(const ValueKey('login-email')), 'user@example.com');
    await tester.enterText(
        find.byKey(const ValueKey('login-password')), 'Temp123!');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Secure your account'), findsOneWidget);
    await tester.tap(find.text('Back to sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(
        find.text('Change your temporary password to continue.'), findsNothing);
  });
}
