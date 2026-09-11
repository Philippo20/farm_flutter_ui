import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/services/api_connection.dart';

void main() {
  testWidgets('unlock quietly recovers interrupted requests', (tester) async {
    final state = ApiConnection();
    addTearDown(state.dispose);
    final epoch = state.lifecycleEpoch;
    state.setForeground(false);
    var probes = 0;
    var recovered = false;
    state.failed(() async {
      probes++;
      return true;
    }, requestEpoch: epoch).then((_) => recovered = true);
    await tester.pump(const Duration(seconds: 10));
    expect(state.unavailable, isFalse);
    expect(probes, 0);
    state.setForeground(true);
    await tester.pump(const Duration(seconds: 2));
    expect(probes, 1);
    expect(recovered, isTrue);
    expect(state.unavailable, isFalse);
  });

  testWidgets(
      'late background failure verifies connection before showing error',
      (tester) async {
    final state = ApiConnection();
    addTearDown(state.dispose);
    final epoch = state.lifecycleEpoch;
    state.setForeground(false);
    state.setForeground(true);
    unawaited(state.failed(() async => false, requestEpoch: epoch));
    expect(state.unavailable, isFalse);
    await tester.pump(const Duration(seconds: 2));
    expect(state.unavailable, isTrue);
    state.setForeground(false);
  });

  testWidgets('requests wait while backgrounded then resume', (tester) async {
    final state = ApiConnection();
    addTearDown(state.dispose);
    var calls = 0;
    final client = ConnectedApiClient(
        connection: state,
        inner: MockClient((_) async {
          calls++;
          return http.Response('ok', 200);
        }));
    addTearDown(client.close);
    state.setForeground(false);
    final response = client.get(Uri.parse('https://example.test/farms'));
    await tester.pump(const Duration(seconds: 10));
    expect(calls, 0);
    state.setForeground(true);
    await tester.pump(const Duration(seconds: 2));
    expect((await response).statusCode, 200);
    expect(calls, 1);
  });

  test('failed reads resume after one shared connection retry', () async {
    final state = ApiConnection();
    addTearDown(state.dispose);
    var online = false;
    var reads = 0;
    final client = ConnectedApiClient(
        connection: state,
        inner: MockClient((r) async {
          reads++;
          if (!online) throw http.ClientException('network down');
          return http.Response('[]', 200);
        }));
    final first = client.get(Uri.parse('https://example.test/farms'));
    final second = client.get(Uri.parse('https://example.test/tasks'));
    await Future<void>.delayed(Duration.zero);
    expect(state.unavailable, isFalse);
    await state.retry();
    expect(state.unavailable, isTrue);
    online = true;
    await state.retry();
    expect((await first).statusCode, 200);
    expect((await second).statusCode, 200);
    expect(state.unavailable, isFalse);
    expect(reads, 6);
    client.close();
  });

  test('failed writes are never replayed and validation stays local', () async {
    final state = ApiConnection();
    addTearDown(state.dispose);
    var writes = 0;
    final client = ConnectedApiClient(
        connection: state,
        inner: MockClient((r) async {
          if (r.method == 'POST') {
            writes++;
            throw http.ClientException('Transport interrupted');
          }
          return http.Response('', 404);
        }));
    await expectLater(client.post(Uri.parse('https://example.test/users')),
        throwsA(isA<http.ClientException>()));
    expect(state.submissionInterrupted, isTrue);
    await state.retry();
    expect(writes, 1);
    expect(state.unavailable, isFalse);
    client.close();
    for (final code in [401, 403, 422]) {
      final client = ConnectedApiClient(
          connection: state,
          inner: MockClient((_) async => http.Response('error', code)));
      expect(
          (await client.get(Uri.parse('https://example.test/users')))
              .statusCode,
          code);
      expect(state.unavailable, isFalse);
      client.close();
    }
  });

  test('a timed out submission reports the global connection failure',
      () async {
    final state = ApiConnection();
    addTearDown(state.dispose);
    final client = ConnectedApiClient(
        connection: state,
        timeout: const Duration(milliseconds: 5),
        inner: MockClient((_) => Completer<http.Response>().future));
    await expectLater(client.post(Uri.parse('https://example.test/users')),
        throwsA(isA<http.ClientException>()));
    expect(state.unavailable, isFalse);
    client.close();
  });
  testWidgets('transient failure recovers without displaying offline',
      (tester) async {
    final state = ApiConnection();
    addTearDown(state.dispose);
    var reads = 0;
    final client = ConnectedApiClient(
        connection: state,
        inner: MockClient((_) async {
          if (++reads == 1) throw http.ClientException('stale socket');
          return http.Response('ok', 200);
        }));
    addTearDown(client.close);
    var displayedOffline = false;
    state.addListener(() => displayedOffline |= state.unavailable);
    final request = client.get(Uri.parse('https://example.test/farms'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    expect((await request).statusCode, 200);
    expect(displayedOffline, isFalse);
  });

  testWidgets('offline recovery retries automatically without user interaction',
      (tester) async {
    final state = ApiConnection();
    addTearDown(state.dispose);
    var online = false;
    var recovered = false;
    unawaited(state.failed(() async => online).then((_) => recovered = true));
    await tester.pump(const Duration(milliseconds: 1));
    expect(state.unavailable, isTrue);
    online = true;
    await tester.pump(const Duration(seconds: 5));
    expect(recovered, isTrue);
    expect(state.unavailable, isFalse);
  });

  test('HTTP server errors never show a global internet failure', () async {
    final state = ApiConnection();
    addTearDown(state.dispose);
    final client = ConnectedApiClient(
        connection: state,
        inner: MockClient((_) async => http.Response('Server error', 500)));
    addTearDown(client.close);
    expect(
        (await client.get(Uri.parse('https://example.test/farms'))).statusCode,
        500);
    expect(
        (await client.post(Uri.parse('https://example.test/farms'))).statusCode,
        500);
    expect(state.unavailable, isFalse);
  });
}
