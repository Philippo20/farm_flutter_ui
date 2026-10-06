import 'package:farmestates_ai_dashbaord/services/api_connection.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmestates_ai_dashbaord/models/enums.dart';
import 'package:farmestates_ai_dashbaord/services/auth_service.dart';
import 'package:farmestates_ai_dashbaord/services/api_session_context.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiSessionContext.jwt = null;
    ApiSessionContext.role = null;
  });
  AuthService service(List<String>? roles, {int selectionStatus = 200}) =>
      AuthService.forTesting(MockClient((request) async {
        if (request.url.path == '/account/login') {
          return http.Response(
              jsonEncode({
                'jwt': 'token',
                'session_id': 'session',
                'user': {
                  'id': 'u',
                  'name': 'Test User',
                  'email': 'test@example.com',
                  'role': 'caretaker',
                  if (roles != null) 'roles': roles
                }
              }),
              200);
        }
        expect(request.url.path, '/account/roles/technician');
        expect(request.headers['Authorization'], 'Bearer token');
        return http.Response(jsonEncode({'role': 'technician', 'roles': roles}),
            selectionStatus);
      }));

  test('Single and legacy accounts go straight to dashboard', () async {
    for (final roles in [
      null,
      ['caretaker']
    ]) {
      final auth = service(roles);
      expect(
          (await auth.login('test@example.com', 'password')).success, isTrue);
      expect(auth.getDashboardRoute(), '/caretaker_dashboard');
    }
  });
  test(
      'Multiple roles require a choice, verified selection persists active workspace',
      () async {
    final auth = service(['caretaker', 'technician']);
    await auth.login('test@example.com', 'password');
    expect(auth.getDashboardRoute(), '/select-role');
    expect(ApiSessionContext.role, isNull);
    final pending = service(['caretaker', 'technician']);
    await pending.initialize();
    expect(pending.getDashboardRoute(), '/select-role');
    await auth.selectRole(UserRole.technician);
    expect(auth.getDashboardRoute(), '/technician_dashboard');
    expect(ApiSessionContext.role, 'technician');
    final restored = service(['caretaker', 'technician']);
    await restored.initialize();
    expect(restored.getDashboardRoute(), '/technician_dashboard');
    expect(
        restored.currentUser!.roles, [UserRole.caretaker, UserRole.technician]);
  });
  test('Rejected role choice never opens a dashboard', () async {
    final auth = service(['caretaker', 'technician'], selectionStatus: 403);
    await auth.login('test@example.com', 'password');
    await expectLater(auth.selectRole(UserRole.technician), throwsException);
    expect(auth.getDashboardRoute(), '/select-role');
    expect(auth.currentUser!.role, UserRole.caretaker);
  });
  test(
      'Session headers only go to our API and exclude active role on account routes',
      () async {
    ApiSessionContext.jwt = 'token';
    ApiSessionContext.role = 'technician';
    final requests = <http.Request>[];
    final client = ConnectedApiClient(inner: MockClient((r) async {
      requests.add(r);
      return http.Response('{}', 200);
    }));
    await client.get(Uri.parse('${ApiSessionContext.origin}/users'));
    await client.get(Uri.parse('https://unrelated.example/users'));
    await client.get(Uri.parse('${ApiSessionContext.origin}/account/roles'));
    expect(requests[0].headers['Authorization'], 'Bearer token');
    expect(requests[0].headers['X-Active-Role'], 'technician');
    expect(requests[1].headers['Authorization'], isNull);
    expect(requests[1].headers['X-Active-Role'], isNull);
    expect(requests[2].headers['X-Active-Role'], isNull);
    client.close();
  });
  test('Every canonical backend role round trips', () {
    for (final role in UserRole.values) {
      expect(UserRole.fromString(role.apiValue), role);
    }
  });
}
