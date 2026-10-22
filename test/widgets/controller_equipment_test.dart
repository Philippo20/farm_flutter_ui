import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/device_registration_form.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/maintenance_form_shell.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/controller_equipment_status.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/named_command_fields.dart';
import 'package:farmestates_ai_dashbaord/services/device_maintenance_api.dart';
import 'package:farmestates_ai_dashbaord/services/controller_equipment_monitor.dart';
import 'package:farmestates_ai_dashbaord/services/command_device_service.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  final device = {
    r'$id': 'light',
    'sensortype': 'grow_light',
    'farmID': 'farm',
    'controller_id': 'board',
    'controller_output': 'lights.F',
    'model_number': 'Rack F grow light',
    'serial_number': 'LIGHT-002',
    'location': 'Grow room',
    'maintenance_plan': '[]',
    'status': 'Active'
  };
  for (final width in [320.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('linked equipment registration at $width dark=$dark',
          (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Map<String, dynamic>? saved;
        final api = DeviceMaintenanceApi(client: MockClient((request) async {
          if (request.method == 'GET')
            return http.Response(
                jsonEncode({
                  'farms': [
                    {r'$id': 'farm', 'name': 'East farm'}
                  ],
                  'devices': [
                    {
                      r'$id': 'board',
                      'sensortype': 'command_device',
                      'farmID': 'farm',
                      'model_number': 'Controller',
                      'serial_number': 'CMD-001'
                    },
                    {
                      r'$id': 'foreign',
                      'sensortype': 'command_device',
                      'farmID': 'other',
                      'model_number': 'Foreign',
                      'serial_number': 'CMD-002'
                    },
                    {
                      r'$id': 'occupied',
                      'controller_id': 'board',
                      'controller_output': 'lights.E'
                    },
                    device
                  ]
                }),
                200);
          saved = jsonDecode(request.body);
          return http.Response('{"detail":"Try again later"}', 503);
        }));
        addTearDown(api.dispose);
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light,
                platform: width < 600
                    ? TargetPlatform.android
                    : TargetPlatform.windows),
            home: Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () => showMaintenanceRoute(context,
                            DeviceRegistrationForm(device: device, api: api)),
                        child: const Text('Open'))))));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('ESP32 controller'), findsOneWidget);
        expect(find.text('Reading alerts'), findsNothing);
        final dropdowns = tester
            .widgetList<DropdownButton<String>>(
                find.byType(DropdownButton<String>))
            .toList();
        expect(dropdowns[2].items!.map((e) => e.value), ['board']);
        expect(
            dropdowns[3].items!.map((e) => e.value), ['lights.F', 'lights.P']);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(saved?['controller_id'], 'board');
        expect(saved?['controller_output'], 'lights.F');
        expect(saved?['value'], 0);
        expect(saved?['alerts_enabled'], false);
        expect(saved?['plans'], isEmpty);
        await tester.ensureVisible(find.text('Try again later'));
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('reported state tile has no overflow at $width dark=$dark',
          (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var online = false;
        final now = DateTime.now().toUtc().toIso8601String();
        final monitor = ControllerEquipmentMonitor(
            service: CommandDeviceService(
                token: () => 'jwt',
                client: MockClient((_) async => http.Response(
                    jsonEncode({
                      'equipment': [
                        {
                          'device_id': 'light',
                          'controller_id': 'board',
                          'reported_on': true,
                          'online': online,
                          'seen_at': now,
                          'server_time': now,
                          'received_at': now,
                          'maintenance_status': 'Overdue',
                          'next_due': '2026-10-01'
                        }
                      ]
                    }),
                    200))));
        monitor.setDevices([device]);
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light),
            home: Scaffold(
                body: SingleChildScrollView(
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                            width: width < 600 ? 140 : 300,
                            child: ControllerEquipmentStatus(
                                device: device,
                                monitor: monitor,
                                compact: true)))))));
        await tester.pump();
        expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
        expect(find.text('Rack F grow light'), findsOneWidget);
        expect(find.text('OFFLINE'), findsOneWidget);
        expect(find.byType(Text), findsNWidgets(2));
        expect(find.textContaining('Serial:'), findsNothing);
        expect(find.textContaining('Last reported:'), findsNothing);
        expect(find.textContaining('Received '), findsNothing);
        expect(find.text('Overdue'), findsNothing);
        online = true;
        monitor.didChangeAppLifecycleState(AppLifecycleState.paused);
        monitor.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await tester.pump();
        expect(find.text('ONLINE'), findsOneWidget);
        expect(find.byType(Text), findsNWidgets(2));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        monitor.dispose();
      });
    }
  }
  testWidgets('V1.7 presets preserve existing IDs and aliases', (tester) async {
    List<Map<String, String>> commands = [];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: NamedCommandFields(initial: const [
      {'id': 'existing', 'label': 'Rack E enabled', 'value': 'E-ON'},
      {'id': 'calibration', 'label': 'Start calibration', 'value': 'CAL_START'},
    ], onChanged: (v) => commands = v)))));
    await tester.tap(find.text('Add V1.7 rack commands'));
    await tester.pump();
    expect(commands.length, 10);
    expect(commands.first['id'], 'existing');
    expect(commands[1]['id'], 'calibration');
    expect(commands.where((c) => c['value'] == 'E_ON'), isEmpty);
    expect(commands.any((c) => c['value'] == 'FERT_STATUS'), true);
    await tester.pumpWidget(const SizedBox());
  });
}
