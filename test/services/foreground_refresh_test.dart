import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/services/foreground_refresh.dart';

void main() {
  testWidgets(
      'slow refreshes never stack and wait five seconds after completion',
      (tester) async {
    var calls = 0;
    final pending = Completer<void>();
    final poller = ForegroundRefresh(fetch: (_) {
      calls++;
      return pending.future;
    });
    final first = poller.refresh();
    expect(identical(first, poller.refresh()), true);
    await tester.pump(const Duration(seconds: 30));
    expect(calls, 1);
    pending.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 4999));
    expect(calls, 1);
    await tester.pump(const Duration(milliseconds: 1));
    expect(calls, 2);
    poller.dispose();
  });
  testWidgets(
      'sleep invalidates old failures and immediately refreshes on wake without stacking',
      (tester) async {
    var calls = 0;
    final pending = Completer<String>();
    final applied = <String>[], errors = <String>[];
    final poller = ForegroundRefresh(fetch: (ticket) async {
      calls++;
      try {
        final result = calls == 1 ? await pending.future : 'Fresh data';
        if (ticket.isCurrent) applied.add(result);
      } catch (error) {
        if (ticket.isCurrent) errors.add('$error');
      }
    });
    unawaited(poller.refresh());
    poller.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 10));
    expect(calls, 1);
    poller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(calls, 1);
    pending.completeError(Exception('Socket suspended during sleep'));
    await tester.pump();
    await tester.pump();
    expect(calls, 2);
    expect(errors, isEmpty);
    expect(applied, ['Fresh data']);
    poller.dispose();
  });
  testWidgets('temporary focus loss does not pause or duplicate refreshes',
      (tester) async {
    var calls = 0;
    RefreshTicket? ticket;
    final poller = ForegroundRefresh(fetch: (value) async {
      ticket = value;
      calls++;
    });
    await poller.refresh();
    poller.didChangeAppLifecycleState(AppLifecycleState.inactive);
    poller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    expect(calls, 1);
    expect(ticket!.isCurrent, true);
    poller.dispose();
    expect(ticket!.isCurrent, false);
  });
  testWidgets(
      'disposal invalidates in-flight data and cancels future refreshes',
      (tester) async {
    final pending = Completer<void>();
    var calls = 0, updates = 0;
    final poller = ForegroundRefresh(fetch: (ticket) async {
      calls++;
      await pending.future;
      if (ticket.isCurrent) updates++;
    });
    unawaited(poller.refresh());
    poller.dispose();
    pending.complete();
    await tester.pump(const Duration(seconds: 30));
    expect(calls, 1);
    expect(updates, 0);
    expect(tester.takeException(), isNull);
  });
}
