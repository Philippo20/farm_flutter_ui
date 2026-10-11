import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmestates_ai_dashbaord/providers/auth_provider.dart';
import 'package:farmestates_ai_dashbaord/screens/auth/modern_login_screen.dart';
import 'package:farmestates_ai_dashbaord/services/auth_service.dart';
import 'package:farmestates_ai_dashbaord/services/biometric_sign_in_service.dart';
import 'package:farmestates_ai_dashbaord/services/android_app_updates.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/android_update_host.dart';

class _Updates extends AndroidAppUpdates {
  final result = Completer<bool>();

  void available() {
    release = AndroidRelease(
        build: 99,
        version: '1.0.0',
        packageName: 'farm.test',
        url: Uri.parse(
            'https://apps.farmestates.farm/downloads/farm-estates.apk'),
        sha256: List.filled(64, 'a').join(),
        bytes: 80000000,
        notes: 'App improvements.');
    result.complete(true);
  }

  @override
  Future<bool> check() => result.future;
  @override
  Future<void> resumed() async {}
}

class _Biometrics extends BiometricSignInService {
  _Biometrics({this.available = true, this.enabled = true});
  bool available, enabled;
  int enables = 0, disables = 0, unlocks = 0;
  Future<BiometricCredentials?> Function()? onUnlock;
  Future<bool> Function()? onEnable;
  Future<BiometricSignInStatus> Function()? onStatus;
  @override
  Future<BiometricSignInStatus> status() async => onStatus != null
      ? await onStatus!()
      : BiometricSignInStatus(
          available: available,
          enabled: enabled,
          email: enabled ? 'test@example.com' : null);
  @override
  Future<BiometricCredentials?> unlock() {
    unlocks++;
    return onUnlock?.call() ??
        Future.value(
            const BiometricCredentials('test@example.com', 'real-password'));
  }

  @override
  Future<bool> enable(String email, String password) async {
    enables++;
    expect(email, 'test@example.com');
    expect(password, 'real-password');
    return onEnable?.call() ?? true;
  }

  @override
  Future<void> disable() async {
    disables++;
    enabled = false;
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> mount(WidgetTester tester, _Biometrics biometric,
      Future<http.Response> Function(http.Request) backend,
      {bool dark = false, bool settle = true, _Updates? updates}) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          biometricSignInProvider.overrideWithValue(biometric),
          authServiceProvider
              .overrideWithValue(AuthService.forTesting(MockClient(backend))),
        ],
        child: MaterialApp(
          navigatorKey: navigator,
          builder: updates == null
              ? null
              : (_, child) => AndroidUpdateHost(
                  navigatorKey: navigator, service: updates, child: child!),
          theme:
              ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
          home: const ModernLoginScreen(),
          routes: {
            '/dashboard': (_) => const Scaffold(body: Text('Dashboard')),
            '/select-role': (_) =>
                const Scaffold(body: Text('Choose your role')),
          },
        )));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump();
    }
  }

  http.Response success({bool multiple = false}) => http.Response(
      jsonEncode({
        'jwt': 'server-token',
        'session_id': 'new-server-session',
        'user': {
          'id': 'user-1',
          'name': 'Test',
          'email': 'test@example.com',
          'role': 'Admin',
          'roles': multiple ? ['Admin', 'Caretaker'] : ['Admin']
        },
      }),
      200);

  testWidgets('startup update check waits before automatic fingerprint',
      (tester) async {
    final updates = _Updates();
    final biometric = _Biometrics();
    await mount(tester, biometric, (_) async => success(), updates: updates);
    await tester.pump(const Duration(seconds: 2));
    expect(biometric.unlocks, 0);
    expect(find.text('Dashboard'), findsNothing);
    updates.result.complete(false);
    await tester.pumpAndSettle();
    expect(biometric.unlocks, 1);
    expect(find.text('Dashboard'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    updates.dispose();
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
      'update offer and closing animation take priority over fingerprint',
      (tester) async {
    final updates = _Updates();
    final biometric = _Biometrics();
    await mount(tester, biometric, (_) async => success(), updates: updates);
    updates.available();
    await tester.pumpAndSettle();
    expect(find.text('App update available'), findsOneWidget);
    expect(biometric.unlocks, 0);
    // Even a deliberate native prompt cannot jump ahead of the update offer.
    final login = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('biometric-sign-in'), skipOffstage: false));
    expect(login.onPressed, isNull);
    await tester.pump();
    expect(biometric.unlocks, 0);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(biometric.unlocks, 0);
    await tester.pumpAndSettle();
    expect(biometric.unlocks, 1);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    updates.dispose();
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets(
      'background update result is offered before fingerprint on resume',
      (tester) async {
    final updates = _Updates();
    final biometric = _Biometrics();
    await mount(tester, biometric, (_) async => success(), updates: updates);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    updates.available();
    await tester.pumpAndSettle();
    expect(biometric.unlocks, 0);
    expect(find.text('App update available'), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('App update available'), findsOneWidget);
    expect(biometric.unlocks, 0);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(biometric.unlocks, 1);
    await tester.pumpWidget(const SizedBox());
    updates.dispose();
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('navigation interruption preserves update priority on new login',
      (tester) async {
    final updates = _Updates()..available();
    final biometric = _Biometrics();
    await mount(tester, biometric, (_) async => success(), updates: updates);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const ModernLoginScreen()),
        (_) => false);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.text('App update available'), findsOneWidget);
    expect(biometric.unlocks, 0);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(biometric.unlocks, 1);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    updates.dispose();
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  for (final timeout in [false, true]) {
    testWidgets('failed update check releases fingerprint timeout=$timeout',
        (tester) async {
      final updates = _Updates();
      final biometric = _Biometrics();
      await mount(tester, biometric, (_) async => success(), updates: updates);
      expect(biometric.unlocks, 0);
      if (timeout) {
        await tester.pump(const Duration(seconds: 16));
      } else {
        updates.result.completeError(StateError('Release website offline'));
      }
      await tester.pumpAndSettle();
      expect(biometric.unlocks, 1);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      updates.dispose();
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  }

  testWidgets('explicitly snoozed update allows automatic fingerprint',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'app_update_snooze_explicit': true,
      'app_update_snooze_build': 99,
      'app_update_snooze_until':
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
    });
    final updates = _Updates()..available();
    final biometric = _Biometrics();
    await mount(tester, biometric, (_) async => success(), updates: updates);
    expect(biometric.unlocks, 1);
    expect(find.text('App update available'), findsNothing);
    expect(find.text('Dashboard'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    updates.dispose();
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  Future<void> tapFingerprint(WidgetTester tester) async {
    final button = find.byKey(const ValueKey('biometric-sign-in'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Future<void> password(WidgetTester tester, {bool optIn = false}) async {
    await tester.enterText(
        find.byKey(const ValueKey('login-email')), 'test@example.com');
    await tester.enterText(
        find.byKey(const ValueKey('login-password')), 'real-password');
    if (optIn) {
      final checkbox = find.byKey(const ValueKey('enable-biometric-sign-in'));
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pump();
    }
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
  }

  testWidgets('unsupported phones show only password sign-in', (tester) async {
    await mount(tester, _Biometrics(available: false, enabled: false),
        (_) async => success());
    expect(
        find.byKey(const ValueKey('enable-biometric-sign-in')), findsNothing);
    expect(find.byKey(const ValueKey('biometric-sign-in')), findsNothing);
    await password(tester);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  for (final dark in [false, true]) {
    testWidgets(
        'biometric unlock uses a fresh server login and role selection dark=$dark',
        (tester) async {
      var requests = 0;
      final biometrics = _Biometrics();
      await mount(tester, biometrics, (request) async {
        requests++;
        expect(request.url.path, '/account/login');
        expect(request.bodyFields,
            {'email': 'test@example.com', 'password': 'real-password'});
        return success(multiple: true);
      }, dark: dark);
      expect(biometrics.unlocks, 1);
      expect(requests, 1);
      expect(find.text('Choose your role'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_jwt'), 'server-token');
      expect(prefs.getKeys().any((key) => key.contains('password')), isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'cancelled prompt makes no API request and permits password fallback',
      (tester) async {
    final biometrics = _Biometrics()..onUnlock = () async => null;
    var requests = 0;
    await mount(tester, biometrics, (_) async {
      requests++;
      return success();
    });
    expect(biometrics.unlocks, 1);
    expect(
        find.byKey(const ValueKey('enable-biometric-sign-in')), findsNothing);
    expect(find.text('test@example.com'), findsNothing);
    expect(find.text('Remove saved fingerprint sign-in'), findsNothing);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(biometrics.unlocks, 1);
    expect(requests, 0);
    expect(find.text('Welcome back'), findsOneWidget);
    await password(tester);
    expect(requests, 1);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets(
      'rejected saved password removes enrollment and preserves backend error',
      (tester) async {
    final biometrics = _Biometrics();
    await mount(
        tester,
        biometrics,
        (_) async =>
            http.Response('{"detail":"Invalid email or password"}', 401));
    expect(biometrics.disables, 1);
    expect(find.byKey(const ValueKey('biometric-sign-in')), findsNothing);
    expect(find.text('Invalid email or password'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getBool('is_logged_in'),
        isNot(true));
  });

  testWidgets('API outages retain enrollment without creating a local session',
      (tester) async {
    final biometrics = _Biometrics();
    await mount(tester, biometrics, (_) async => http.Response('{}', 503));
    expect(biometrics.disables, 0);
    expect(find.byKey(const ValueKey('biometric-sign-in')), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);
    expect((await SharedPreferences.getInstance()).getBool('is_logged_in'),
        isNot(true));
  });

  testWidgets('required password changes still run after a biometric unlock',
      (tester) async {
    final biometrics = _Biometrics();
    await mount(
        tester,
        biometrics,
        (_) async => http.Response(
            '{"must_change_password":true,"password_change_token":"change-me"}',
            200));
    expect(biometrics.disables, 1);
    expect(biometrics.enables, 0);
    expect(find.text('Secure your account'), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);
  });

  testWidgets('setup requires opt-in and successful backend login',
      (tester) async {
    final biometrics = _Biometrics(enabled: false);
    var accepted = false;
    await mount(
        tester,
        biometrics,
        (_) async => accepted
            ? success()
            : http.Response('{"detail":"Not approved"}', 403));
    await password(tester, optIn: true);
    expect(biometrics.enables, 0);
    accepted = true;
    await password(tester);
    expect(biometrics.enables, 1);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('declining setup does not prevent a successful password login',
      (tester) async {
    final biometrics = _Biometrics(enabled: false)
      ..onEnable = () async => false;
    await mount(tester, biometrics, (_) async => success());
    await password(tester, optIn: true);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('pending biometric prompts disable duplicate sign-in',
      (tester) async {
    final pending = Completer<BiometricCredentials?>();
    final biometrics = _Biometrics()..onUnlock = () => pending.future;
    await mount(tester, biometrics, (_) async => success(), settle: false);
    final button = find.byKey(const ValueKey('biometric-sign-in'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    expect(biometrics.unlocks, 1);
    pending.complete(null);
    await tester.pumpAndSettle();
    expect(tester.widget<OutlinedButton>(button).onPressed, isNotNull);
  });

  testWidgets(
      'invalidated keys return to password sign-in and permit new setup',
      (tester) async {
    final biometrics = _Biometrics();
    biometrics.onUnlock = () async {
      biometrics.enabled = false;
      throw PlatformException(
          code: 'invalidated',
          message: 'Sign in with your password to set up fingerprint again.');
    };
    await mount(tester, biometrics, (_) async => success());
    expect(find.text('Sign in with your password to set up fingerprint again.'),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('enable-biometric-sign-in')), findsOneWidget);
    expect(find.byKey(const ValueKey('biometric-sign-in')), findsNothing);
  });

  testWidgets(
      'enrolled users can retry manually after cancelling automatic prompt',
      (tester) async {
    final biometrics = _Biometrics()..onUnlock = () async => null;
    var requests = 0;
    await mount(tester, biometrics, (_) async {
      requests++;
      return success();
    });
    expect(biometrics.unlocks, 1);
    biometrics.onUnlock = null;
    await tapFingerprint(tester);
    expect(biometrics.unlocks, 2);
    expect(requests, 1);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('enrolled but unavailable biometrics leave password login ready',
      (tester) async {
    final biometrics = _Biometrics(available: false);
    await mount(tester, biometrics, (_) async => success());
    expect(biometrics.unlocks, 0);
    expect(
        find.byKey(const ValueKey('enable-biometric-sign-in')), findsNothing);
    expect(find.byKey(const ValueKey('biometric-sign-in')), findsNothing);
    expect(find.text('test@example.com'), findsNothing);
    await password(tester);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets(
      'leaving login before biometric status returns never opens a prompt',
      (tester) async {
    final pending = Completer<BiometricSignInStatus>();
    final biometrics = _Biometrics()..onStatus = () => pending.future;
    await mount(tester, biometrics, (_) async => success());
    await tester.pumpWidget(const SizedBox.shrink());
    pending
        .complete(const BiometricSignInStatus(available: true, enabled: true));
    await tester.pumpAndSettle();
    expect(biometrics.unlocks, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('automatic prompt waits until the app is in the foreground',
      (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final biometrics = _Biometrics()..onUnlock = () async => null;
    await mount(tester, biometrics, (_) async => success());
    expect(biometrics.unlocks, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(biometrics.unlocks, 1);
  });

  testWidgets('automatic prompt waits for a covering route to close',
      (tester) async {
    final pending = Completer<BiometricSignInStatus>();
    final biometrics = _Biometrics();
    biometrics.onStatus = () => pending.future;
    biometrics.onUnlock = () async => null;
    await mount(tester, biometrics, (_) async => success());
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('App update'))));
    await tester.pumpAndSettle();
    pending
        .complete(const BiometricSignInStatus(available: true, enabled: true));
    await tester.pumpAndSettle();
    expect(biometrics.unlocks, 0);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(biometrics.unlocks, 1);
  });
}
