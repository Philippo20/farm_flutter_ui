import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import '../../lib/services/messaging_service.dart';

void main() {
  test('loads the authenticated notification inbox and conversation target',
      () async {
    final service = MessagingService(
      token: () => 'session-token',
      client: MockClient((request) async {
        expect(request.url.path, '/messages/notifications');
        expect(request.headers['Authorization'], 'Bearer session-token');
        return http.Response(
            jsonEncode({
              'notifications': [
                {'id': 'message:one', 'peer_id': 'alice', 'is_read': false}
              ]
            }),
            200);
      }),
    );
    final rows = await service.notifications();
    expect(rows.single['peer_id'], 'alice');
    expect(rows.single['is_read'], false);
    service.dispose();
  });
  test('sends authenticated text and a stable retry identifier', () async {
    final service = MessagingService(
        token: () => 'session-token',
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer session-token');
          expect(jsonDecode(request.body),
              {'text': 'Hello', 'request_id': 'stable_request_123'});
          return http.Response(
              jsonEncode({'id': 'saved-1', 'text': 'Hello'}), 200);
        }));
    expect((await service.send('peer-1', 'Hello', 'stable_request_123'))['id'],
        'saved-1');
    service.dispose();
  });
  test('server failures are not reported as sent messages', () async {
    final service = MessagingService(
        token: () => 'token',
        client: MockClient(
            (_) async => http.Response('{"detail":"Session expired"}', 401)));
    await expectLater(
        service.send('peer', 'Hello', 'request_123456789'), throwsException);
    service.dispose();
  });
  test('missing authentication never makes a request', () async {
    final service = MessagingService(
        token: () => null,
        client: MockClient((_) async {
          fail('Unauthenticated request reached transport');
        }));
    await expectLater(service.conversations(), throwsException);
    service.dispose();
  });
}
