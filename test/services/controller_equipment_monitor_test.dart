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
  testWidgets(
      'equipment wakes without applying an interrupted request error or stacking requests',
      (tester) async {
    var calls = 0;
    final interrupted = Completer<http.Response>();
    final monitor = ControllerEquipmentMonitor(
        service: CommandDeviceService(
            token: () => 'jwt',
            client: MockClient((request) async {
              calls++;
              if (calls == 2) return interrupted.future;
              return http.Response(
                  jsonEncode({
                    'equipment': [
                      {
                        ...state('light', true),
                        'seen_at': calls == 1
                            ? '2026-10-22T12:00:00Z'
                            : '2026-10-22T12:00:03Z'
                      }
                    ]
                  }),
                  200);
            })));
    monitor.setDevices(equipment);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(calls, 2);
    monitor.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 5));
    expect(calls, 2);
    monitor.didChangeAppLifecycleState(AppLifecycleState.resumed);
    interrupted.completeError(Exception('Interrupted by phone sleep'));
    await tester.pump();
    await tester.pump();
    expect(calls, 3);
    expect(monitor.online('light'), true);
    expect(monitor.error, isNull);
    expect(tester.takeException(), isNull);
    monitor.dispose();
  });
  testWidgets(
      'aged but advancing heartbeat receives full grace, without false offline flicker',
      (tester) async {
    var elapsed = 0, calls = 0;
    final monitor = ControllerEquipmentMonitor(
        elapsedMilliseconds: () => elapsed,
        presenceOnly: true,
        service: CommandDeviceService(
            token: () => 'jwt',
            client: MockClient((request) async {
              calls++;
              return http.Response(
                  jsonEncode({
                    'equipment': [
                      {
                        ...state('light', true),
                        'controller_id': 'board',
                        'seen_at': '2026-10-22T11:59:55Z'
                      }
                    ]
                  }),
                  200);
            })));
    monitor.setDevices(equipment);
    await tester.pump();
    elapsed = 2000;
    await tester.pump(const Duration(seconds: 2));
    expect(monitor.online('light'), true);
    elapsed = 4000;
    await tester.pump(const Duration(seconds: 2));
    expect(monitor.online('light'), true);
    elapsed = 5500;
    await tester.pump(const Duration(milliseconds: 1500));
    expect(monitor.online('light'), false);
    expect(calls, 3);
    monitor.dispose();
  });

  testWidgets(
      'one stale server response does not clear a healthy receipt and recovery is continuous',
      (tester) async {
    var elapsed = 0, calls = 0;
    final monitor = ControllerEquipmentMonitor(
        elapsedMilliseconds: () => elapsed,
        service: CommandDeviceService(
            token: () => 'jwt',
            client: MockClient((request) async {
              calls++;
              return http.Response(
                  jsonEncode({
                    'equipment': [
                      {
                        ...state('light', true),
                        'controller_id': 'board',
                        'online': calls != 2,
                        'seen_at':
                            '2026-10-22T12:00:0${calls == 1 ? 0 : calls == 2 ? 0 : 4}Z'
                      }
                    ]
                  }),
                  200);
            })));
    monitor.setDevices(equipment);
    await tester.pump();
    elapsed = 2000;
    await tester.pump(const Duration(seconds: 2));
    expect(monitor.online('light'), true);
    elapsed = 4000;
    await tester.pump(const Duration(seconds: 2));
    expect(monitor.online('light'), true);
    elapsed = 6000;
    expect(monitor.online('light'), true);
    monitor.dispose();
  });

  testWidgets(
      'adding another device retains existing light status while refreshing',
      (tester) async {
    var calls = 0;
    final delayed = Completer<http.Response>();
    final monitor = ControllerEquipmentMonitor(
        service: CommandDeviceService(
            token: () => 'jwt',
            client: MockClient((request) async {
              calls++;
              return calls == 1
                  ? http.Response(
                      jsonEncode({
                        'equipment': [state('light', true)]
                      }),
                      200)
                  : delayed.future;
            })));
    monitor.setDevices([equipment.first]);
    await tester.pump();
    expect(monitor.online('light'), true);
    monitor.setDevices(equipment);
    await tester.pump();
    expect(monitor.online('light'), true);
    delayed.complete(http.Response(
        jsonEncode({
          'equipment': [state('light', true), state('pump', false)]
        }),
        200));
    await tester.pump();
    monitor.dispose();
  });

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
