import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/services/light_switch_service.dart';
import 'package:farmestates_ai_dashbaord/widgets/cards/farm/first_row.dart';

class FakeLights extends LightSwitchService {
  int commands = 0;
  bool pending = false;
  bool confirmed = false;
  @override
  Future<Map<String, dynamic>> state(String serial) async => {
        'online': true,
        'reported_on': confirmed,
        'pending': pending,
        'desired_on': pending ? true : null,
        'server_time': DateTime.now().toUtc().toIso8601String(),
        'seen_at': DateTime.now().toUtc().toIso8601String(),
      };
  @override
  Future<Map<String, dynamic>> command(
      String serial, bool on, String requestId) async {
    commands++;
    expect(on, true);
    pending = true;
    return state(serial);
  }
}

class SleepingLights extends LightSwitchService {
  int calls = 0;
  final delayed = Completer<Map<String, dynamic>>();
  @override
  Future<Map<String, dynamic>> state(String serial) async {
    calls++;
    if (calls == 2) return delayed.future;
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'online': true,
      'reported_on': true,
      'pending': false,
      'seen_at': now,
      'server_time': now
    };
  }
}

void main() {
  testWidgets(
      'light dashboard resumes after sleep without adopting the suspended error',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final service = SleepingLights();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: SizedBox(
                    width: 360,
                    child: FirstRow(
                        isDark: false,
                        lightSwitchService: service,
                        devices: const [
                          {
                            'sensortype': 'light_switch',
                            'serial_number': 'LIGHT-001',
                            'location': 'Rack A'
                          }
                        ]))))));
    await tester.pump();
    await tester.ensureVisible(find.text('Rack A'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    expect(service.calls, 2);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 5));
    expect(service.calls, 2);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    service.delayed.completeError(Exception('Old socket failed during sleep'));
    await tester.pump();
    await tester.pump();
    expect(service.calls, 3);
    expect(find.text('ON'), findsOneWidget);
    expect(find.textContaining('Old socket'), findsNothing);
    expect(find.text('UNAVAILABLE'), findsNothing);
    expect(tester.takeException(), isNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(service.calls, 3);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });
  testWidgets('Tap waits for device confirmation and prevents repeat commands',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final service = FakeLights();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: SizedBox(
                    width: 360,
                    child: FirstRow(
                        isDark: false,
                        lightSwitchService: service,
                        devices: const [
                          {
                            'sensortype': 'light_switch',
                            'serial_number': 'LIGHT-001',
                            'location': 'Rack A'
                          }
                        ]))))));
    await tester.pump();
    await tester.ensureVisible(find.text('Rack A'));
    await tester.pumpAndSettle();
    expect(find.text('OFF'), findsOneWidget);
    await tester.tap(find.text('Rack A'));
    await tester.pump();
    expect(find.textContaining('TURNING ON'), findsOneWidget);
    await tester.tap(find.text('Rack A'));
    await tester.pump();
    expect(service.commands, 1);
    service.pending = false;
    service.confirmed = true;
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('ON'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
