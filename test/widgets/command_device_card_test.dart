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
  int sends = 0;
  @override
  Future<Map<String, dynamic>> state(String serial) async => data;
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

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
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
      'five-second polling timeout goes offline and recovers in background',
      (tester) async {
    final api = FakeCommands();
    addTearDown(api.dispose);
    final now = DateTime.now().toUtc();
    api.data = {
      ...api.data,
      'offline_after_ms': 5000,
      'server_time': now.toIso8601String(),
      'seen_at': now.subtract(const Duration(seconds: 4)).toIso8601String()
    };
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: CommandDeviceCard(device: device, service: api)))));
    await tester.pumpAndSettle();
    expect(find.text('Online'), findsOneWidget);
    api.data = {
      ...api.data,
      'seen_at':
          now.subtract(const Duration(milliseconds: 5001)).toIso8601String()
    };
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('Offline'), findsOneWidget);
    api.data = {...api.data, 'seen_at': now.toIso8601String()};
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('Online'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
