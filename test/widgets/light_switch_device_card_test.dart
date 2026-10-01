import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/light_switch_device_card.dart';
import 'package:farmestates_ai_dashbaord/services/light_switch_service.dart';

class FakeRelay extends LightSwitchService {
  bool on = false, pending = false, online = true;
  int commands = 0;
  @override
  Future<Map<String, dynamic>> state(String serial) async {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'online': online,
      'reported_on': on,
      'pending': pending,
      'desired_on': true,
      'server_time': now,
      'seen_at': now
    };
  }

  @override
  Future<Map<String, dynamic>> command(
      String serial, bool desired, String id) async {
    expect(desired, true);
    commands++;
    pending = true;
    return state(serial);
  }
}

void main() {
  for (final dark in [false, true]) {
    for (final width in [280.0, 430.0]) {
      testWidgets('Relay confirmation and offline control at $width dark=$dark',
          (tester) async {
        GoogleFonts.config.allowRuntimeFetching = false;
        final service = FakeRelay();
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light),
            home: Scaffold(
                body: SingleChildScrollView(
                    child: SizedBox(
                        width: width,
                        child: LightSwitchDeviceCard(
                            serial: 'FARM-ESTATES-LIGHT-001',
                            name: 'Rack light controller',
                            farm: 'Farm Estates',
                            zone: 'Greenhouse A',
                            isDark: dark,
                            onSettings: () {},
                            service: service))))));
        await tester.pump();
        expect(tester.widget<Switch>(find.byType(Switch)).value, false);
        await tester.tap(find.byType(Switch));
        await tester.pump();
        expect(service.commands, 1);
        expect(tester.widget<Switch>(find.byType(Switch)).value, false);
        expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
        expect(find.textContaining('Turning on'), findsOneWidget);
        service.on = true;
        service.pending = false;
        await tester.pump(const Duration(seconds: 2));
        await tester.pump();
        expect(tester.widget<Switch>(find.byType(Switch)).value, true);
        service.online = false;
        await tester.pump(const Duration(seconds: 2));
        await tester.pump();
        expect(find.text('Offline'), findsOneWidget);
        expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 3));
        expect(tester.takeException(), isNull);
        service.dispose();
      });
    }
  }
}
