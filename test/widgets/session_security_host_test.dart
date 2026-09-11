import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/session_security_host.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/message_notification_host.dart';
import 'package:farmestates_ai_dashbaord/providers/auth_provider.dart';
import 'package:farmestates_ai_dashbaord/services/auth_service.dart';
import 'package:farmestates_ai_dashbaord/models/user_model.dart';
import 'package:farmestates_ai_dashbaord/models/enums.dart';

class SessionFake extends Fake implements AuthService {
  @override
  String? get sessionId => 'test-session';
  @override
  DateTime? lastActivity = DateTime(2026, 9, 10);
  @override
  int sessionTimeoutMinutes = 5;
  @override
  int sessionWarningMinutes = 1;
  bool rejected = false;
  bool offline = false;
  @override
  UserModel? currentUser = UserModel(
      id: 'test',
      name: 'Test',
      email: 'test@example.com',
      role: UserRole.superAdmin,
      address: '',
      createdAt: DateTime(2026));
  @override
  bool get isLoggedIn => currentUser != null;
  @override
  Future<void> initialize() async {}
  @override
  Future<void> logout() async {
    currentUser = null;
  }

  @override
  Future<void> recordSessionActivity(DateTime time) async {
    lastActivity = time;
  }

  @override
  Future<void> refreshSession() async {
    if (rejected) throw const SessionExpiredException();
    if (offline) throw Exception('Offline');
  }
}

void main() {
  testWidgets('Expired saved session does not replace password recovery', (tester) async {
    final auth = SessionFake();
    final now = auth.lastActivity!.add(const Duration(minutes: 6));
    await tester.pumpWidget(ProviderScope(
      overrides: [authServiceProvider.overrideWithValue(auth)],
      child: MaterialApp(
        navigatorKey: messageNavigatorKey,
        builder: (_, child) => SessionSecurityHost(
          now: () => now, isPasswordRecovery: () => true, child: child!),
        home: const Scaffold(body: Text('Reset password')),
        routes: {'/login': (_) => const Scaffold(body: Text('Login screen'))},
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(auth.currentUser, isNull);
    expect(find.text('Reset password'), findsOneWidget);
    expect(find.text('Login screen'), findsNothing);
    expect(find.text('Are you still there?'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  for (final width in [320.0, 1200.0]) {
    testWidgets('Warning and verified continuation at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = SessionFake();
      var now = auth.lastActivity!.add(const Duration(minutes: 4));
      await tester.pumpWidget(ProviderScope(
          overrides: [authServiceProvider.overrideWithValue(auth)],
          child: MaterialApp(
            navigatorKey: messageNavigatorKey,
            builder: (_, child) =>
                SessionSecurityHost(now: () => now, child: child!),
            home: const Scaffold(body: Text('Protected')),
            routes: {
              '/login': (_) => const Scaffold(body: Text('Login screen'))
            },
          )));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('Are you still there?'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Continue session'));
      await tester.pump();
      expect(find.text('Are you still there?'), findsNothing);
      expect(auth.lastActivity, now);
      now = now.add(const Duration(minutes: 5));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Login screen'), findsOneWidget);
      expect(find.text('Protected'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('A failed verification cannot extend inactivity', (tester) async {
    final auth = SessionFake()..offline = true;
    final initial = auth.lastActivity;
    var now = initial!.add(const Duration(minutes: 4));
    await tester.pumpWidget(ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(auth)],
        child: MaterialApp(
          navigatorKey: messageNavigatorKey,
          builder: (_, child) =>
              SessionSecurityHost(now: () => now, child: child!),
          home: const Scaffold(body: Text('Protected')),
          routes: {'/login': (_) => const Scaffold(body: Text('Login screen'))},
        )));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.tap(find.text('Continue session'));
    await tester.pump();
    expect(find.textContaining('Unable to verify'), findsOneWidget);
    expect(auth.lastActivity, initial);
    now = now.add(const Duration(minutes: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Login screen'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
