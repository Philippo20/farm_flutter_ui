import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/android_update_host.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/message_notification_host.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/session_security_host.dart';
import 'package:farmestates_ai_dashbaord/models/enums.dart';
import 'package:farmestates_ai_dashbaord/models/user_model.dart';
import 'package:farmestates_ai_dashbaord/providers/auth_provider.dart';
import 'package:farmestates_ai_dashbaord/services/android_app_updates.dart';
import 'package:farmestates_ai_dashbaord/services/auth_service.dart';

class _Updates extends AndroidAppUpdates {
  _Updates([AppUpdatePhase initial = AppUpdatePhase.available]) {
    release = AndroidRelease(
        build: 18,
        version: '1.0.0',
        packageName: 'farm.test',
        url: Uri.parse(
            'https://apps.farmestates.farm/downloads/farm-estates.apk'),
        sha256: List.filled(64, 'a').join(),
        bytes: 80000000,
        notes: 'App improvements.');
    phase = initial;
    progress = initial == AppUpdatePhase.downloading ? .4 : null;
    currentVersion = '1.0.0 (17)';
  }
  int checks = 0, downloads = 0;
  @override
  Future<bool> check() async {
    checks++;
    return true;
  }

  @override
  Future<void> resumed() async {}
  @override
  Future<void> download() async {
    downloads++;
    phase = AppUpdatePhase.downloading;
    progress = .4;
    notifyListeners();
  }
}

class _ExpiredSession extends Fake implements AuthService {
  @override
  DateTime? lastActivity = DateTime(2026, 10, 11);
  @override
  int sessionTimeoutMinutes = 5;
  @override
  int sessionWarningMinutes = 1;
  @override
  String? get sessionId => 'expired-session';
  @override
  UserModel? currentUser = UserModel(
      id: 'user',
      name: 'Test',
      email: 'test@example.com',
      role: UserRole.admin,
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
}

void main() {
  void androidTest(String description, WidgetTesterCallback callback) {
    testWidgets(description, callback,
        variant: TargetPlatformVariant.only(TargetPlatform.android));
  }

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> mount(WidgetTester tester, _Updates updates,
      {bool expired = false, GlobalKey<NavigatorState>? navigator}) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(updates.dispose);
    final key = navigator ?? messageNavigatorKey;
    await tester.pumpWidget(ProviderScope(
      overrides: [authServiceProvider.overrideWithValue(_ExpiredSession())],
      child: MaterialApp(
        navigatorKey: key,
        theme: ThemeData(platform: TargetPlatform.android),
        home: const Scaffold(body: Text('Dashboard')),
        routes: {'/login': (_) => const Scaffold(body: Text('Login screen'))},
        builder: (_, child) => AndroidUpdateHost(
            navigatorKey: key,
            service: updates,
            child: expired
                ? SessionSecurityHost(
                    now: () => DateTime(2026, 10, 11, 0, 6), child: child!)
                : child!),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
  }

  Future<void> settleInterruption(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(); // Route replacement and its removal animation.
    await tester
        .pump(const Duration(milliseconds: 350)); // Re-present pending offer.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
  }

  for (final phase in [
    AppUpdatePhase.available,
    AppUpdatePhase.downloading,
    AppUpdatePhase.ready
  ]) {
    androidTest('session expiry restores the update sheet in phase $phase',
        (tester) async {
      final updates = _Updates(phase);
      await mount(tester, updates, expired: true);
      expect(find.text('App update available'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await settleInterruption(tester);
      expect(find.text('Login screen'), findsOneWidget);
      expect(find.text('App update available'), findsOneWidget);
      expect(updates.phase, phase);
      expect(updates.checks, phase == AppUpdatePhase.available ? 1 : 0);
      expect(updates.downloads, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('app_update_snooze_build'), isNull);
      expect(prefs.getBool('app_update_snooze_explicit'), isNot(true));
      if (phase == AppUpdatePhase.downloading) {
        expect(find.text('Downloading 40%'), findsOneWidget);
      }
      if (phase == AppUpdatePhase.ready) {
        expect(find.text('Install update'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final action in ['Cancel', 'Close', 'Back']) {
    androidTest('only explicit $action snoozes the update', (tester) async {
      final updates = _Updates();
      await mount(tester, updates);
      if (action == 'Back') {
        await tester.binding.handlePopRoute();
      } else if (action == 'Close') {
        await tester.tap(find.byTooltip('Close'));
      } else {
        await tester.tap(find.text('Cancel'));
      }
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('App update available'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('app_update_snooze_build'), 18);
      expect(prefs.getBool('app_update_snooze_explicit'), isTrue);
      expect(prefs.getInt('app_update_snooze_until'),
          greaterThan(DateTime.now().millisecondsSinceEpoch));
      await tester.pumpWidget(const SizedBox());
    });
  }

  androidTest('legacy automatic snooze does not hide an available update',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'app_update_snooze_build': 18,
      'app_update_snooze_until':
          DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch,
    });
    await mount(tester, _Updates());
    expect(find.text('App update available'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  androidTest('a genuine explicit snooze is still respected', (tester) async {
    SharedPreferences.setMockInitialValues({
      'app_update_snooze_build': 18,
      'app_update_snooze_until':
          DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch,
      'app_update_snooze_explicit': true,
    });
    await mount(tester, _Updates());
    expect(find.text('App update available'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  androidTest('closing a running download keeps it available on resume',
      (tester) async {
    final updates = _Updates(AppUpdatePhase.downloading);
    await mount(tester, updates);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('App update available'), findsNothing);
    expect(
        (await SharedPreferences.getInstance())
            .getBool('app_update_snooze_explicit'),
        isNot(true));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('Downloading 40%'), findsOneWidget);
    expect(updates.downloads, 0);
    await tester.pumpWidget(const SizedBox());
  });

  androidTest(
      'an interrupted background download reopens on resume without restarting it',
      (tester) async {
    final key = GlobalKey<NavigatorState>();
    final updates = _Updates();
    await mount(tester, updates, navigator: key);
    await tester.tap(find.text('Download update'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(updates.downloads, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    key.currentState!.pushNamedAndRemoveUntil('/login', (_) => false);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settleInterruption(tester);
    expect(find.text('App update available'), findsOneWidget);
    expect(find.text('Downloading 40%'), findsOneWidget);
    expect(updates.downloads, 1);
    expect(updates.checks, 1);
    expect(
        (await SharedPreferences.getInstance())
            .getBool('app_update_snooze_explicit'),
        isNot(true));
    await tester.pumpWidget(const SizedBox());
  });
}
