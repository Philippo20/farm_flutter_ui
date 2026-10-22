import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/controller_activity_modal.dart';
import 'package:farmestates_ai_dashbaord/services/command_device_service.dart';

Map<String, dynamic> report(String id) => {
      'event_id': id,
      'session_id': 'board-12345678-12345678',
      'generation': 42,
      'type': 'fertigation.paused',
      'target': 'fertigation',
      'reason': 'grid_power_lost',
      'message':
          'Fertigation paused because grid power is unavailable. The controller will resume safely.',
      'received_at': DateTime.now().toUtc().toIso8601String(),
      'lights': {
        'pair': 'OFF',
        'E': false,
        'F': false,
        'P': false,
        'changing': true
      },
      'fertigation': {
        'enabled': {'E': true, 'F': false, 'P': true},
        'state': 'paused_grid',
        'pump_on': false,
        'rack': 'P',
        'source': 'scheduled',
        'configured_duration_ms': 120000
      },
      'drainage': {
        'ef': {'pump_on': false, 'tank_full': true},
        'p': {'pump_on': false, 'tank_full': false}
      },
      'grid_available': false,
      'rtc_available': true,
    };

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  testWidgets('queued recovery is separate from actual pump output',
      (tester) async {
    final snapshot = report('boot-43');
    snapshot['type'] = 'fertigation.recovery_queued';
    snapshot['fertigation'] = <String, dynamic>{
      ...Map<String, dynamic>.from(snapshot['fertigation'] as Map),
      'source': 'manual',
      'manual_requested': true,
      'active': false,
      'pump_on': false,
      'state': 'idle',
    };
    final api = CommandDeviceService(
        token: () => 'jwt',
        client: MockClient((_) async => http.Response(
            jsonEncode({
              'online': true,
              'seen_at': DateTime.now().toUtc().toIso8601String(),
              'snapshot': snapshot
            }),
            200)));
    addTearDown(api.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ControllerActivityModal(serial: 'CMD-001', service: api))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Manual recovery'));
    expect(find.text('Queued · Waiting for safe start'), findsOneWidget);
    expect(find.text('Running'), findsNothing);
    expect(find.text('OFF'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  for (final width in [320.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets(
          'controller status and full paged history at $width dark=$dark',
          (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var historyCalls = 0;
        final api = CommandDeviceService(
            token: () => 'jwt',
            client: MockClient((request) async {
              if (request.url.path.endsWith('/events')) {
                historyCalls++;
                return http.Response(
                    jsonEncode({
                      'events': [
                        report(historyCalls == 1 ? 'boot-42' : 'boot-40')
                      ],
                      'next_cursor': historyCalls == 1 ? 'cursor' : null
                    }),
                    200);
              }
              return http.Response(
                  jsonEncode({
                    'online': true,
                    'seen_at': DateTime.now().toUtc().toIso8601String(),
                    'snapshot': report('boot-42')
                  }),
                  200);
            }));
        addTearDown(api.dispose);
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light),
            home: Scaffold(
                body: Center(
                    child: ControllerActivityModal(
                        serial: 'FARM-ESTATES-CONTROLLER-001',
                        service: api)))));
        await tester.pumpAndSettle();
        expect(find.text('Controller online'), findsOneWidget);
        expect(find.text('Reported outputs'), findsOneWidget);
        await tester.ensureVisible(find.text('Stage'));
        expect(find.text('paused grid'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('History'));
        await tester.tap(find.text('History'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('fertigation.paused'));
        await tester.pumpAndSettle();
        expect(find.text('grid power lost'), findsOneWidget);
        expect(
            find.textContaining('Fertigation paused because'), findsOneWidget);
        await tester.ensureVisible(find.text('Load earlier reports'));
        await tester.tap(find.text('Load earlier reports'));
        await tester.pumpAndSettle();
        expect(historyCalls, 2);
        expect(find.text('fertigation.paused'), findsNWidgets(2));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
