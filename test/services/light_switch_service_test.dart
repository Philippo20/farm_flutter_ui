import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/services/light_switch_service.dart';
import 'package:farmestates_ai_dashbaord/services/api_session_context.dart';

class SuspendedLightClient extends http.BaseClient {
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
  testWidgets('light timeout aborts transport before another poll can start',
      (tester) async {
    final client = SuspendedLightClient();
    final service = LightSwitchService(client: client, token: () => 'jwt');
    final assertion = expectLater(
        service.state('LIGHT-001'), throwsA(isA<TimeoutException>()));
    await tester.pump(const Duration(seconds: 8));
    await assertion;
    expect(client.active, 0);
    service.dispose();
  });
  testWidgets('sleep cancellation aborts the outstanding status request',
      (tester) async {
    final client = SuspendedLightClient();
    final service = LightSwitchService(client: client, token: () => 'jwt');
    final assertion = expectLater(service.state('LIGHT-001'),
        throwsA(isA<http.RequestAbortedException>()));
    service.cancelPolling();
    await tester.pump();
    await assertion;
    expect(client.active, 0);
    service.dispose();
  });
  testWidgets('paused authentication refresh cannot send a late poll',
      (tester) async {
    var calls = 0;
    final refresh = Completer<void>();
    final service = LightSwitchService(
        token: () => 'jwt',
        refresh: () => refresh.future,
        client: MockClient((request) async {
          calls++;
          return http.Response('{}', 401);
        }));
    final assertion = expectLater(service.state('LIGHT-001'),
        throwsA(isA<http.RequestAbortedException>()));
    await tester.pump();
    service.cancelPolling();
    refresh.complete();
    await tester.pump();
    await assertion;
    expect(calls, 1);
    service.dispose();
  });
  test('switch submission uses selected role and is not replayed on error',
      () async {
    final previous = ApiSessionContext.role;
    ApiSessionContext.role = 'caretaker';
    addTearDown(() => ApiSessionContext.role = previous);
    var calls = 0;
    final service = LightSwitchService(
        token: () => 'jwt',
        client: MockClient((request) async {
          calls++;
          expect(request.method, 'POST');
          expect(request.headers['X-Active-Role'], 'caretaker');
          expect(jsonDecode(request.body)['desired_on'], true);
          return http.Response('{"detail":"Controller busy"}', 409);
        }));
    await expectLater(service.command('LIGHT-001', true, service.requestId()),
        throwsException);
    expect(calls, 1);
    service.dispose();
  });
}
