import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/services/command_device_service.dart';
import 'package:farmestates_ai_dashbaord/services/superadmin_api_service.dart';
import 'package:farmestates_ai_dashbaord/services/api_session_context.dart';

class AbortTestClient extends http.BaseClient {
  int active = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    active++;
    final result = Completer<http.StreamedResponse>();
    (request as http.Abortable).abortTrigger!.then((_) {
      active--;
      result.completeError(http.RequestAbortedException(request.url));
    });
    return result.future;
  }
}

void main() {
  testWidgets('timeout aborts the HTTP transport before the request completes',
      (tester) async {
    final transport = AbortTestClient();
    final api = CommandDeviceService(client: transport, token: () => 'token');
    final assertion =
        expectLater(api.state('F-001'), throwsA(isA<SuperAdminApiException>()));
    expect(transport.active, 1);
    await tester.pump(const Duration(seconds: 8));
    await assertion;
    expect(transport.active, 0);
    api.dispose();
  });
  test('stopping polling aborts its transport', () async {
    final transport = AbortTestClient();
    final api = CommandDeviceService(client: transport, token: () => 'token');
    final assertion = expectLater(
        api.state('F-001'), throwsA(isA<http.RequestAbortedException>()));
    api.cancelPolling();
    await assertion;
    expect(transport.active, 0);
    api.dispose();
  });
  test('direct polling retains the active role header', () async {
    final previous = ApiSessionContext.role;
    ApiSessionContext.role = 'farm_owner';
    addTearDown(() => ApiSessionContext.role = previous);
    final api = CommandDeviceService(
        token: () => 'token',
        client: MockClient((request) async {
          expect(request.headers['X-Active-Role'], 'farm_owner');
          return http.Response('{"online":true}', 200);
        }));
    addTearDown(api.dispose);
    expect((await api.state('F-001'))['online'], isTrue);
  });
  test('stop during authentication refresh cannot start another HTTP poll',
      () async {
    final refreshing = Completer<void>(), finishRefresh = Completer<void>();
    var requests = 0;
    final api = CommandDeviceService(
        token: () => 'token',
        refresh: () async {
          refreshing.complete();
          await finishRefresh.future;
        },
        client: MockClient((_) async {
          requests++;
          return http.Response('{}', 401);
        }));
    final assertion = expectLater(
        api.state('F-001'), throwsA(isA<http.RequestAbortedException>()));
    await refreshing.future;
    api.cancelPolling();
    finishRefresh.complete();
    await assertion;
    expect(requests, 1);
    api.dispose();
  });
  test('authentication refresh preserves the same command request identity',
      () async {
    var calls = 0, refreshes = 0;
    var token = 'expired';
    final id = newCommandId();
    final api = CommandDeviceService(
        token: () => token,
        refresh: () async {
          token = 'new-token';
          refreshes++;
        },
        client: MockClient((request) async {
          expect(request.url.path, '/command-devices/F-001/commands');
          expect(jsonDecode(request.body), {
            'command_key': 'start',
            'request_id': id,
            'config_revision':
                'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
          });
          expect(request.headers['Authorization'],
              calls == 0 ? 'Bearer expired' : 'Bearer new-token');
          calls++;
          return calls == 1
              ? http.Response('{}', 401)
              : http.Response('{"pending":true}', 200);
        }));
    addTearDown(api.dispose);
    expect(
        (await api.send('F-001', 'start', id,
                revision:
                    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'))[
            'pending'],
        true);
    expect(calls, 2);
    expect(refreshes, 1);
  });
  test(
      'proxy errors stay readable without exposing HTML or a decoding exception',
      () async {
    final api = CommandDeviceService(
        token: () => 'token',
        client: MockClient(
            (_) async => http.Response('<html>Proxy error</html>', 503)));
    addTearDown(api.dispose);
    await expectLater(
        api.state('F-001'),
        throwsA(isA<SuperAdminApiException>().having((e) => e.toString(),
            'message', contains('Unable to load device commands (503)'))));
  });
}
