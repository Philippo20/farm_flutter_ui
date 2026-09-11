import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/screens/auth/password_recovery_screen.dart';
import 'package:farmestates_ai_dashbaord/services/password_recovery_service.dart';

void main() {
  testWidgets('Successful reset offers app launch and falls back to web sign-in', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    var launches = 0;
    final service = PasswordRecoveryService(client: MockClient((_) async => http.Response('{}', 200)));
    addTearDown(service.close);
    await tester.pumpWidget(MaterialApp(
      home: PasswordRecoveryScreen(reset: true, userId: 'user', secret: 'token',
        service: service, appLauncher: () { launches++; throw StateError('No app'); }),
      routes: {'/login': (_) => const Scaffold(body: Text('Web sign-in'))},
    ));
    expect(find.text('Open Farm Estates app'), findsNothing);
    await tester.enterText(find.byType(TextFormField).first, 'new-password-123');
    await tester.enterText(find.byType(TextFormField).last, 'new-password-123');
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();
    expect(launches, 0);
    await tester.tap(find.text('Open Farm Estates app'));
    await tester.pump();
    expect(launches, 1);
    expect(find.text('Continue on web'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Web sign-in'), findsOneWidget);
  });
  for (final width in [320.0, 1440.0]) {
    for (final reset in [false, true]) {
      testWidgets('password recovery width=$width reset=$reset',
          (tester) async {
        GoogleFonts.config.allowRuntimeFetching = false;
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final requests = <http.Request>[];
        final service =
            PasswordRecoveryService(client: MockClient((request) async {
          requests.add(request);
          return http.Response('{}', 200);
        }));
        addTearDown(service.close);
        await tester.pumpWidget(MaterialApp(
            home: PasswordRecoveryScreen(
                reset: reset,
                userId: 'test-user',
                secret: 'test-token',
                service: service)));
        final fields = find.byType(TextFormField);
        await tester.enterText(
            fields.first, reset ? 'new-password-123' : 'person@example.com');
        if (reset) await tester.enterText(fields.last, 'new-password-123');
        await tester.ensureVisible(
            find.text(reset ? 'Update password' : 'Send reset link'));
        await tester
            .tap(find.text(reset ? 'Update password' : 'Send reset link'));
        await tester.pumpAndSettle();
        expect(requests.length, 1);
        expect(requests.single.url.query, isEmpty);
        expect(find.text(reset ? 'Password updated' : 'Check your email'),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('missing reset token cannot submit a new password',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.pumpWidget(
        const MaterialApp(home: PasswordRecoveryScreen(reset: true)));
    expect(find.text('Request new link'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });
  test('legacy backend errors are not shown as successful recovery', () async {
    final service = PasswordRecoveryService(
        client: MockClient(
            (_) async => http.Response('{"error":"mail failed"}', 200)));
    addTearDown(service.close);
    await expectLater(service.request('person@example.com'), throwsException);
  });
}
