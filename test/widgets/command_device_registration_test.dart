import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/services/device_maintenance_api.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/device_registration_form.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/named_command_fields.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/maintenance_form_shell.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/command_device_setup_guide.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  final command = <String, dynamic>{
    r'$id': 'device',
    'farmID': 'farm',
    'model_number': 'Pump controller',
    'location': 'Grow room',
    'serial_number': 'CMD-001',
    'sensortype': 'command_device',
    'status': 'Active',
    'command_config': jsonEncode([
      {'id': 'start', 'label': 'Start pump', 'value': 'PUMP_START'}
    ])
  };
  for (final width in [320.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets(
          'named commands save atomically and preserve errors at $width dark=$dark',
          (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Map<String, dynamic>? saved;
        final api = DeviceMaintenanceApi(client: MockClient((request) async {
          if (request.method == 'GET') {
            return http.Response(
                jsonEncode({
                  'can_configure_commands': true,
                  'farms': [
                    {r'$id': 'farm', 'name': 'East farm'}
                  ]
                }),
                200);
          }
          saved = jsonDecode(request.body);
          return http.Response('{"detail":"Please try again later"}', 503);
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
                            DeviceRegistrationForm(device: command, api: api)),
                        child: const Text('Open'))))));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Update command device'), findsOneWidget);
        expect(find.byType(NamedCommandFields), findsOneWidget);
        expect(find.text('Maintenance tasks'), findsNothing);
        expect(find.text('Reading alerts'), findsNothing);
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(saved?['sensortype'], 'command_device');
        expect(jsonDecode(saved!['command_config']), [
          {'id': 'start', 'label': 'Start pump', 'value': 'PUMP_START'}
        ]);
        expect(saved!['value'], 0);
        expect(saved!['unit'], 'command');
        expect(saved!['plans'], isEmpty);
        await tester.ensureVisible(find.text('Please try again later'));
        expect(find.text('Please try again later'), findsOneWidget);
        expect(
            find.byWidgetPredicate((widget) =>
                widget is EditableText &&
                widget.controller.text == 'PUMP_START'),
            findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
  testWidgets('technicians do not get the command registration option',
      (tester) async {
    final api = DeviceMaintenanceApi(
        client: MockClient((_) async => http.Response(
            jsonEncode({
              'can_configure_commands': false,
              'farms': [
                {r'$id': 'farm', 'name': 'East'}
              ]
            }),
            200)));
    addTearDown(api.dispose);
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: DeviceRegistrationForm(api: api))));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    expect(find.text('Command Device'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'commands can be added, validated and removed without disposing a closing field',
      (tester) async {
    List<Map<String, String>>? values;
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: Form(
                    key: form,
                    child: NamedCommandFields(
                        initial: const [],
                        onChanged: (value) => values = value))))));
    expect(form.currentState!.validate(), false);
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(0), 'Start pump');
    await tester.enterText(find.byType(TextFormField).at(1), 'PUMP_START');
    await tester.tap(find.text('Add command'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(2), 'Start pump');
    await tester.enterText(find.byType(TextFormField).at(3), 'PUMP_STOP');
    expect(form.currentState!.validate(), false);
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(2), 'Stop pump');
    expect(form.currentState!.validate(), true);
    expect(values, hasLength(2));
    await tester.ensureVisible(find.byTooltip('Remove command').last);
    await tester.tap(find.byTooltip('Remove command').last);
    await tester.pump();
    expect(values, hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  for (final width in [320.0, 1440.0]) {
    testWidgets('setup guide stays bounded at $width', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(
              platform: width < 600
                  ? TargetPlatform.android
                  : TargetPlatform.windows),
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () =>
                          showCommandDeviceSetupGuide(context, 'F-001'),
                      child: const Text('Open'))))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Command device setup'), findsOneWidget);
      expect(find.text('Copy guide'), findsOneWidget);
      expect(commandDeviceSetupText('F-001'),
          contains('/command-devices/F-001/poll'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
