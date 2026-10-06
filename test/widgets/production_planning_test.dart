import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/core/utils/production_plan.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/plant_type_form.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/production_schedule_card.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/maintenance_form_shell.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/batch_creation_dialog.dart';
import 'package:farmestates_ai_dashbaord/services/superadmin_api_service.dart';

void main() {
  final plan = {
    'stages': [
      {'name': 'Sprouting', 'days': 7},
      {'name': 'Leaf Development', 'days': 28},
      {'name': 'Harvest', 'days': 7},
    ],
    'interval_days': 14,
    'reminder_days': 2,
  };
  final plant = {
    'id': 'p',
    'name': 'Lettuce',
    'category': 'Greens',
    'maturityMin': 42,
    'maturityMax': 42,
    'maturityUnit': 'days',
    'status': 'Active',
    'production_plan': jsonEncode(plan)
  };
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Staggered production saves independently of custom stages',
      (tester) async {
    Map<String, String>? payload;
    final client = MockClient((request) async {
      payload = request.bodyFields;
      return http.Response('{"detail":"Test save error"}', 422);
    });
    addTearDown(client.close);
    final standalone = {
      'stages': [],
      'interval_days': 14,
      'reminder_days': 2,
      'maturity_value': 6,
      'maturity_unit': 'weeks'
    };
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PlantTypeForm(
                api: SuperAdminApiService(client: client),
                categories: const [
          'Greens'
        ],
                plant: {
          ...plant,
          'maturityMin': 4,
          'maturityMax': 6,
          'maturityUnit': 'weeks',
          'production_plan': jsonEncode(standalone)
        }))));
    final toggles =
        tester.widgetList<SwitchListTile>(find.byType(SwitchListTile)).toList();
    expect(toggles.first.value, isFalse);
    expect(toggles.last.value, isTrue);
    expect(find.text('Stage name'), findsNothing);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final sent = jsonDecode(payload!['production_plan']!);
    expect(sent['stages'], isEmpty);
    expect(sent['interval_days'], 14);
    expect(sent['maturity_value'], 6);
    expect(payload!['maturity_min_value'], '4');
    expect(payload!['maturity_unit'], 'weeks');
    expect(
        productionHarvest(sent, DateTime(2026, 10, 5)), DateTime(2026, 11, 16));
    expect(
        productionHarvest(
            {...sent, 'maturity_value': 1, 'maturity_unit': 'months'},
            DateTime(2028, 1, 31)),
        DateTime(2028, 2, 29));
    expect(tester.takeException(), isNull);
  });

  test('Calendar schedule preserves stage order and crosses year boundaries',
      () {
    final dates = productionSchedule(plan, DateTime(2026, 12, 25));
    expect(productionDays(plan), 42);
    expect(dates[1]['start'], DateTime(2027, 1, 1));
    expect(dates.last['end'], DateTime(2027, 2, 5));
    expect(productionStages(null), isEmpty);
  });

  for (final width in [320.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('Growth modal and keyboard at $width dark=$dark',
          (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final client = MockClient((_) async => http.Response('{}', 200));
        addTearDown(client.close);
        final api = SuperAdminApiService(client: client);
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light,
                platform: width < 600
                    ? TargetPlatform.android
                    : TargetPlatform.windows),
            home: Scaffold(
                body: Builder(
                    builder: (context) => TextButton(
                        onPressed: () => showMaintenanceRoute(
                            context,
                            PlantTypeForm(
                                api: api,
                                categories: const ['Greens'],
                                plant: plant)),
                        child: const Text('Open'))))));
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Edit plant type'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (width < 600) {
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          addTearDown(tester.view.resetViewInsets);
          await tester.pumpAndSettle();
          expect(tester.getBottomLeft(find.text('Save')).dy, lessThan(600));
        }
        await tester.drag(
            find.byType(SingleChildScrollView), const Offset(0, -1300));
        await tester.pumpAndSettle();
        expect(find.text('Start a new batch every (days)'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Open'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
      'Save uses ordered plan, disables repeats and preserves values on failure',
      (tester) async {
    final completer = Completer<http.Response>();
    Map<String, String>? payload;
    var calls = 0;
    final client = MockClient((request) {
      calls++;
      payload = request.bodyFields;
      return completer.future;
    });
    addTearDown(client.close);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PlantTypeForm(
                api: SuperAdminApiService(client: client),
                categories: const ['Greens'],
                plant: plant))));
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Saving...'), findsOneWidget);
    await tester.tap(find.text('Saving...'));
    expect(calls, 1);
    expect(jsonDecode(payload!['production_plan']!)['interval_days'], 14);
    expect(payload!['maturity_max_value'], '42');
    completer.complete(http.Response('{"detail":"Unable to save plan"}', 422));
    await tester.pumpAndSettle();
    expect(find.textContaining('Unable to save plan'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Lettuce'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Schedule shows next batch and previous cadence at narrow width',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: SizedBox(
                    width: 280,
                    child: ProductionScheduleCard(
                        plan: plan,
                        start: DateTime(2026, 10, 19),
                        previousBatch: {
                          'batch_no': 'B001',
                          'start_date': '2026-10-05',
                          'production_plan': jsonEncode(plan),
                        }))))));
    expect(find.textContaining('2 Nov 2026'), findsWidgets);
    expect(find.textContaining('30 Nov 2026'), findsWidgets);
    expect(find.textContaining('This start follows the schedule.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Admin batch creation uses registered plant plan without a variety duration',
      (tester) async {
    final client = MockClient((request) async => http.Response(
        jsonEncode({
          'users': request.url.path == '/plant_type'
              ? [
                  {
                    r'$id': 'p',
                    'name': 'Lettuce',
                    'production_plan': jsonEncode(plan)
                  }
                ]
              : []
        }),
        200));
    addTearDown(client.close);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () => showBatchCreationDialog(
                        context: context,
                        api: SuperAdminApiService(client: client),
                        farm: {
                          'id': 'farm',
                          'name': 'North',
                          'plantType': 'Lettuce',
                          'plantTypeId': 'p',
                          'plantVariety': 'Green',
                          'caretakerID': 'care',
                          'caretaker': 'Caretaker'
                        },
                        createdBy: 'Admin',
                        onCreated: () async {}),
                    child: const Text('Create batch'))))));
    await tester.tap(find.text('Create batch'));
    await tester.pumpAndSettle();
    expect(find.text('Planned growth schedule'), findsOneWidget);
    expect(find.textContaining('42 days of growth stages'), findsOneWidget);
    expect(find.textContaining('every 14 days'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
