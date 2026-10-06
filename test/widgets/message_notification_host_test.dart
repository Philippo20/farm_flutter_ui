import 'dart:convert';
import 'dart:async';
import 'package:farmestates_ai_dashbaord/core/models/notification/notification_model.dart';
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
                refreshInbox: (_) async {},
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
  testWidgets(
      'Workflow alerts baseline, deduplicate, sync read state and ignore a disposed response',
      (tester) async {
    final calls = <MethodCall>[];
    const channel = MethodChannel('farmestates/message_notifications');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      calls.add(call);
      return call.method == 'show' ? false : null; // Permission denied.
    });
    final container = ProviderContainer(overrides: [
      messageNotificationUserProvider.overrideWith((ref) => 'owner'),
    ]);
    final service = MessagingService(
        token: () => 'test',
        client: MockClient(
            (_) async => http.Response('{"notifications":[]}', 200)));
    final notifier = container.read(notificationProvider.notifier);
    NotificationModel item(String id) => NotificationModel(
        id: id,
        title: 'Maintenance due',
        message: 'Check device',
        type: NotificationType.maintenance,
        createdAt: DateTime(2026));
    Completer<void>? pending;
    var first = true;
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          scaffoldMessengerKey: messageScaffoldKey,
          home: MessageNotificationHost(
              service: service,
              refreshInbox: (_) async {
                if (first) {
                  first = false;
                  notifier.addNotification(item('historical'));
                }
                await pending?.future;
              },
              child: const Scaffold(body: Text('Dashboard'))),
        )));
    await tester.pump();
    expect(calls.where((c) => c.method == 'show'), isEmpty);
    notifier.addNotification(item('new'));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(calls.where((c) => c.method == 'show'), hasLength(1));
    expect(find.text('Maintenance due'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(calls.where((c) => c.method == 'show'), hasLength(1));
    notifier.markAsRead('new');
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(
        calls.where((c) =>
            c.method == 'dismiss' && c.arguments['peerId'] == '__inbox__:new'),
        hasLength(1));
    pending = Completer<void>();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
    container.dispose();
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
