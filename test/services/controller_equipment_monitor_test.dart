import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/services/controller_equipment_monitor.dart';
import 'package:farmestates_ai_dashbaord/services/command_device_service.dart';

const equipment = [
  {
    r'$id': 'light',
    'sensortype': 'grow_light',
    'controller_id': 'board',
    'controller_output': 'lights.E'
  },
  {
    r'$id': 'pump',
    'sensortype': 'feeding_pump',
    'controller_id': 'board',
    'controller_output': 'fertigation.pump_on'
  },
];
Map<String, dynamic> state(String id, bool on) => {
      'device_id': id,
      'reported_on': on,
      'online': true,
      'server_time': '2026-10-22T12:00:00Z',
      'seen_at': '2026-10-22T12:00:00Z',
      'received_at': '2026-10-22T12:00:00Z'
    };

void main() {
  testWidgets('batched adaptive polling does not stack and stops in background',
      (tester) async {
    var calls = 0;
    Uri? receivedUri;
    final response = Completer<http.Response>();
    final service = CommandDeviceService(
        token: () => 'jwt',
        client: MockClient((request) {
          calls++;
          receivedUri = request.url;
          return response.future;
        }));
    final monitor = ControllerEquipmentMonitor(service: service);
    monitor.setDevices(equipment);
    await tester.pump(const Duration(seconds: 5));
    expect(calls, 1, reason: monitor.error);
    expect(receivedUri!.path, '/controller-equipment');
    expect(receivedUri!.queryParametersAll['device_id'], ['light', 'pump']);
    response.complete(http.Response(
        jsonEncode({
          'equipment': [state('light', true), state('pump', false)]
        }),
        200));
    await tester.pump();
    expect(monitor.label('light'), 'ON');
    expect(monitor.label('pump'), 'OFF');
    monitor.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 3));
    expect(calls, 1);
    expect(monitor.online('light'), false);
    monitor.dispose();
  });

  testWidgets(
      'HTTP failures preserve reports through grace then show unavailable, never false OFF',
      (tester) async {
    var calls = 0, elapsed = 0;
    final monitor = ControllerEquipmentMonitor(
        elapsedMilliseconds: () => elapsed,
        service: CommandDeviceService(
            token: () => 'jwt',
            client: MockClient((request) async {
              if (++calls > 1) throw Exception('Temporary network delay');
              return http.Response(
                  jsonEncode({
                    'equipment': [state('light', true), state('pump', false)]
                  }),
                  200);
            })));
    monitor.setDevices(equipment);
    await tester.pump();
    elapsed = 2000;
    await tester.pump(const Duration(seconds: 2));
    expect(monitor.label('light'), 'ON');
    elapsed = 5501;
    await tester.pump(const Duration(seconds: 1));
    expect(monitor.label('light'), 'Status unavailable');
    expect(monitor.states['light']!['reported_on'], true);
    monitor.dispose();
  });

  testWidgets('old reports and changed output links cannot appear current',
      (tester) async {
    var elapsed = 0;
    final monitor = ControllerEquipmentMonitor(
        elapsedMilliseconds: () => elapsed,
        service: CommandDeviceService(
            token: () => 'jwt',
            client: MockClient((request) async => http.Response(
                jsonEncode({
                  'equipment': [
                    {
                      ...state('light', true),
                      'received_at': '2026-10-22T11:58:00Z'
                    }
                  ]
                }),
                200))));
    monitor.setDevices(equipment);
    await tester.pump();
    expect(monitor.online('light'), true);
    expect(monitor.label('light'), 'Awaiting report');
    monitor.didChangeAppLifecycleState(AppLifecycleState.paused);
    monitor.setDevices([
      {...equipment.first, 'controller_output': 'lights.P'}
    ]);
    expect(monitor.states, isEmpty);
    monitor.dispose();
  });
}
