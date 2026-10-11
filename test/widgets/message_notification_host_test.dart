import 'dart:convert';
import 'dart:async';
import 'package:farmestates_ai_dashbaord/core/models/notification/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/message_notification_host.dart';
import 'package:farmestates_ai_dashbaord/core/providers/notification_provider.dart';
import 'package:farmestates_ai_dashbaord/services/messaging_service.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/notification_center.dart';
import 'package:farmestates_ai_dashbaord/models/user_model.dart';
import 'package:farmestates_ai_dashbaord/models/enums.dart';

class _MemoryInbox extends NotificationNotifier {
  @override
  void markAsRead(String id, {String? recipientId}) {
    state = [
      for (final item in state)
        item.id == id ? item.copyWith(isRead: true) : item
    ];
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
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
        isEmpty); // Startup owns the OS prompt, independent of account binding.
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
    final alert =
        calls.firstWhere((call) => call.method == 'show').arguments as Map;
    expect(alert['title'], 'Alice');
    expect(alert['body'], 'Hello');
    expect(alert['messageId'], 'one');
    expect(alert['timestamp'],
        DateTime.parse('2026-09-07T10:00:00Z').millisecondsSinceEpoch);
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

  for (final recipient in ['caretaker', 'other-account']) {
    testWidgets(
        'Android tap respects recipient and opens known role destination: $recipient',
        (tester) async {
      const channel = MethodChannel('farmestates/message_notifications');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
          (call) async {
        if (call.method == 'initialMessage') {
          return {'recipientId': recipient, 'peerId': '__inbox__:task-1'};
        }
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null));
      final inbox = _MemoryInbox();
      final user = UserModel(
          id: 'caretaker',
          name: 'Test',
          email: 'test@example.com',
          role: UserRole.caretaker,
          address: '',
          createdAt: DateTime(2026));
      final container = ProviderContainer(overrides: [
        messageNotificationUserProvider.overrideWith((ref) => 'caretaker'),
        notificationViewerProvider.overrideWith((ref) => user),
        notificationProvider.overrideWith((ref) => inbox),
      ]);
      final api = MessagingService(
          token: () => 'test',
          client: MockClient(
              (_) async => http.Response('{"notifications":[]}', 200)));
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            navigatorKey: messageNavigatorKey,
            routes: {
              '/calendar': (_) =>
                  const Scaffold(body: Text('Assigned task calendar'))
            },
            builder: (_, child) => MessageNotificationHost(
                service: api,
                refreshInbox: (_) async {
                  if (container.read(notificationProvider).isEmpty) {
                    inbox.addNotification(NotificationModel(
                      id: 'task-1',
                      title: 'Task assigned',
                      message: 'Please water the farm.',
                      type: NotificationType.task,
                      createdAt: DateTime(2026),
                      metadata: {'sourceType': 'task'},
                    ));
                  }
                },
                child: child!),
            home: const Scaffold(body: Text('Dashboard')),
          )));
      await tester.pumpAndSettle();
      expect(find.text('Assigned task calendar'),
          recipient == 'caretaker' ? findsOneWidget : findsNothing);
      expect(container.read(notificationProvider).single.isRead,
          recipient == 'caretaker');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    });
  }
}
