import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/services/api_connection.dart';
import 'package:farmestates_ai_dashbaord/services/api_session_context.dart';

Uri endpoint(String path) => Uri.parse('${ApiSessionContext.origin}$path');
ApiConnection connection(WidgetTester tester) =>
    ApiConnection(now: tester.binding.clock.now);
Future<void> confirmOutage(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(seconds: 3));
  }
}

class StreamClient extends http.BaseClient {
  StreamClient(this.handle);
  final Future<http.StreamedResponse> Function(http.BaseRequest) handle;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      handle(request);
}

void main() {
  testWidgets('unlock quietly recovers without a false outage', (tester) async {
    final state = connection(tester);
    addTearDown(state.dispose);
    final epoch = state.lifecycleEpoch;
    state.setForeground(false);
    var probes = 0;
    var recovered = false;
    unawaited(state.failed(() async {
      probes++;
      return true;
    }, requestEpoch: epoch).then((_) => recovered = true));
    await tester.pump(const Duration(seconds: 10));
    expect(state.unavailable, isFalse);
    expect(probes, 0);
    state.setForeground(true);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(probes, 1);
    expect(recovered, isTrue);
    expect(state.unavailable, isFalse);
  });

  testWidgets('resume grace is not extended by repeated stale failures',
      (tester) async {
    final state = connection(tester);
    addTearDown(state.dispose);
    final epoch = state.lifecycleEpoch;
    state.setForeground(false);
    state.setForeground(true);
    var probes = 0;
    Future<bool> probe() async {
      probes++;
      return false;
    }

    for (var i = 0; i < 4; i++) {
      unawaited(state.failed(probe, requestEpoch: epoch));
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pump();
    expect(probes, 1);
    expect(state.unavailable, isFalse);
    await confirmOutage(tester);
    expect(state.unavailable, isTrue);
    state.setForeground(false);
  });

  testWidgets('requests wait in background and resume normally',
      (tester) async {
    final state = connection(tester);
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
    final response = client.get(endpoint('/farms'));
    await tester.pump(const Duration(seconds: 10));
    expect(calls, 0);
    state.setForeground(true);
    await tester.pump(const Duration(seconds: 2));
    expect((await response).statusCode, 200);
    expect(calls, 1);
  });

  testWidgets('sustained outages are confirmed and pending reads recover',
      (tester) async {
    final state = connection(tester);
    addTearDown(state.dispose);
    var online = false;
    final paths = <String>[];
    final client = ConnectedApiClient(
        connection: state,
        inner: MockClient((r) async {
          paths.add(r.url.path);
          if (!online) throw http.ClientException('network down');
          return http.Response('[]', 200);
        }));
    addTearDown(client.close);
    final first = client.get(endpoint('/farms'));
    final second = client.get(endpoint('/tasks'));
    await tester.pump();
    expect(state.unavailable, isFalse);
    await confirmOutage(tester);
    expect(state.unavailable, isTrue);
    expect(paths.where((p) => p == '/farms').length, 1);
    expect(paths.where((p) => p == '/tasks').length, 1);
    online = true;
    await state.retry();
    await tester.pump();
    expect((await first).statusCode, 200);
    expect((await second).statusCode, 200);
    expect(state.unavailable, isFalse);
  });

  test('writes are never replayed; health has no auth or original payload',
      () async {
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
          expect(r.url.path, '/health');
          expect(r.headers['Authorization'], isNull);
          expect(r.headers['X-Active-Role'], isNull);
          expect(r.body, isEmpty);
          return http.Response('', 404);
        }));
    addTearDown(client.close);
    await expectLater(
        client.post(endpoint('/users'),
            headers: {
              'Authorization': 'Bearer private',
              'X-Active-Role': 'admin'
            },
            body: 'private form'),
        throwsA(isA<http.ClientException>()));
    expect(state.submissionInterrupted, isTrue);
    await state.retry();
    expect(writes, 1);
    expect(state.unavailable, isFalse);
  });

  testWidgets(
      'slow endpoint gets one retry and never declares healthy API offline',
      (tester) async {
    final state = connection(tester);
    addTearDown(state.dispose);
    var reads = 0, probes = 0;
    final client = ConnectedApiClient(
        connection: state,
        inner: MockClient((r) async {
          if (r.url.path == '/health') {
            probes++;
            return http.Response('{}', 200);
          }
          reads++;
          throw http.ClientException('endpoint timed out');
        }));
    addTearDown(client.close);
    var showedOffline = false;
    state.addListener(() => showedOffline |= state.unavailable);
    final result = expectLater(
        client.get(endpoint('/reports')), throwsA(isA<http.ClientException>()));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    await result;
    expect(reads, 2);
    expect(probes, greaterThanOrEqualTo(1));
    expect(showedOffline, isFalse);
  });

  testWidgets('a nine-second API response is slow, not disconnected',
      (tester) async {
    final state = connection(tester);
    addTearDown(state.dispose);
    final client = ConnectedApiClient(
        connection: state,
        inner: MockClient((_) async {
          await Future<void>.delayed(const Duration(seconds: 9));
          return http.Response('ok', 200);
        }));
    addTearDown(client.close);
    final result = client.get(endpoint('/reports'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 9));
    expect((await result).statusCode, 200);
    expect(state.unavailable, isFalse);
    expect(state.checking, isFalse);
  });

  testWidgets('one failed probe never shows offline and checks cannot stack',
      (tester) async {
    final state = connection(tester);
    addTearDown(state.dispose);
    final pending = Completer<bool>();
    var probes = 0;
    for (var i = 0; i < 30; i++) {
      unawaited(state.failed(() {
        probes++;
        return pending.future;
      }));
    }
    await tester.pump();
    unawaited(state.retry());
    await tester.pump(const Duration(seconds: 20));
    expect(probes, 1);
    expect(state.unavailable, isFalse);
    pending.complete(false);
    await tester.pump();
    expect(state.unavailable, isFalse);
    await tester.pump(const Duration(seconds: 3));
    expect(probes, 2);
    expect(state.unavailable, isTrue);
    state.setForeground(false);
  });

  testWidgets('late probe cannot overwrite a newer success or recovery cycle',
      (tester) async {
    final state = connection(tester);
    addTearDown(state.dispose);
    final old = Completer<bool>();
    unawaited(state.failed(() => old.future));
    await tester.pump(const Duration(milliseconds: 1));
    expect(state.checking, isTrue);
    state.succeeded(state.lifecycleEpoch);
    var newRecovered = false;
    var online = false;
    unawaited(
        state.failed(() async => online).then((_) => newRecovered = true));
    old.complete(true);
    await tester.pump();
    expect(newRecovered, isFalse);
    await tester.pump(const Duration(seconds: 3));
    expect(newRecovered, isFalse);
    expect(state.unavailable, isFalse);
    online = true;
    await state.retry();
    await tester.pump();
    expect(newRecovered, isTrue);
  });

  testWidgets('success on another API request cancels a stale failed check',
      (tester) async {
    final state = connection(tester);
    addTearDown(state.dispose);
    final pending = Completer<bool>();
    unawaited(state.failed(() => pending.future));
    await tester.pump(const Duration(milliseconds: 1));
    expect(state.checking, isTrue);
    state.succeeded(state.lifecycleEpoch);
    pending.complete(false);
    await tester.pump(const Duration(seconds: 20));
    expect(state.unavailable, isFalse);
    expect(state.checking, isFalse);
  });

  test('HTTP validation and server errors stay local', () async {
    final state = ApiConnection();
    addTearDown(state.dispose);
    for (final code in [401, 403, 422, 500, 503]) {
      final client = ConnectedApiClient(
          connection: state,
          inner: MockClient((_) async => http.Response('error', code)));
      expect((await client.get(endpoint('/farms'))).statusCode, code);
      expect((await client.post(endpoint('/farms'))).statusCode, code);
      expect(state.unavailable, isFalse);
      client.close();
    }
  });

  test('external service failure does not mark the application API offline',
      () async {
    final state = ApiConnection();
    addTearDown(state.dispose);
    final client = ConnectedApiClient(
        connection: state,
        inner: MockClient(
            (_) async => throw http.ClientException('third party failed')));
    addTearDown(client.close);
    await expectLater(client.get(Uri.parse('https://external.test/file')),
        throwsA(isA<http.ClientException>()));
    expect(state.unavailable, isFalse);
    expect(state.checking, isFalse);
    expect(state.submissionInterrupted, isFalse);
  });

  test('multipart body and generated boundary survive deadline wrapping',
      () async {
    final state = ApiConnection();
    addTearDown(state.dispose);
    final client = ConnectedApiClient(
        connection: state,
        inner: MockClient((r) async {
          expect(r.headers['content-type'],
              startsWith('multipart/form-data; boundary='));
          expect(r.body, contains('farm-name'));
          expect(r.body, contains('field-value'));
          expect(r.bodyBytes.length, r.contentLength);
          return http.Response('{}', 200);
        }));
    addTearDown(client.close);
    final request = http.MultipartRequest('POST', endpoint('/farms'))
      ..fields['farm-name'] = 'field-value';
    expect((await client.send(request)).statusCode, 200);
  });

  testWidgets('body timeout aborts transport and never replays a submission',
      (tester) async {
    final state = connection(tester);
    addTearDown(state.dispose);
    var aborted = false, sends = 0;
    final inner = StreamClient((request) async {
      if (request.method == 'GET') {
        return http.StreamedResponse(Stream.value([123, 125]), 200);
      }
      sends++;
      final body = StreamController<List<int>>();
      unawaited((request as http.Abortable).abortTrigger!.then((_) {
        aborted = true;
        body.addError(http.RequestAbortedException(request.url));
        unawaited(body.close());
      }));
      return http.StreamedResponse(body.stream, 200);
    });
    final client = ConnectedApiClient(
        connection: state, inner: inner, timeout: const Duration(seconds: 2));
    addTearDown(client.close);
    final result = expectLater(
        client.post(endpoint('/users')), throwsA(isA<http.ClientException>()));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await result;
    expect(aborted, isTrue);
    expect(sends, 1);
    expect(state.unavailable, isFalse);
    state.setForeground(false);
  });

  test('caller cancellation does not start connectivity recovery', () async {
    final state = ApiConnection();
    addTearDown(state.dispose);
    final abort = Completer<void>();
    final client = ConnectedApiClient(
        connection: state,
        inner: StreamClient((request) async {
          await (request as http.Abortable).abortTrigger;
          throw http.RequestAbortedException(request.url);
        }));
    addTearDown(client.close);
    final request = http.AbortableRequest('GET', endpoint('/farms'),
        abortTrigger: abort.future);
    final result = expectLater(
        client.send(request), throwsA(isA<http.RequestAbortedException>()));
    abort.complete();
    await result;
    expect(state.unavailable, isFalse);
    expect(state.checking, isFalse);
  });
}
