import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/services/api_connection.dart';

void main() {
  test('failed reads resume after one shared connection retry', () async {
    final state = ApiConnection();
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
    expect(state.unavailable, isTrue);
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
    var writes = 0;
    final client = ConnectedApiClient(
        connection: state,
        inner: MockClient((r) async {
          if (r.method == 'POST') {
            writes++;
            return http.Response('unavailable', 503);
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
    final client = ConnectedApiClient(
        connection: state,
        timeout: const Duration(milliseconds: 5),
        inner: MockClient((_) => Completer<http.Response>().future));
    await expectLater(client.post(Uri.parse('https://example.test/users')),
        throwsA(isA<http.ClientException>()));
    expect(state.unavailable, isTrue);
    client.close();
  });
}
