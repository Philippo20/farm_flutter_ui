import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/device_calibration_modal.dart';
import 'package:farmestates_ai_dashbaord/services/command_device_service.dart';
import 'package:farmestates_ai_dashbaord/services/heartbeat_poller.dart';

final boardState = <String, dynamic>{
  'controller_session_id': 'boot-session-one',
  'online': true,
  'ready': true,
  'commands': [
    {
      'id': 'select-ef',
      'label': 'E/F Drainage Calibration Mode',
      'value': 'EF_D_SELECT'
    },
    {
      'id': 'select-p',
      'label': 'P Rack Drainage Calibration Mode',
      'value': 'P_D_SELECT'
    },
    {
      'id': 'select-fert',
      'label': 'Fertigation Calibration',
      'value': 'FERT_D_SELECT'
    },
    {'id': 'start', 'label': 'Start Calibration', 'value': 'CAL_START'},
    {'id': 'stop', 'label': 'Stop Calibration', 'value': 'CAL_STOP'},
    {'id': 'cancel', 'label': 'Cancel Calibration', 'value': 'CAL_CANCEL'},
  ],
  'seen_at': '2026-10-17T12:00:00Z',
  'config_revision': 'a' * 64,
};
Map<String, dynamic> event(String id, String type, {String? reason}) => {
      'event_id': id,
      'calibration_id': 'selection-command-uuid',
      'command_id': 'triggering-command-uuid',
      'type': 'calibration.$type',
      'target': 'fertigation',
      'rack': 'E',
      'state': 'running',
      'message':
          'Controller measurement report for the selected fertigation rack.',
      'reason': reason,
      'uptime_ms': 125000,
      'elapsed_ms': 12400,
      'saved': type == 'completed',
      if (type == 'completed') 'saved_duration_ms': 20000,
      'received_at': '2026-10-17T12:01:00Z',
      'selection_at': '2026-10-17T12:00:00Z',
    };
Map<String, dynamic> overview(String status) {
  final current = event('current', status);
  return {
    'current': {
      'session_id': 'boot-session-one',
      'calibration_id': 'selection-command-uuid',
      'target': 'fertigation',
      'rack': 'E',
      'status': status,
      'event': current
    },
    'latest_attempt': null,
    'saved_durations': [event('saved', 'completed')],
    'recent_events': [current],
    'next_cursor': 'older-cursor'
  };
}

class FakeCalibrationApi extends CommandDeviceService {
  Map<String, dynamic> data = overview('running');
  Completer<Map<String, dynamic>>? sending;
  int sends = 0;
  final sentKeys = <String>[], requestIds = <String>[];
  @override
  Future<Map<String, dynamic>> calibrations(String serial) async => data;
  @override
  Future<Map<String, dynamic>> calibrationHistory(String serial,
      {String? before}) async {
    expect(before, 'older-cursor');
    return {
      'events': [event('older', 'cancelled', reason: 'grid_power_lost')],
      'next_cursor': null
    };
  }

  @override
  Future<Map<String, dynamic>> send(String serial, String key, String request,
      {String? revision}) {
    expect(request.length, 36);
    expect(revision, 'a' * 64);
    sends++;
    sentKeys.add(key);
    requestIds.add(request);
    return sending!.future;
  }
}

void report(FakeCalibrationApi api, String status, String calibrationId,
    String commandId,
    {String? reason, String? previous}) {
  final next = event('$status-$commandId', status, reason: reason)
    ..['calibration_id'] = calibrationId
    ..['command_id'] = commandId;
  api.data = overview(status);
  final session = api.data['current'] as Map;
  session['calibration_id'] = calibrationId;
  session['event'] = session['latest_event'] = next;
  if (previous != null) {
    session['last_progress'] = {'type': 'calibration.$previous'};
  }
  api.data['latest_attempt'] = session;
  api.data['recent_events'] = [next];
}

Future<void> refresh(WidgetTester tester) async {
  await tester.tap(find.text('Refresh'));
  await tester.pumpAndSettle();
}

Future<void> acknowledge(WidgetTester tester, FakeCalibrationApi api) async {
  api.sending!.complete({
    ...boardState,
    'last_command': {'id': api.requestIds.last, 'status': 'confirmed'}
  });
  await tester.pumpAndSettle();
}

Future<HeartbeatPoller<Map<String, dynamic>>> mount(
    WidgetTester tester, FakeCalibrationApi api,
    {double width = 430,
    bool dark = false,
    bool online = true,
    bool allowSend = false}) async {
  tester.view.physicalSize = Size(width, 950);
  tester.view.devicePixelRatio = 1;
  final heartbeat = HeartbeatPoller<Map<String, dynamic>>(
      fetch: () async => {...boardState, 'online': online},
      isHeartbeat: (data) => data['online'] == true);
  heartbeat.startPolling();
  await tester.pump();
  await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
          brightness: dark ? Brightness.dark : Brightness.light,
          platform:
              width < 600 ? TargetPlatform.android : TargetPlatform.windows),
      home: Scaffold(
          body: Center(
              child: TextButton(
                  onPressed: () => showDeviceCalibration(
                      tester.element(find.text('Open calibration')),
                      serial: 'FARM-ESTATES-FARM-1-005',
                      deviceState: heartbeat,
                      allowSend: allowSend,
                      api: api),
                  child: const Text('Open calibration'))))));
  await tester.tap(find.text('Open calibration'));
  await tester.pumpAndSettle();
  return heartbeat;
}

Future<void> unmount(WidgetTester tester, HeartbeatPoller heartbeat,
    FakeCalibrationApi api) async {
  await tester.pumpWidget(const SizedBox());
  heartbeat.dispose();
  api.dispose();
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets(
      'selection then start then cancel uses saved command IDs and waits for events',
      (tester) async {
    final api = FakeCalibrationApi()..sending = Completer();
    api.data = {
      ...overview('completed'),
      'current': null,
      'latest_attempt': null,
      'recent_events': []
    };
    final heartbeat = await mount(tester, api, width: 320, allowSend: true);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('Start Calibration'), findsNothing);
    await tester.tap(find.text('E/F Drainage Calibration Mode').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Send command'));
    await tester.tap(find.text('Send command'));
    await tester.pump();
    expect(api.sentKeys, ['select-ef']);
    final selection = api.requestIds.last;
    await acknowledge(tester, api);
    expect(find.text('Start'), findsNothing);
    report(api, 'waiting_for_start', selection, selection);
    await refresh(tester);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    api.sending = Completer();
    await tester.ensureVisible(find.text('Start'));
    await tester.tap(find.text('Start'));
    await tester.pump();
    final start = api.requestIds.last;
    await acknowledge(tester, api);
    expect(find.text('Stop'), findsNothing);
    report(api, 'starting', selection, start);
    await refresh(tester);
    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('Start'), findsNothing);
    api.sending = Completer();
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    final cancel = api.requestIds.last;
    await acknowledge(tester, api);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    report(api, 'cancelled', selection, cancel, reason: 'user_cancelled');
    await refresh(tester);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(find.text('Send command'), findsOneWidget);
    expect(find.text('Start'), findsNothing);
    expect(find.text('20 s'), findsOneWidget);
    expect(api.sentKeys, ['select-ef', 'start', 'cancel']);
    expect(tester.takeException(), isNull);
    await unmount(tester, heartbeat, api);
  });
  testWidgets(
      'stop waits for not-saved outcome and preserves the previous measurement',
      (tester) async {
    final api = FakeCalibrationApi()..sending = Completer();
    final heartbeat = await mount(tester, api, allowSend: true);
    await tester.ensureVisible(find.text('Stop'));
    await tester.tap(find.text('Stop'));
    await tester.pump();
    expect(api.sentKeys, ['stop']);
    await acknowledge(tester, api);
    expect(find.text('Stopping…'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    report(api, 'not_saved', 'selection-command-uuid', api.requestIds.last,
        reason: 'duration_too_short');
    await refresh(tester);
    expect(find.text('Send command'), findsOneWidget);
    expect(find.text('Previous saved duration retained.'), findsOneWidget);
    expect(find.text('20 s'), findsOneWidget);
    await unmount(tester, heartbeat, api);
  });
  testWidgets('a rejected start restores start and cancel for retry',
      (tester) async {
    final api = FakeCalibrationApi()..sending = Completer();
    api.data = overview('waiting_for_start');
    final heartbeat = await mount(tester, api, allowSend: true);
    await tester.ensureVisible(find.text('Start'));
    await tester.tap(find.text('Start'));
    await tester.pump();
    await acknowledge(tester, api);
    report(api, 'rejected', 'selection-command-uuid', api.requestIds.last,
        reason: 'grid_power_unavailable', previous: 'waiting_for_start');
    await refresh(tester);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Stop'), findsNothing);
    expect(find.text('Latest command was rejected'), findsOneWidget);
    await unmount(tester, heartbeat, api);
  });
  for (final width in [320.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('calibration progress and saved data at $width dark=$dark',
          (tester) async {
        final api = FakeCalibrationApi();
        final heartbeat = await mount(tester, api, width: width, dark: dark);
        expect(find.text('Controller calibration'), findsOneWidget);
        expect(find.text('Controller online'), findsOneWidget);
        expect(find.text('Measuring'), findsWidgets);
        expect(find.text('Saved measurements'), findsOneWidget);
        expect(find.text('20 s'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await unmount(tester, heartbeat, api);
      });
    }
  }
  testWidgets('offline never assumes a running calibration completed',
      (tester) async {
    final api = FakeCalibrationApi();
    final heartbeat = await mount(tester, api, online: false);
    expect(find.text('Calibration status unknown'), findsOneWidget);
    expect(find.text('Controller offline'), findsOneWidget);
    expect(find.text('20 s'), findsOneWidget);
    expect(find.text('Completed'), findsNothing);
    await unmount(tester, heartbeat, api);
  });
  testWidgets(
      'a restarted online controller does not revive an old running session',
      (tester) async {
    final api = FakeCalibrationApi();
    final heartbeat = await mount(tester, api);
    heartbeat.acceptData(
        {...boardState, 'controller_session_id': 'new-boot-session'});
    await tester.pump();
    expect(find.text('Controller online'), findsOneWidget);
    expect(find.text('Calibration status unknown'), findsOneWidget);
    expect(find.textContaining('Controller restarted.'), findsOneWidget);
    await unmount(tester, heartbeat, api);
  });
  testWidgets('a successful command ACK does not complete the calibration',
      (tester) async {
    final api = FakeCalibrationApi()..sending = Completer();
    api.data = overview('waiting_for_start');
    final heartbeat = await mount(tester, api, allowSend: true);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    await tester.ensureVisible(find.text('Start'));
    await tester.tap(find.text('Start'));
    await tester.pump();
    api.sending!.complete({
      ...boardState,
      'last_command': {'status': 'confirmed'}
    });
    await tester.pumpAndSettle();
    expect(find.text('Ready to start'), findsWidgets);
    expect(find.text('Completed'), findsNothing);
    api.data = overview('running');
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('Measuring'), findsWidgets);
    await unmount(tester, heartbeat, api);
  });
  testWidgets('history loads older events and shows the full reason',
      (tester) async {
    final api = FakeCalibrationApi();
    final heartbeat = await mount(tester, api);
    await tester.ensureVisible(find.text('Load older events'));
    await tester.tap(find.text('Load older events'));
    await tester.pumpAndSettle();
    expect(find.text('Load older events'), findsNothing);
    await tester.ensureVisible(find.text('Cancelled'));
    await tester.tap(find.text('Cancelled'));
    await tester.pumpAndSettle();
    expect(find.text('Grid power was lost'), findsOneWidget);
    expect(find.textContaining('Calibration: selection-command-uuid'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmount(tester, heartbeat, api);
  });
  testWidgets(
      'command submission disables repeats and preserves the modal on failure',
      (tester) async {
    final api = FakeCalibrationApi()..sending = Completer();
    api.data = overview('waiting_for_start');
    final heartbeat = await mount(tester, api, allowSend: true);
    await tester.ensureVisible(find.text('Start'));
    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(find.text('Starting…'), findsOneWidget);
    expect(api.sends, 1);
    expect(find.text('Completed'), findsNothing);
    api.sending!.completeError(Exception('Pump safety lock'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Pump safety lock'), findsOneWidget);
    expect(find.text('Controller calibration'), findsOneWidget);
    expect(api.sends, 1);
    await unmount(tester, heartbeat, api);
  });
}
