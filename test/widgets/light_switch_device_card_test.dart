import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/light_switch_device_card.dart';
import 'package:farmestates_ai_dashbaord/services/light_switch_service.dart';

class FakeRelay extends LightSwitchService {
  bool on = false, pending = false, online = true;
  bool reject = false;
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
    if (reject) throw Exception('Controller busy');
    pending = true;
    return state(serial);
  }
}

void main() {
  testWidgets(
      'a rejected switch action stays visible without marking the light offline',
      (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final service = FakeRelay()..reject = true;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: LightSwitchDeviceCard(
                    serial: 'LIGHT-001',
                    name: 'Rack light',
                    farm: 'Farm',
                    zone: 'Rack A',
                    isDark: false,
                    onSettings: () {},
                    service: service)))));
    await tester.pump();
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(find.text('Controller busy'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Unavailable'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });
  for (final dark in [false, true]) {
    for (final width in [280.0, 430.0]) {
      testWidgets('Relay confirmation and offline control at $width dark=$dark',
          (tester) async {
        GoogleFonts.config.allowRuntimeFetching = false;
        final service = FakeRelay();
        var elapsed = 0;
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
                            elapsedMilliseconds: () => elapsed,
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
        elapsed = 2000;
        await tester.pump(const Duration(seconds: 2));
        await tester.pump();
        expect(tester.widget<Switch>(find.byType(Switch)).value, true);
        service.online = false;
        elapsed = 4000;
        await tester.pump(const Duration(seconds: 2));
        await tester.pump();
        expect(find.text('On'), findsOneWidget);
        elapsed = 17501;
        await tester.pump(const Duration(seconds: 15));
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
