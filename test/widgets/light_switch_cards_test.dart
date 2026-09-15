import 'package:flutter/material.dart';
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

void main() {
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
