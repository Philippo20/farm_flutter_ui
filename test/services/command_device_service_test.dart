import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/services/command_device_service.dart';
import 'package:farmestates_ai_dashbaord/services/superadmin_api_service.dart';

void main() {
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
