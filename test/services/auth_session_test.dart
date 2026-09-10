import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmestates_ai_dashbaord/services/auth_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
      'Fresh login is verified by the server, not rejected by local token decoding',
      () async {
    var verified = false;
    final auth = AuthService.forTesting(MockClient((request) async {
      if (request.url.path == '/account/login') {
        return http.Response(
            jsonEncode({
              'jwt': 'server-issued-token',
              'session_id': 'fresh',
              'user': {
                'id': 'user',
                'name': 'Test',
                'email': 'test@example.com',
                'role': 'Super Admin'
              }
            }),
            200);
      }
      expect(request.headers['Authorization'], 'Bearer server-issued-token');
      verified = true;
      return http.Response(
          jsonEncode({
            'jwt': 'renewed',
            'session_timeout': 30,
            'session_idle_warning_minutes': 5
          }),
          200);
    }));
    expect((await auth.login('test@example.com', 'password')).success, isTrue);
    await auth.refreshSession();
    expect(verified, isTrue);
    expect(auth.isLoggedIn, isTrue);
    expect(auth.jwt, 'renewed');
    expect(
        DateTime.now().difference(auth.lastActivity!).inSeconds, lessThan(5));
  });

  test(
      'Server rejection still expires a session; infrastructure failures do not',
      () async {
    SharedPreferences.setMockInitialValues({
      'is_logged_in': true,
      'user_id': 'user',
      'user_name': 'Test',
      'user_email': 'test@example.com',
      'user_role': 'superAdmin',
      'auth_jwt': 'token',
      'auth_session_id': 'session',
      'session_last_activity': DateTime.now().toIso8601String()
    });
    var status = 503;
    final auth = AuthService.forTesting(
        MockClient((_) async => http.Response('{}', status)));
    await auth.initialize();
    await expectLater(
        auth.refreshSession(), throwsA(isNot(isA<SessionExpiredException>())));
    status = 401;
    await expectLater(
        auth.refreshSession(), throwsA(isA<SessionExpiredException>()));
  });

  test('A rejected sign-in never creates a tokenless local session', () async {
    final auth = AuthService.forTesting(MockClient(
        (_) async => http.Response('{"detail":"Invalid credentials"}', 401)));
    expect((await auth.login('superadmin@farmestates.com', 'password')).success,
        isFalse);
    expect(auth.isLoggedIn, isFalse);
  });
}
