import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/services/device_maintenance_api.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/device_registration_form.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/device_maintenance_panel.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/maintenance_form_shell.dart';

void main() {
  final task = <String, dynamic>{
    'device_id': 'device',
    'plan_id': 'cal',
    'type': 'calibration',
    'device_name': 'Long name nutrient solution pH measurement equipment',
    'serial_number': 'FARM-001',
    'farm_name': 'North greenhouse with a long name',
    'due_date': '2026-01-01',
    'interval_days': 30,
    'status': 'Overdue',
    'instructions': 'Use the reference solutions supplied by the manufacturer.'
  };
  final device = <String, dynamic>{
    r'$id': 'device',
    'farmID': 'farm',
    'sensortype': 'pH Level',
    'model_number': 'pH device',
    'location': 'Tank',
    'unit': 'pH',
    'status': 'Active',
    'serial_number': 'F-001',
    'value': 7,
    'maintenance_plan': jsonEncode([
      {
        'id': 'cal',
        'type': 'calibration',
        'first_due': '2026-01-01',
        'interval_days': 30
      }
    ])
  };
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final width in [320.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('Device schedules at $width dark=$dark', (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = DeviceMaintenanceApi(
            client: MockClient((_) async => http.Response(
                jsonEncode({
                  'tasks': [task],
                  'history': [],
                  'devices': [device],
                  'farms': [
                    {r'$id': 'farm', 'name': 'North greenhouse'}
                  ]
                }),
                200)));
        addTearDown(api.dispose);
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light),
            home: Scaffold(body: DeviceMaintenancePanel(api: api))));
        await tester.pumpAndSettle();
        expect(find.text('Device maintenance'), findsOneWidget);
        if (width < 600) {
          await tester.drag(find.byType(ListView), const Offset(0, -700));
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(find.text('Record completion'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Record completion'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Complete'));
        await tester.pumpAndSettle();
        expect(find.text('Please record Work performed'), findsOneWidget);
        expect(find.text('Please record Calibration results'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('Registration fields and save error at $width dark=$dark',
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
                    {r'$id': 'farm', 'name': 'North greenhouse'}
                  ]
                }),
                200);
          saved = jsonDecode(request.body);
          return http.Response('{"detail":"Unable to save right now"}', 503);
        }));
        addTearDown(api.dispose);
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light),
            home: Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () => showMaintenanceRoute(context,
                            DeviceRegistrationForm(device: device, api: api)),
                        child: const Text('Open'))))));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(saved!['plans'], hasLength(1));
        expect(saved!['plans'][0]['type'], 'calibration');
        expect(find.text('Update device'), findsOneWidget);
        await tester.ensureVisible(find.text('Unable to save right now'));
        expect(find.text('Unable to save right now'), findsOneWidget);
        expect(find.text('pH device'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  testWidgets(
      'Mobile keyboard keeps actions visible and legacy schedule needs review',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    var writes = 0;
    final legacy = {...device, 'maintenance_frequency': 'Monthly'}
      ..remove('maintenance_plan');
    final api = DeviceMaintenanceApi(client: MockClient((request) async {
      if (request.method == 'GET')
        return http.Response(
            jsonEncode({
              'farms': [
                {r'$id': 'farm', 'name': 'Farm'}
              ]
            }),
            200);
      writes++;
      return http.Response('{"detail":"Please retry"}', 503);
    }));
    addTearDown(api.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => showMaintenanceRoute(context,
                        DeviceRegistrationForm(device: legacy, api: api)),
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(tester.getBottomRight(find.text('Save')).dy, lessThan(700));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(writes, 0);
    expect(find.textContaining('Review the previous maintenance schedule:'),
        findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('No scheduled maintenance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No scheduled maintenance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(writes, 1);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });
}
