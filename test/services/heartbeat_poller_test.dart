import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/services/heartbeat_poller.dart';

void main() {
  testWidgets(
      'proxied controller silence is syncing until server confirms offline',
      (tester) async {
    final delayed = Completer<Map<String, dynamic>>();
    var calls = 0;
    final poller = HeartbeatPoller<Map<String, dynamic>>(
        controllerStatus: (data) => data,
        fetch: () async {
          if (++calls > 1) return delayed.future;
          return {
            'online': true,
            'controller_session_id': 'boot',
            'seen_at': '2026-10-22T12:00:00Z',
            'server_time': '2026-10-22T12:00:00Z'
          };
        });
    poller.startPolling();
    await tester.pump();
    expect(poller.isOnline, true);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 3500));
    expect(poller.isOnline, false);
    expect(poller.isSynchronizing, true);
    expect(poller.isOfflineConfirmed, false);
    expect(calls, 2);
    delayed.complete({
      'online': false,
      'controller_session_id': 'boot',
      'seen_at': '2026-10-22T12:00:00Z',
      'server_time': '2026-10-22T12:00:06Z'
    });
    await tester.pump();
    expect(poller.isOfflineConfirmed, true);
    expect(poller.isSynchronizing, false);
    poller.dispose();
  });

  testWidgets('slow requests finish before the two-second delay starts',
      (tester) async {
    final first = Completer<int>();
    var calls = 0;
    final poller = HeartbeatPoller<int>(fetch: () {
      calls++;
      return first.future;
    });
    poller.startPolling();
    poller.startPolling();
    await tester.pump(const Duration(seconds: 10));
    expect(calls, 1);
    expect(poller.isOnline, isFalse);
    first.complete(1);
    await tester.pump();
    expect(poller.isOnline, isTrue);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(calls, 1);
    await tester.pump(const Duration(milliseconds: 1));
    expect(calls, 2);
    poller.dispose();
  });

  testWidgets('one failed request preserves online until exactly 5.5 seconds',
      (tester) async {
    var calls = 0;
    final poller = HeartbeatPoller<int>(fetch: () async {
      if (++calls > 1) throw Exception('Temporary network jitter');
      return 1;
    });
    poller.startPolling();
    await tester.pump();
    expect(poller.isOnline, isTrue);
    await tester.pump(const Duration(seconds: 2));
    expect(poller.lastError, isNotNull);
    expect(poller.isOnline, isTrue);
    await tester.pump(const Duration(milliseconds: 3499));
    expect(poller.isOnline, isTrue);
    await tester.pump(const Duration(milliseconds: 1));
    expect(poller.isOnline, isFalse);
    poller.dispose();
  });

  testWidgets('grace expires while a request is hung and recovers on receipt',
      (tester) async {
    final delayed = Completer<int>();
    var calls = 0;
    final poller = HeartbeatPoller<int>(
        fetch: () => ++calls == 1 ? Future.value(1) : delayed.future);
    poller.startPolling();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 3500));
    expect(calls, 2);
    expect(poller.isOnline, isFalse);
    delayed.complete(2);
    await tester.pump();
    expect(poller.isOnline, isTrue);
    expect(poller.data, 2);
    poller.dispose();
  });

  testWidgets('stop is immediate and late responses cannot restore presence',
      (tester) async {
    final delayed = Completer<int>();
    var calls = 0;
    final poller = HeartbeatPoller<int>(
        fetch: () => ++calls == 1 ? Future.value(1) : delayed.future);
    poller.startPolling();
    await tester.pump();
    expect(poller.isOnline, isTrue);
    await tester.pump(const Duration(seconds: 2));
    poller.stopPolling();
    expect(poller.isOnline, isFalse);
    delayed.complete(2);
    await tester.pump(const Duration(seconds: 20));
    expect(poller.data, 1);
    expect(poller.isOnline, isFalse);
    expect(calls, 2);
    poller.dispose();
  });

  testWidgets('stop and restart cannot stack requests or adopt an old response',
      (tester) async {
    final old = Completer<int>();
    var calls = 0;
    final poller = HeartbeatPoller<int>(
        fetch: () => ++calls == 1 ? old.future : Future.value(2));
    poller.startPolling();
    poller.stopPolling();
    poller.startPolling();
    await tester.pump(const Duration(seconds: 10));
    expect(calls, 1);
    old.complete(1);
    await tester.pump();
    await tester.pump();
    expect(calls, 2);
    expect(poller.data, 2);
    poller.dispose();
  });

  testWidgets('manual refresh joins an in-flight request', (tester) async {
    var calls = 0;
    final response = Completer<int>();
    final poller = HeartbeatPoller<int>(fetch: () {
      calls++;
      return response.future;
    });
    poller.startPolling();
    final a = poller.refresh(), b = poller.refresh();
    expect(identical(a, b), isTrue);
    expect(calls, 1);
    response.complete(1);
    await a;
    poller.dispose();
  });

  testWidgets('cached device heartbeats cannot renew grace indefinitely',
      (tester) async {
    var source = DateTime.utc(2026, 10, 17);
    final poller = HeartbeatPoller<DateTime>(
        fetch: () async => source, sourceHeartbeat: (value) => value);
    poller.startPolling();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 1500));
    expect(poller.isOnline, isFalse);
    source = source.add(const Duration(seconds: 6));
    await poller.refresh();
    expect(poller.isOnline, isTrue);
    poller.dispose();
  });

  testWidgets(
      'a new packet renews the full grace from receipt, not request start',
      (tester) async {
    final response = Completer<int>();
    var calls = 0;
    final pending = Completer<int>();
    final poller = HeartbeatPoller<int>(
        fetch: () => ++calls == 1 ? response.future : pending.future);
    poller.startPolling();
    await tester.pump(const Duration(seconds: 4));
    response.complete(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 5499));
    expect(poller.isOnline, isTrue);
    await tester.pump(const Duration(milliseconds: 1));
    expect(poller.isOnline, isFalse);
    poller.dispose();
    pending.complete(2);
    await tester.pump();
  });
}
