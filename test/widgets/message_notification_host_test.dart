import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/message_notification_host.dart';
import 'package:farmestates_ai_dashbaord/core/providers/notification_provider.dart';
import 'package:farmestates_ai_dashbaord/services/messaging_service.dart';

void main() {
  testWidgets(
      'Android alerts arrive once, skip active chats and clear on logout',
      (tester) async {
    final calls = <MethodCall>[];
    const channel = MethodChannel('farmestates/message_notifications');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      calls.add(call);
      return null;
    });
    final user = StateProvider<String?>((ref) => 'bob');
    final container = ProviderContainer(overrides: [
      messageNotificationUserProvider.overrideWith((ref) => ref.watch(user)),
    ]);
    var rows = <Map<String, dynamic>>[];
    final service = MessagingService(
        token: () => 'test',
        client: MockClient((_) async =>
            http.Response(jsonEncode({'notifications': rows}), 200)));
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            home: MessageNotificationHost(
                service: service,
                child: const Scaffold(body: Text('Dashboard'))))));
    await tester.pump();
    expect(calls.where((call) => call.method == 'requestPermission'),
        hasLength(1));
    rows = [
      {
        'id': 'message:one',
        'message_id': 'one',
        'peer_id': 'alice',
        'title': 'Alice',
        'message': 'Hello',
        'created_at': '2026-09-07T10:00:00Z',
        'is_read': false,
      }
    ];
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(container.read(notificationProvider).single.isRead, false);
    expect(calls.where((call) => call.method == 'show'), hasLength(1));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(calls.where((call) => call.method == 'show'), hasLength(1));
    container.read(activeMessagePeerProvider.notifier).state = 'alice';
    rows = [
      ...rows,
      {...rows.first, 'id': 'message:two', 'message_id': 'two'}
    ];
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(calls.where((call) => call.method == 'show'), hasLength(1));
    expect(calls.where((call) => call.method == 'dismiss'), isNotEmpty);
    container.read(user.notifier).state = null;
    await tester.pump();
    await tester.pump();
    expect(container.read(notificationProvider), isEmpty);
    expect(calls.last.method, 'clear');
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
