import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/command_device_card.dart';
import 'package:farmestates_ai_dashbaord/services/command_device_service.dart';

const commands = [
  {'id': 'start', 'label': 'Start pump', 'value': 'PUMP_START'},
  {'id': 'stop', 'label': 'Stop pump', 'value': 'PUMP_STOP'}
];
final device = <String, dynamic>{
  'serial_number': 'FARM-ESTATES-COMMAND-DEVICE-001',
  'model_number': 'Irrigation control board',
  'farm_name': 'East farm',
  'location': 'Grow room',
  'command_config': jsonEncode(commands)
};

class FakeCommands extends CommandDeviceService {
  FakeCommands()
      : data = {
          'commands': commands,
          'online': true,
          'enabled': true,
          'ready': true,
          'can_send': true,
          'pending': false,
          'config_revision':
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          'server_time': DateTime.now().toUtc().toIso8601String(),
          'seen_at': DateTime.now().toUtc().toIso8601String()
        };
  Map<String, dynamic> data;
  Completer<Map<String, dynamic>>? sending;
  Object? readError;
  int sends = 0;
  @override
  Future<Map<String, dynamic>> state(String serial) async {
    if (readError != null) throw readError!;
    return data;
  }

  @override
  Future<Map<String, dynamic>> send(String serial, String key, String request,
      {String? revision}) {
    expect(key, 'start');
    expect(request.length, 36);
    expect(revision,
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');
    sends++;
    return sending!.future;
  }
}

class CalibrationCardApi extends FakeCommands {
  CalibrationCardApi() {
    data = {
      ...data,
      'controller_session_id': 'board-boot',
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
    };
  }
  Map<String, dynamic> calibration = {
    'current': null,
    'latest_attempt': null,
    'recent_events': [],
    'saved_durations': [],
    'next_cursor': null,
  };
  final keys = <String>[], requests = <String>[];
  @override
  Future<Map<String, dynamic>> state(String serial) async => {
        ...data,
        'seen_at': DateTime.now().toUtc().toIso8601String(),
      };
  @override
  Future<Map<String, dynamic>> calibrations(String serial) async => calibration;
  @override
  Future<Map<String, dynamic>> send(String serial, String key, String request,
      {String? revision}) async {
    keys.add(key);
    requests.add(request);
    data = {
      ...data,
      'last_command': {'id': request, 'status': 'confirmed'}
    };
    return state(serial);
  }

  void report(String status, String calibrationId) {
    final event = {
      'event_id': '$status-${requests.last}',
      'type': 'calibration.$status',
      'target': 'ef_drain',
      'calibration_id': calibrationId,
      'command_id': requests.last,
    };
    calibration = {
      ...calibration,
      'current': {
        'calibration_id': calibrationId,
        'session_id': 'board-boot',
        'target': 'ef_drain',
        'status': status,
        'event': event,
        'latest_event': event,
      },
    };
  }
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final width in [320.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets(
          'calibration workflow is visible directly on device card at $width dark=$dark',
          (tester) async {
        tester.view.physicalSize = Size(width, 1300);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = CalibrationCardApi();
        addTearDown(api.dispose);
        await tester.pumpWidget(MaterialApp(
          theme:
              ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
          home: Scaffold(
              body: SingleChildScrollView(
                  child: Align(
                      child: SizedBox(
            width: width < 600 ? width : 450,
            child: CommandDeviceCard(
                device: device, service: api, calibrationService: api),
          )))),
        ));
        await tester.pumpAndSettle();
        // This flow must work without opening Calibration & history.
        expect(find.text('Controller calibration'), findsNothing);
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        expect(find.text('Start Calibration'), findsNothing);
        await tester.tap(find.text('E/F Drainage Calibration Mode').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Send command'));
        await tester.pumpAndSettle();
        expect(api.keys, ['select-ef']);
        expect(find.text('Start'), findsOneWidget);
        expect(find.text('Selection confirmed'), findsOneWidget);
        final calibrationId = api.requests.first;
        Future<void> report(String status) async {
          api.report(status, calibrationId);
          await tester.tap(find.byTooltip('Refresh calibration'));
          await tester.pumpAndSettle();
        }

        await report('waiting_for_start');
        expect(find.text('Cancel'), findsOneWidget);
        await tester.tap(find.text('Start'));
        await tester.pumpAndSettle();
        expect(find.text('Stop'), findsOneWidget);
        await report('running');
        expect(find.text('Stop'), findsOneWidget);
        await tester.tap(find.text('Stop'));
        await tester.pumpAndSettle();
        expect(find.text('Stop confirmed. Waiting for the calibration result.'),
            findsOneWidget);
        await report('completed');
        expect(find.text('Select a calibration'), findsOneWidget);
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('P Rack Drainage Calibration Mode').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Send command'));
        await tester.pumpAndSettle();
        api.report('waiting_for_start', api.requests.last);
        await tester.tap(find.byTooltip('Refresh calibration'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Select a calibration'), findsOneWidget);
        api.report('cancelled', api.requests[3]);
        await tester.tap(find.byTooltip('Refresh calibration'));
        await tester.pumpAndSettle();
        expect(find.text('Select a calibration'), findsOneWidget);
        expect(api.keys, ['select-ef', 'start', 'stop', 'select-p', 'cancel']);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  for (final width in [320.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets(
          'command card has live pending and confirmed states at $width dark=$dark',
          (tester) async {
        tester.view.physicalSize = Size(width, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = FakeCommands();
        addTearDown(api.dispose);
        api.sending = Completer();
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light),
            home: Scaffold(
                body: SingleChildScrollView(
                    child: Align(
                        child: SizedBox(
                            width: width < 600 ? width : 450,
                            child: CommandDeviceCard(
                                device: device, service: api)))))));
        await tester.pumpAndSettle();
        expect(find.text('Online'), findsOneWidget);
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Start pump').last);
        await tester.pumpAndSettle();
        expect(find.text('PUMP_START'), findsOneWidget);
        await tester.tap(find.text('Send command'));
        await tester.pump();
        expect(find.text('Sending…'), findsOneWidget);
        expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
            isNull);
        api.data = {
          ...api.data,
          'ready': false,
          'pending': true,
          'last_command': {
            'id': 'request',
            'label': 'Start pump',
            'status': 'pending',
            'created_at': DateTime.now().toUtc().toIso8601String()
          }
        };
        api.sending!.complete(api.data);
        await tester.pumpAndSettle();
        expect(find.text('Awaiting confirmation'), findsOneWidget);
        expect(find.text('Confirmed'), findsNothing);
        expect(api.sends, 1);
        api.data = {
          ...api.data,
          'pending': false,
          'ready': true,
          'last_command': {
            'label': 'Start pump',
            'status': 'confirmed',
            'result': 'Pump started'
          }
        };
        await tester.tap(find.byTooltip('Refresh commands'));
        await tester.pumpAndSettle();
        expect(find.text('Confirmed'), findsOneWidget);
        expect(find.text('Pump started'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  testWidgets('offline and view-only devices cannot send commands',
      (tester) async {
    final api = FakeCommands();
    addTearDown(api.dispose);
    api.data = {
      ...api.data,
      'online': false,
      'seen_at': DateTime.now()
          .subtract(const Duration(seconds: 16))
          .toUtc()
          .toIso8601String()
    };
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: CommandDeviceCard(
                    device: device, service: api, allowSend: false)))));
    await tester.pumpAndSettle();
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('View-only access'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('a rejected command remains visible after background refresh',
      (tester) async {
    final api = FakeCommands();
    addTearDown(api.dispose);
    api.sending = Completer();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: CommandDeviceCard(device: device, service: api)))));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start pump').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send command'));
    await tester.pump();
    api.sending!.completeError(Exception('Device has a pending command'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Device has a pending command'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.textContaining('Device has a pending command'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'a transient failure preserves online until grace expires and polling recovers',
      (tester) async {
    final api = FakeCommands();
    addTearDown(api.dispose);
    final now = DateTime.now().toUtc();
    api.data = {
      ...api.data,
      'offline_after_ms': 5500,
      'server_time': now.toIso8601String(),
      'seen_at': now.toIso8601String()
    };
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: CommandDeviceCard(device: device, service: api)))));
    await tester.pumpAndSettle();
    expect(find.text('Online'), findsOneWidget);
    api.readError = Exception('Temporary connection failure');
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Unavailable'), findsNothing);
    await tester.pump(const Duration(seconds: 11));
    expect(find.text('Reconnecting'), findsOneWidget);
    expect(find.text('Offline'), findsNothing);
    api.readError = null;
    api.data = {
      ...api.data,
      'seen_at': now.add(const Duration(seconds: 6)).toIso8601String()
    };
    await tester.tap(find.byTooltip('Refresh commands'));
    await tester.pump();
    expect(find.text('Online'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
