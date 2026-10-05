import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/modern_admin_sidebar.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/role_mobile_navigation.dart';
import 'package:farmestates_ai_dashbaord/providers/auth_provider.dart';
import 'package:farmestates_ai_dashbaord/services/auth_service.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final mobile in [true, false]) {
    for (final cancel in [true, false]) {
      testWidgets(
          '${mobile ? 'Mobile drawer' : 'Desktop sidebar'} logout ${cancel ? 'cancel' : 'confirm offline'}',
          (tester) async {
        await http.runWithClient(() async {
          SharedPreferences.setMockInitialValues({
            'is_logged_in': true,
            'user_id': 'u',
            'user_name': 'Test Admin',
            'user_email': 'user@example.com',
            'user_role': 'admin',
            'auth_jwt': 'token',
            'auth_session_id': 'session',
            'session_last_activity': DateTime.now().toIso8601String(),
          });
          final service = AuthService.forTesting(
              MockClient((_) async => http.Response('{}', 200)));
          final container = ProviderContainer(
              overrides: [authServiceProvider.overrideWithValue(service)]);
          addTearDown(container.dispose);
          container.read(authProvider);
          await tester.pump();
          tester.view.physicalSize = Size(mobile ? 390 : 1280, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final navigator = GlobalKey<NavigatorState>();
          await tester.pumpWidget(UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                navigatorKey: navigator,
                theme: ThemeData(
                    platform: mobile
                        ? TargetPlatform.android
                        : TargetPlatform.windows),
                routes: {
                  '/login': (_) => const Scaffold(body: Text('Login screen'))
                },
                home: Scaffold(
                    body: mobile
                        ? RoleMobileDrawer(
                            userName: 'Test Admin',
                            userEmail: 'user@example.com',
                            userRole: 'Admin',
                            selectedIndex: 0,
                            onItemSelected: (_) {},
                            items: const [])
                        : ModernAdminSidebar(
                            selectedIndex: 0, onItemSelected: (_) {})),
              )));
          await tester.pumpAndSettle();
          expect(container.read(authProvider).isAuthenticated, isTrue);
          await tester.tap(find.text('Logout').last);
          await tester.pumpAndSettle();
          await tester.tap(find
              .text(cancel
                  ? 'Cancel'
                  : mobile
                      ? 'Logout'
                      : 'Log out')
              .last);
          await tester.pumpAndSettle();
          final prefs = await SharedPreferences.getInstance();
          if (cancel) {
            expect(service.isLoggedIn, isTrue);
            expect(prefs.getString('auth_jwt'), 'token');
            expect(find.text('Login screen'), findsNothing);
          } else {
            expect(container.read(authProvider).isAuthenticated, isFalse);
            expect(service.currentUser, isNull);
            expect(service.jwt, isNull);
            expect(service.sessionId, isNull);
            expect(service.lastActivity, isNull);
            for (final key in [
              'is_logged_in',
              'user_id',
              'auth_jwt',
              'auth_session_id',
              'session_last_activity'
            ]) {
              expect(prefs.containsKey(key), isFalse, reason: key);
            }
            expect(find.text('Login screen'), findsOneWidget);
            expect(navigator.currentState!.canPop(), isFalse);
          }
          expect(tester.takeException(), isNull);
        },
            () =>
                MockClient((_) async => throw http.ClientException('offline')));
      });
    }
  }
}
